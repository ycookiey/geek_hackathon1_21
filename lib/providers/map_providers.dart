import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geek_hackathon1_21/models/crosswalk.dart';

final currentPositionProvider = StateProvider<Position?>((ref) => null);

final isFollowingProvider = StateProvider<bool>((ref) => true);

final markersProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);

final mapControllerProvider = Provider<MapController>((ref) => MapController());

final selectedMarkerIdProvider = StateProvider<String?>((ref) => null);

final isSidebarVisibleProvider = StateProvider<bool>((ref) => false);

final crosswalksProvider = StateProvider<List<Crosswalk>>((ref) => []);
