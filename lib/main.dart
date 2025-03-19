
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load();
  await requestPermission(); // ← ここで実行    
  WidgetsFlutterBinding.ensureInitialized();
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


  Position? currentPosition;
  late GoogleMapController mapController;
  late StreamSubscription<Position> positionStream; 

  //初期位置
  final CameraPosition _initialLocation = const CameraPosition(
    target: LatLng(35.161940, 136.906947),
    zoom: 15,
    );

  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high, //正確性:highはAndroid(0-100m),iOS(10m)
    distanceFilter: 100,
  );


  @override
  void initState() {
    super.initState();
    

  
    //現在位置を更新し続ける
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      currentPosition = position;
      print(position == null
          ? 'Unknown'
          : '${position.latitude.toString()}, ${position.longitude.toString()}');
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
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            ),
          ],
        ),
      ),
    );
  }
}
