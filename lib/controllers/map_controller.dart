import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:geek_hackathon1_21/providers/map_providers.dart';
import 'package:geek_hackathon1_21/repositories/intersection_repository.dart';

class MapControllerHelper {
  final MapController mapController;
  final WidgetRef ref;

  MapControllerHelper(this.mapController, this.ref);

  void moveCamera(LatLng position, double zoom) {
    mapController.move(position, zoom);
  }

  Future<void> getMarkersInView(IntersectionRepository repository) async {
    final bounds = mapController.camera.visibleBounds;
    final minLat = bounds.southWest.latitude;
    final maxLat = bounds.northEast.latitude;
    final minLng = bounds.southWest.longitude;
    final maxLng = bounds.northEast.longitude;

    final intersectionMarkers = await repository.getIntersectionsInBounds(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    );

    ref.read(markersProvider.notifier).state = intersectionMarkers;
  }
}
