import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OSMService {
  static MapOptions getDefaultMapOptions({
    required LatLng initialCenter,
    required double initialZoom,
    Function()? onMapTap,
    Function()? onCameraIdle,
  }) {
    return MapOptions(
      initialCenter: initialCenter,
      initialZoom: initialZoom,
      onTap: onMapTap != null ? (_, __) => onMapTap() : null,
      onMapEvent: (event) {
        if (event is MapEventMoveEnd && onCameraIdle != null) {
          onCameraIdle();
        }
      },
    );
  }

  static TileLayer getDefaultTileLayer() {
    return TileLayer(
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager_nolabels/{z}/{x}/{y}{r}.png',
      userAgentPackageName: 'com.example.geek_hackathon1_21',
      subdomains: ['a', 'b', 'c', 'd'],
      retinaMode: true,
    );
  }

  static Marker getCurrentLocationMarker(LatLng position) {
    return Marker(
      width: 20.0,
      height: 20.0,
      point: position,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  static Marker createCustomMarker({
    required LatLng point,
    required String id,
    required Function(String) onTap,
  }) {
    return Marker(
      width: 40.0,
      height: 40.0,
      point: point,
      child: GestureDetector(
        onTap: () => onTap(id),
        child: Icon(Icons.location_on, color: Colors.blue, size: 40),
      ),
    );
  }
}
