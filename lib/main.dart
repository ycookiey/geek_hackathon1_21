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
  final MapController mapController = MapController();
  late StreamSubscription<Position> positionStream;
  late Timer _timer; // 定期実行用のタイマー
  int IntersectionId = 0;
  int Cycle = 0;

  final LatLng _initialLocation = const LatLng(35.161940, 136.906947);

  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high, //正確性:highはAndroid(0-100m),iOS(10m)
    distanceFilter: 0,
  );

  @override
  void initState() {
    super.initState();

    // **1秒ごとに現在時刻を取得 & 出力**
    _setupPositionStream();

    // 時間チェック用タイマー
    _timer = Timer.periodic(Duration(seconds: 6), (timer) {
      _printCurrentTime();
    });
  }

  void _setupPositionStream() {
    positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position? position) {
      if (position != null) {
        ref.read(currentPositionProvider.notifier).state = position;

        if (ref.read(isFollowingProvider)) {
          moveCameraToCurrentPosition(); // 追従モードならカメラを移動
        }
        //_getVisibleRegion(); // 位置更新時に四隅の座標取得
      }
    });
  }

  Future<void> getMarkersFromSupabase() async {
    final bounds = mapController.camera.visibleBounds;
    //double minLat = bounds.southwest.latitude;
    final maxLat = bounds.northEast.latitude;
    final minLng = bounds.southWest.longitude;
    //double maxLng = bounds.northeast.longitude;
    DateTime now = DateTime.now();
    int weekdayNumber = now.weekday; // 1:月, 2:火, ..., 7:日

    if (weekdayNumber == 6 || weekdayNumber == 7) {
      int weekType = 1;
    } else {
      int weekType = 2;
    }

    List<String> weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final maker_map = await Supabase.instance.client
        .from('intersection_location')
        .select('lat, lon, intersection_id')
        //.gte('lat', minLat)
        .lte('lat', maxLat)
        .gte('lon', minLng);
    //.lte('lon', maxLng);

    final _markers = <Map<String, dynamic>>[];

    for (var item in maker_map) {
      IntersectionId = item['intersection_id'];
      await getDataByTimeRange();

      _markers.add(item);
    }

    ref.read(markersProvider.notifier).state = _markers;
  }

  Future<void> getDataByTimeRange() async {
    DateTime now = DateTime.now();
    String today = "${now.year}/${now.month}/${now.day}";
    String time =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";

    DateTime minTime = now.subtract(Duration(hours: 1));
    DateTime maxTime = now.add(Duration(hours: 1));

    String minTimeStr =
        "${minTime.hour.toString().padLeft(2, '0')}:${minTime.minute.toString().padLeft(2, '0')}:00";
    String maxTimeStr =
        "${maxTime.hour.toString().padLeft(2, '0')}:${maxTime.minute.toString().padLeft(2, '0')}:00";

    final response = await Supabase.instance.client
        .from('intersection_time_data')
        .select()
        .eq('intersection_id', IntersectionId)
        .gte('time', minTimeStr) // 時刻が minTime 以上
        .lte('time', maxTimeStr); // 時刻が maxTime 以下

    if (response.isEmpty && Cycle < 24) {
      Cycle += 1;
      await getDataByTimeRange();
    }

    print(response);
    print("だよーん");
  }

  // カメラを現在地に移動
  void moveCameraToCurrentPosition() {
    final position = ref.read(currentPositionProvider);
    if (position != null) {
      mapController.move(
        LatLng(position.latitude, position.longitude),
        mapController.camera.zoom,
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
  void toggleFollowMode() {
    final isFollowing = ref.read(isFollowingProvider);
    ref.read(isFollowingProvider.notifier).state = !isFollowing;

    if (!isFollowing) {
      moveCameraToCurrentPosition();
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
          onTap: (id) {},
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
              mapController: mapController,
              options: OSMService.getDefaultMapOptions(
                initialCenter: _initialLocation,
                initialZoom: 16.0,
                onMapTap: () {
                  ref.read(isFollowingProvider.notifier).state = false;
                },
                onCameraIdle: () {
                  getMarkersFromSupabase();
                },
              ),
              children: [
                OSMService.getDefaultTileLayer(),
                MarkerLayer(markers: mapMarkers),
              ],
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: isFollowing ? Colors.blue : Colors.white,
                onPressed: toggleFollowMode,
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
    positionStream.cancel(); // ストリームを停止
    _timer.cancel(); // **タイマーを停止**
    mapController.dispose();
    super.dispose();
  }
}
