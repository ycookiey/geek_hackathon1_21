import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:geek_hackathon1_21/providers/map_providers.dart';

class LocationControllerHelper {
  final WidgetRef ref;
  final MapController mapController;
  StreamSubscription<Position>? _positionStream;

  LocationControllerHelper(this.ref, this.mapController);

  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high, //正確性:highはAndroid(0-100m),iOS(10m)
    distanceFilter: 0,
  );

  void setupPositionStream() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen((Position? position) {
      if (position != null) {
        ref.read(currentPositionProvider.notifier).state = position;

        if (ref.read(isFollowingProvider)) {
          _moveCameraToCurrentPosition(); // 追従モードならカメラを移動
        }
      }
    });
  }

  // カメラを現在地に移動
  void _moveCameraToCurrentPosition() {
    final position = ref.read(currentPositionProvider);
    if (position != null) {
      final currentZoom = mapController.camera.zoom;

      // 現在地にカメラを移動
      mapController.move(
        LatLng(position.latitude, position.longitude),
        currentZoom,
      );
    }
  }

  // 追従モードの切り替え
  void toggleFollowMode() {
    final isFollowing = ref.read(isFollowingProvider);
    ref.read(isFollowingProvider.notifier).state = !isFollowing;

    if (!isFollowing) {
      _moveCameraToCurrentPosition();
    }
  }

  void dispose() {
    _positionStream?.cancel(); // ストリームを停止
  }
}
