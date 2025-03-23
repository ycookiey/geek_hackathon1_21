import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class Crosswalk {
  final String id;
  final List<LatLng> points;
  final int? intersectionId;
  final Color color;
  final double opacity;

  Crosswalk({
    required this.id,
    required this.points,
    this.intersectionId,
    this.color = Colors.green,
    this.opacity = 0.5,
  });

  // ポリゴンの中心点を計算
  LatLng get center {
    double lat = 0;
    double lng = 0;

    for (var point in points) {
      lat += point.latitude;
      lng += point.longitude;
    }

    return LatLng(lat / points.length, lng / points.length);
  }

  Crosswalk copyWith({Color? newColor}) {
    return Crosswalk(
      id: id,
      points: points,
      intersectionId: intersectionId,
      color: newColor ?? color,
      opacity: opacity,
    );
  }
}
