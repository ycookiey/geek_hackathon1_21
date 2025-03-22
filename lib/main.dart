import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:geek_hackathon1_21/constants.dart';
import 'package:geek_hackathon1_21/env.dart';
import 'package:geek_hackathon1_21/providers/map_providers.dart';
import 'package:geek_hackathon1_21/services/location_service.dart';
import 'package:geek_hackathon1_21/services/osm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocationService.requestPermission();
  await Supabase.initialize(
    url: 'https://ifuswhoatzauxusfgtyo.supabase.co',
    anonKey: Env.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Maps',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MapView(),
    );
  }
}

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  final MapController _mapController = MapController();
  late StreamSubscription<Position> _positionStream;
  late Timer _timer; // 定期実行用のタイマー
  int _intersectionId = 0;
  bool _isSidebarVisible = false;
  String? _selectedMarkerId; // 選択されたマーカーのID

  final LatLng _initialLocation = const LatLng(35.161940, 136.906947);

  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high, //正確性:highはAndroid(0-100m),iOS(10m)
    distanceFilter: 0,
  );

  @override
  void initState() {
    super.initState();

    // **1秒ごとに現在時刻を取得 & 出力**
    _setupPositionStream();

    // 時間チェック用タイマー
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      _printCurrentTime();
    });
  }

  void _setupPositionStream() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen((Position? position) {
      if (position != null) {
        ref.read(currentPositionProvider.notifier).state = position;

        if (ref.read(isFollowingProvider)) {
          _moveCameraToCurrentPosition(); // 追従モードならカメラを移動
        }
      }
    });
  }

  Future<void> _getMarkersFromSupabase() async {
    final bounds = _mapController.camera.visibleBounds;
    final minLat = bounds.southWest.latitude;
    final maxLat = bounds.northEast.latitude;
    final minLng = bounds.southWest.longitude;
    final maxLng = bounds.northEast.longitude;

    final maker_map = await supabase
        .from('intersection_location')
        .select('lat, lon, intersection_id')
        .gte('lat', minLat)
        .lte('lat', maxLat)
        .gte('lon', minLng)
        .lte('lon', maxLng);

    final markers = <Map<String, dynamic>>[];

    for (final item in maker_map) {
      _intersectionId = item['intersection_id'];
      await _getDataByTimeRange();

      markers.add(item);
    }

    ref.read(markersProvider.notifier).state = markers;
  }

  Future<void> _getDataByTimeRange() async {
    DateTime now = DateTime.now();
    String weekType = "";
    String weekdays = "";
    int weekdayNumber = now.weekday; // 1:月, 2:火, ..., 7:日
    String today = "${now.year}/${now.month}/${now.day}";
    String time =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";

    if (weekdayNumber == 6 || weekdayNumber == 7) {
      weekType = "holiday";
    } else {
      weekType = "weekday";
    }
    if (weekdayNumber == 1) {
      weekdays = "monday";
    } else if (weekdayNumber == 2) {
      weekdays = "tuesday";
    } else if (weekdayNumber == 3) {
      weekdays = "wednesday";
    } else if (weekdayNumber == 4) {
      weekdays = "thursday";
    } else if (weekdayNumber == 5) {
      weekdays = "friday";
    } else if (weekdayNumber == 6) {
      weekdays = "saturday";
    } else if (weekdayNumber == 7) {
      weekdays = "sunday";
    }

    for (int Cycle = 0; Cycle < 24; Cycle++) {
      //List<String> weekdays = [
      //  'monday',
      //  'tuesday',
      //  'wednesday',
      //  'thursday',
      //  'friday',
      //  'saturday',
      //  'sunday',
      //];
      //print("現在のサイクル数");
      //print(Cycle);
      DateTime minTime = now.subtract(Duration(hours: (Cycle)));
      DateTime maxTime = now.add(Duration(hours: (Cycle)));

      String minTimeStr =
          "${minTime.hour.toString().padLeft(2, '0')}:${minTime.minute.toString().padLeft(2, '0')}:00";
      String maxTimeStr =
          "${maxTime.hour.toString().padLeft(2, '0')}:${maxTime.minute.toString().padLeft(2, '0')}:00";

      final response = await Supabase.instance.client
          .from('intersection_regular_time_data')
          .select()
          .eq('intersection_id', _intersectionId)
          .eq('day_type', weekdays)
          .gte('time', minTimeStr) // 時刻が minTime 以上
          .lte('time', maxTimeStr); // 時刻が maxTime 以下

      if (response.isNotEmpty) {
        print(response);
        print("だよーん");

        break;
      } else {
        final response2 = await Supabase.instance.client
            .from('intersection_regular_time_data')
            .select()
            .eq('intersection_id', _intersectionId)
            .eq('day_type', weekType)
            .gte('time', minTimeStr) // 時刻が minTime 以上
            .lte('time', maxTimeStr); // 時刻が maxTime 以下

        if (response2.isNotEmpty) {
          print(response);
          print("だよーん");

          break;
        }
      }
    }
  }

  // カメラを現在地に移動
  void _moveCameraToCurrentPosition() {
    final position = ref.read(currentPositionProvider);
    if (position != null) {
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _mapController.camera.zoom,
      );
    }
  }

  /// **現在時刻を取得してデバッグ出力**
  void _printCurrentTime() {
    //String formattedTime = DateTime.now().toLocal().toString();
    String formattedTime = TimeOfDay.now().toString();

    //print("現在時刻: $formattedTime");
  }

  // 追従モードの切り替え
  void _toggleFollowMode() {
    final isFollowing = ref.read(isFollowingProvider);
    ref.read(isFollowingProvider.notifier).state = !isFollowing;

    if (!isFollowing) {
      _moveCameraToCurrentPosition();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPosition = ref.watch(currentPositionProvider);
    final isFollowing = ref.watch(isFollowingProvider);
    final markers = ref.watch(markersProvider);

    final mapMarkers = <Marker>[];

    if (currentPosition != null) {
      mapMarkers.add(
        OSMService.getCurrentLocationMarker(
          LatLng(currentPosition.latitude, currentPosition.longitude),
        ),
      );
    }

    for (final marker in markers) {
      mapMarkers.add(
        OSMService.createCustomMarker(
          point: LatLng(marker['lat'], marker['lon']),
          id: '${marker['intersection_id']}',
          onTap: (id) {
            setState(() {
              _selectedMarkerId = '${marker['intersection_id']}';
              _isSidebarVisible = true;
            });
          },
        ),
      );
    }
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Container(
      height: height,
      width: width,
      child: Scaffold(
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: OSMService.getDefaultMapOptions(
                initialCenter: _initialLocation,
                initialZoom: 16.0,
                onMapTap: () {
                  ref.read(isFollowingProvider.notifier).state = false;
                  _isSidebarVisible = false; // どこかをタップしたら閉じる
                },
                onCameraIdle: () {
                  _getMarkersFromSupabase();
                },
              ),
              children: [
                OSMService.getDefaultTileLayer(),
                MarkerLayer(markers: mapMarkers),
              ],
            ),
            AnimatedPositioned(
              duration: Duration(milliseconds: 200),
              right: _isSidebarVisible ? 0 : -200, // 非表示時は画面外へ
              top: 0,
              bottom: 0,
              width: 200,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "マーカーID:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _selectedMarkerId ?? "選択なし",
                      style: TextStyle(fontSize: 16),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isSidebarVisible = false;
                        });
                      },
                      child: Text("閉じる"),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: isFollowing ? Colors.blue : Colors.white,
                onPressed: _toggleFollowMode,
                child: Icon(
                  isFollowing ? Icons.lock : Icons.lock_open,
                  color: isFollowing ? Colors.white : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionStream.cancel(); // ストリームを停止
    _timer.cancel(); // **タイマーを停止**
    _mapController.dispose();
    super.dispose();
  }
}
