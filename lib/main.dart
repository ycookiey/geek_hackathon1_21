import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geek_hackathon1_21/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestPermission(); // ← ここで実行
  await Supabase.initialize(
    // TODO: ここにSupabaseのURLとAnon Keyを入力
    url: 'https://ifuswhoatzauxusfgtyo.supabase.co',
    anonKey: 'SUPABASE_ANON_KEY',
  );

  runApp(MyApp());
}

//位置情報が許可されていない時に許可をリクエストする
//    Future(() async {

Future<void> requestPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      print("位置情報の権限が拒否されました");
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      print("位置情報の権限が永久に拒否されています。設定から変更してください。");
      return;
    }

    print("位置情報の権限が許可されました");
  }
}

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
  bool _isMarkerVisible = false; // マーカーの表示状態を管理

  final LatLng _markerPosition = LatLng(35.14006731, 136.90313371); // ピンの座標

  Position? currentPosition;
  late GoogleMapController mapController;
  late StreamSubscription<Position> positionStream;
  late Timer _timer; // 定期実行用のタイマー
  bool isFollowing = true; // 追従モードの状態（デフォルトON）
  bool isUserInteracting = false; // ユーザーが手動で操作中かどうかを判定

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
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _printCurrentTime();
    });

    //現在位置を更新し続ける
    positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position? position) {
      if (position != null) {
        setState(() {
          currentPosition = position;
          _updateCircle(); //現在位置が更新されたら円も更新
        });
        if (isFollowing) {
          moveCameraToCurrentPosition(); // 追従モードならカメラを移動
        }
        _getVisibleRegion(); // 位置更新時に四隅の座標取得
        _updateMarkerVisibility(); //位置情報の更新時にマーカーの表示を判定
      }
    });
  }

  Future<void> getMarkersFromSupabase() async {
    LatLngBounds bounds = await mapController.getVisibleRegion();
    //double minLat = bounds.southwest.latitude;
    double maxLat = bounds.northeast.latitude;
    double minLng = bounds.southwest.longitude;
    //double maxLng = bounds.northeast.longitude;

    final response = await Supabase.instance.client
        .from('intersection_location')
        .select('lat, lon')
        //.gte('lat', minLat)
        .lte('lat', maxLat)
        .gte('lon', minLng);
    //.lte('lon', maxLng);

    setState(() {
      _markers.clear();
      for (var item in response) {
        _markers.add(
          Marker(
            markerId: MarkerId('${item['lat']},${item['lon']}'),
            position: LatLng(item['lat'], item['lon']),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          ),
        );
      }
    });
  }

  // 現在位置を中心に半径100メートルの円を作成
  void _updateCircle() {
    if (currentPosition != null) {
      final circle = Circle(
        circleId: CircleId("current_location_circle"),
        center: LatLng(currentPosition!.latitude, currentPosition!.longitude),
        radius: 100, // 半径100メートル
        //fillColor: Colors.blue.withOpacity(0.2), // 薄い青色
        strokeColor: Colors.blue, // 青い円の縁
        strokeWidth: 2,
      );
      setState(() {
        _circles = {circle}; // 現在地の円を更新
      });
    }
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
    String formattedTime = DateTime.now().toLocal().toString();
    print("現在時刻: $formattedTime");
  }

  // **マーカーの表示状態を更新**
  Future<void> _updateMarkerVisibility() async {
    if (currentPosition == null) return;

    LatLngBounds visibleRegion = await mapController.getVisibleRegion();
    bool shouldShowMarker = visibleRegion.contains(_markerPosition);

    if (shouldShowMarker != _isMarkerVisible) {
      setState(() {
        _isMarkerVisible = shouldShowMarker;
        _updateMarkers();
      });
    }
  }

  // **マーカーのセットを更新**
  void _updateMarkers() {
    _markers.clear(); // 一旦クリア
    if (_isMarkerVisible) {
      _markers.add(
        Marker(
          markerId: MarkerId("custom_marker"),
          position: _markerPosition,
          infoWindow: InfoWindow(title: "指定の地点"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
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
                _updateMarkerVisibility(); // 初回表示時にマーカーの判定
              },
              onCameraIdle: () {
                _getVisibleRegion(); // カメラが停止したら四隅の座標を取得
                getMarkersFromSupabase();
                _updateMarkerVisibility(); // カメラ移動後にマーカーの表示を更新
                // カメラが手動操作されたら追従をOFFにする
                if (isUserInteracting) {
                  setState(() {
                    isFollowing = false;
                  });
                }
                isUserInteracting = false;
              },
            ),
            // 左下に「現在地」ボタンを配置
            Positioned(
              bottom: 20,
              left: 20,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: moveCameraToCurrentPosition,
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
            ),
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
