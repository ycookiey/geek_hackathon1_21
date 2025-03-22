import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geek_hackathon1_21/constants.dart';
import 'package:geek_hackathon1_21/env.dart';
import 'package:geek_hackathon1_21/services/location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocationService.requestPermission(); // LocationServiceのメソッドを使用
  await Supabase.initialize(
    // TODO: ここにSupabaseのURLとAnon Keyを入力
    url: 'https://ifuswhoatzauxusfgtyo.supabase.co',
    anonKey: Env.supabaseAnonKey,
  );

  runApp(MyApp());
}

//位置情報が許可されていない時に許可をリクエストする関数はlocation_service.dartに移動しました

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Maps',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MapView(),
    );
  }
}

class MapView extends StatefulWidget {
  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  //現在地を示すCircle
  Set<Circle> _circles = Set();
  Set<Marker> _markers = Set(); // マーカーを管理するセット

  Position? currentPosition;
  late GoogleMapController mapController;
  late StreamSubscription<Position> positionStream;
  late Timer _timer; // 定期実行用のタイマー
  bool isFollowing = true; // 追従モードの状態（デフォルトON）
  bool isUserInteracting = false; // ユーザーが手動で操作中かどうかを判定

  String? selectedMarkerId; // 選択されたマーカーのID
  bool isSidebarVisible = false; // サイドバーの表示状態

  int IntersectionId = 0;
  int Cycle = 0;

  //初期位置
  final CameraPosition _initialLocation = const CameraPosition(
    target: LatLng(35.161940, 136.906947),
    zoom: 16,
  );

  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high, //正確性:highはAndroid(0-100m),iOS(10m)
    distanceFilter: 0,
  );

  @override
  void initState() {
    super.initState();

    // **1秒ごとに現在時刻を取得 & 出力**
    _timer = Timer.periodic(Duration(seconds: 6), (timer) {
      _printCurrentTime();
    });

    //現在位置を更新し続ける
    positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position? position) {
      if (position != null) {
        setState(() {
          currentPosition = position;
        });
        if (isFollowing) {
          moveCameraToCurrentPosition(); // 追従モードならカメラを移動
        }
        //_getVisibleRegion(); // 位置更新時に四隅の座標取得
      }
    });
  }

  Future<void> getMarkersFromSupabase() async {
    LatLngBounds bounds = await mapController.getVisibleRegion();
    //double minLat = bounds.southwest.latitude;
    double maxLat = bounds.northeast.latitude;
    double minLng = bounds.southwest.longitude;
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

    setState(() {
      _markers.clear();
      for (var item in maker_map) {
        IntersectionId = item['intersection_id'];

        getDataByTimeRange();

        _markers.add(
          Marker(
            //markerId: MarkerId('${item['lat']},${item['lon']}'),
            markerId: MarkerId('${item['intersection_id']}'),
            position: LatLng(item['lat'], item['lon']),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),

            onTap: () {
              setState(() {
                selectedMarkerId = '${item['intersection_id']}';
                isSidebarVisible = true;
              });
            },
          ),
        );
      }
    });
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
      getDataByTimeRange();
    }

    print(response);
    print("だよーん");
  }

  // カメラを現在地に移動
  void moveCameraToCurrentPosition() {
    if (currentPosition != null && mapController != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(currentPosition!.latitude, currentPosition!.longitude),
        ),
      );
    }
  }

  /// **現在時刻を取得してデバッグ出力**
  void _printCurrentTime() {
    //String formattedTime = DateTime.now().toLocal().toString();
    String formattedTime = TimeOfDay.now().toString();

    //print("現在時刻: $formattedTime");
  }

  /// Googleマップの表示範囲の四隅の座標を取得（カメラ移動後・ズーム変更後）
  Future<void> _getVisibleRegion() async {
    if (mapController == null) return;

    LatLngBounds visibleRegion = await mapController.getVisibleRegion();

    LatLng northeast = visibleRegion.northeast; // 右上
    LatLng southwest = visibleRegion.southwest; // 左下
    LatLng northwest = LatLng(northeast.latitude, southwest.longitude); // 左上
    LatLng southeast = LatLng(southwest.latitude, northeast.longitude); // 右下

    print("四隅の座標:");
    print("左上: ${northwest.latitude}, ${northwest.longitude}");
    print("右上: ${northeast.latitude}, ${northeast.longitude}");
    print("左下: ${southwest.latitude}, ${southwest.longitude}");
    print("右下: ${southeast.latitude}, ${southeast.longitude}");
  }

  // 追従モードの切り替え
  void toggleFollowMode() {
    moveCameraToCurrentPosition;
    setState(() {
      isFollowing = !isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Container(
      height: height,
      width: width,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            GoogleMap(
              onTap: (LatLng position) {
                // ← 追加！
                setState(() {
                  isFollowing = false; // Google Map をタップしたら追尾モードを解除
                  isSidebarVisible = false; // どこかをタップしたら閉じる
                });
                print("Google Map がタップされました！追尾モードOFF");
              },

              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              circles: _circles, // 現在位置の円を地図に表示
              markers: _markers, // 追加したマーカーを表示
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                getMarkersFromSupabase();
                moveCameraToCurrentPosition(); // 初期ロード時に現在地へ移動
              },
              onCameraIdle: () {
                //_getVisibleRegion(); // カメラが停止したら四隅の座標を取得
                getMarkersFromSupabase();
                // カメラが手動操作されたら追従をOFFにする
                if (isUserInteracting) {
                  setState(() {
                    isFollowing = false;
                  });
                }
                isUserInteracting = false;
              },
            ),

            AnimatedPositioned(
              duration: Duration(milliseconds: 200),
              right: isSidebarVisible ? 0 : -200, // 非表示時は画面外へ
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
                      selectedMarkerId ?? "選択なし",
                      style: TextStyle(fontSize: 16),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isSidebarVisible = false;
                        });
                      },
                      child: Text("閉じる"),
                    ),
                  ],
                ),
              ),
            ),

            // 左下に「現在地」ボタンを配置
            //Positioned(
            //  bottom: 20,
            //  left: 20,
            //  child: FloatingActionButton(
            //    backgroundColor: Colors.white,
            //    onPressed: moveCameraToCurrentPosition,
            //    child: const Icon(Icons.my_location, color: Colors.blue),
            //  ),
            //),
            //右下に「追従モード切替ボタン」を配置
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
    super.dispose();
  }
}
