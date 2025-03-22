import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:geek_hackathon1_21/models/crosswalk.dart';

class OSMOverpassService {
  static const String _overpassApi = 'https://overpass-api.de/api/interpreter';

  static Future<List<Crosswalk>> getCrosswalksNearby(
    LatLng position,
    double radius,
  ) async {
    // 半径はメートル単位
    double radiusInDegrees = radius / 111000; // おおよその度数換算（1度≒111km）

    final query = '''
      [out:json];
      (
        way["highway"="footway"]["footway"="crossing"]
          (${position.latitude - radiusInDegrees},${position.longitude - radiusInDegrees},
           ${position.latitude + radiusInDegrees},${position.longitude + radiusInDegrees});
        way["highway"="crossing"]
          (${position.latitude - radiusInDegrees},${position.longitude - radiusInDegrees},
           ${position.latitude + radiusInDegrees},${position.longitude + radiusInDegrees});
      );
      out body;
      >;
      out skel qt;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_overpassApi),
        body: {'data': query},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseCrosswalks(data);
      } else {
        print('Overpass APIエラー: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('横断歩道データ取得エラー: $e');
      return [];
    }
  }

  static Future<List<Crosswalk>> getCrosswalksNearIntersection(
    int intersectionId,
    LatLng intersectionPosition,
  ) async {
    // 周囲20メートル以内の横断歩道を検索
    return await getCrosswalksNearby(intersectionPosition, 20);
  }

  static List<Crosswalk> _parseCrosswalks(Map<String, dynamic> data) {
    final List<Crosswalk> crosswalks = [];
    final Map<int, LatLng> nodes = {};

    // ノードの座標を抽出
    for (var element in data['elements']) {
      if (element['type'] == 'node') {
        nodes[element['id']] = LatLng(element['lat'], element['lon']);
      }
    }

    // 横断歩道を処理
    for (var element in data['elements']) {
      if (element['type'] == 'way' &&
          (element['tags']?['highway'] == 'footway' &&
                  element['tags']?['footway'] == 'crossing' ||
              element['tags']?['highway'] == 'crossing')) {
        final List<LatLng> wayPoints = [];

        // wayを構成するノードの座標を取得
        for (var nodeId in element['nodes']) {
          if (nodes.containsKey(nodeId)) {
            wayPoints.add(nodes[nodeId]!);
          }
        }

        if (wayPoints.length >= 2) {
          final color =
              crosswalks.length % 2 == 0
                  ? Colors.green.withAlpha(200)
                  : Colors.red.withAlpha(200);

          crosswalks.add(
            Crosswalk(
              id: element['id'].toString(),
              points: wayPoints,
              color: color,
              opacity: 0.7,
            ),
          );
        }
      }
    }

    return crosswalks;
  }
}
