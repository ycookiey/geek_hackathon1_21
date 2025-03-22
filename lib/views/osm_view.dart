import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/osm_service.dart';

class OSMView extends StatefulWidget {
  @override
  State<OSMView> createState() => _OSMViewState();
}

class _OSMViewState extends State<OSMView> {
  final MapController _mapController = MapController();

  Position? currentPosition;

  List<Marker> _markers = [];

  bool isFollowing = true;

  bool isSidebarVisible = false;
  String? selectedMarkerId;

  final LatLng _initialLocation = LatLng(35.161940, 136.906947);

  @override
  void initState() {
    super.initState();
    // TODO: 現在位置の取得と更新の実装
  }

  void toggleFollowMode() {
    setState(() {
      isFollowing = !isFollowing;
      if (isFollowing && currentPosition != null) {
        _mapController.move(
          LatLng(currentPosition!.latitude, currentPosition!.longitude),
          _mapController.camera.zoom,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          FlutterMap(
            mapController: _mapController,
            options: OSMService.getDefaultMapOptions(
              initialCenter: _initialLocation,
              initialZoom: 16.0,
              onMapTap: () {
                setState(() {
                  isFollowing = false;
                  isSidebarVisible = false;
                });
              },
              onCameraIdle: () {
                // TODO: 表示範囲内のマーカーを取得
              },
            ),
            children: [
              OSMService.getDefaultTileLayer(),
              MarkerLayer(markers: _markers),
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
    );
  }
}
