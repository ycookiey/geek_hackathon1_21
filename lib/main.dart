
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();  
  await dotenv.load();
  await requestPermission(); // ← ここで実行    
  runApp(MyApp());
}

    //位置情報が許可されていない時に許可をリクエストする
    //    Future(() async {

    Future<void> requestPermission() async {
      LocationPermission permission = await Geolocator.checkPermission();
      if(permission == LocationPermission.denied){
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
  
  
  // **マーカーの表示状態を更新**
  void _updateMarkerVisibility() {
    if (currentPosition == null) return;

    double distance = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      _markerPosition.latitude,
      _markerPosition.longitude,
    );

    bool shouldShowMarker = distance <= 100.0; // 100m以内なら表示

    if (shouldShowMarker != _isMarkerVisible) {
      setState(() {
        _isMarkerVisible = shouldShowMarker;
        _updateMarkers();
      });
    }
  }


    //現在位置を更新し続ける
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      if (position != null) {
        setState(() {              
        currentPosition = position;
        _updateCircle(); //現在位置が更新されたら円も更新
        _updateMarkerVisibility(); // マーカーの表示状態を更新
      });
      if (isFollowing){
        moveCameraToCurrentPosition();// 追従モードならカメラを移動
      }
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
              circles: _circles,// 現在位置の円を地図に表示
              markers: _markers, // 追加したマーカーを表示 
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                moveCameraToCurrentPosition(); // 初期ロード時に現在地へ移動
              },
              onCameraIdle: (){
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
                child: const Icon(Icons.my_location, color: Colors.blue,),
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
              )
            )
          )
          ],
        ),
      ),
    );
  }
    @override
  void dispose() {
    positionStream.cancel(); // ストリームを停止
    super.dispose();
  }
}
