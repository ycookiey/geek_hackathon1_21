import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

// 現在位置のプロバイダー
final currentPositionProvider = StateProvider<Position?>((ref) => null);

// 追従モードのプロバイダー
final isFollowingProvider = StateProvider<bool>((ref) => true);

// マーカーのプロバイダー
final markersProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);
