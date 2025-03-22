import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geek_hackathon1_21/models/crosswalk.dart';

class CrosswalkLayerWidget extends StatelessWidget {
  final List<Crosswalk> crosswalks;

  const CrosswalkLayerWidget({Key? key, required this.crosswalks})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PolygonLayer(polygons: _buildPolygons());
  }

  List<Polygon> _buildPolygons() {
    return crosswalks.map((crosswalk) {
      final points = _createRectangleFromLine(crosswalk.points, 8.0);

      return Polygon(
        points: points,
        color: crosswalk.color,
        borderColor: crosswalk.color.withAlpha(205),
        borderStrokeWidth: 1.0,
        isFilled: true,
      );
    }).toList();
  }

  List<LatLng> _createRectangleFromLine(
    List<LatLng> linePoints,
    double widthInMeters,
  ) {
    if (linePoints.length < 2) return [];

    // 線の最初と最後の点
    final start = linePoints.first;
    final end = linePoints.last;

    // 線の方向ベクトル
    final dx = end.longitude - start.longitude;
    final dy = end.latitude - start.latitude;

    // 方向ベクトルを正規化
    final length = math.sqrt(dx * dx + dy * dy);
    final nx = dx / length;
    final ny = dy / length;

    // 垂直なベクトル（右手系）
    final perpX = -ny;
    final perpY = nx;

    // 緯度1度あたりの距離はおよそ111km
    // 経度1度あたりの距離は緯度によって変わる（緯度0度で約111km、90度で0km）
    final latFactor = 1.0 / 111000.0; // メートルあたりの緯度度
    final lngFactor =
        1.0 /
        (111000.0 * math.cos(start.latitude * math.pi / 180.0)); // メートルあたりの経度度

    final halfWidth = widthInMeters / 2.0;

    final p1 = LatLng(
      start.latitude + perpY * halfWidth * latFactor,
      start.longitude + perpX * halfWidth * lngFactor,
    );

    final p2 = LatLng(
      start.latitude - perpY * halfWidth * latFactor,
      start.longitude - perpX * halfWidth * lngFactor,
    );

    final p3 = LatLng(
      end.latitude - perpY * halfWidth * latFactor,
      end.longitude - perpX * halfWidth * lngFactor,
    );

    final p4 = LatLng(
      end.latitude + perpY * halfWidth * latFactor,
      end.longitude + perpX * halfWidth * lngFactor,
    );

    return [p1, p2, p3, p4];
  }
}
