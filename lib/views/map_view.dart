import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:geek_hackathon1_21/controllers/location_controller.dart';
import 'package:geek_hackathon1_21/controllers/map_controller.dart';
import 'package:geek_hackathon1_21/models/crosswalk.dart';
import 'package:geek_hackathon1_21/providers/map_providers.dart';
import 'package:geek_hackathon1_21/repositories/intersection_repository.dart';
import 'package:geek_hackathon1_21/services/osm_service.dart';
import 'package:geek_hackathon1_21/widgets/crosswalk_layer_widget.dart';
import 'package:geek_hackathon1_21/widgets/sidebar_widget.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  final MapController _mapController = MapController();
  late Timer _timer; // 定期実行用のタイマー
  final LatLng _initialLocation = const LatLng(35.161940, 136.906947);
  late final MapControllerHelper _mapControllerHelper;
  late final LocationControllerHelper _locationController;
  late final IntersectionRepository _intersectionRepository;

  bool _isSidebarVisible = false;
  String? _selectedMarkerId;

  @override
  void initState() {
    super.initState();

    _locationController = LocationControllerHelper(ref, _mapController);
    _mapControllerHelper = MapControllerHelper(_mapController, ref);
    _intersectionRepository = IntersectionRepository();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationController.setupPositionStream();
      _mapControllerHelper.getMarkersInView(_intersectionRepository);
    });

    // 時間チェック用タイマー
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      _printCurrentTime();
    });
  }

  /// **現在時刻を取得してデバッグ出力**
  void _printCurrentTime() {
    //String formattedTime = DateTime.now().toLocal().toString();
    String formattedTime = TimeOfDay.now().toString();

    //print("現在時刻: $formattedTime");
  }

  @override
  Widget build(BuildContext context) {
    final currentPosition = ref.watch(currentPositionProvider);
    final isFollowing = ref.watch(isFollowingProvider);
    final markers = ref.watch(markersProvider);
    final crosswalks = ref.watch(crosswalksProvider);

    final mapMarkers = <Marker>[];

    if (currentPosition != null) {
      mapMarkers.add(
        OSMService.getCurrentLocationMarker(
          LatLng(currentPosition.latitude, currentPosition.longitude),
        ),
      );
    }

    for (final marker in markers) {
      mapMarkers.add(
        OSMService.createCustomMarker(
          point: LatLng(marker['lat'], marker['lon']),
          id: '${marker['intersection_id']}',
          onTap: (id) {
            setState(() {
              _selectedMarkerId = id;
              _isSidebarVisible = true;
            });
          },
        ),
      );
    }

    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Container(
      height: height,
      width: width,
      child: Scaffold(
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: OSMService.getDefaultMapOptions(
                initialCenter: _initialLocation,
                initialZoom: 16.0,
                onMapTap: () {
                  ref.read(isFollowingProvider.notifier).state = false;
                  setState(() {
                    _isSidebarVisible = false; // どこかをタップしたら閉じる
                  });
                },
                onCameraIdle: () {
                  _mapControllerHelper.getMarkersInView(
                    _intersectionRepository,
                  );
                },
              ),
              children: [
                OSMService.getDefaultTileLayer(),
                CrosswalkLayerWidget(crosswalks: crosswalks),
                MarkerLayer(markers: mapMarkers),
              ],
            ),

            SidebarWidget(
              isVisible: _isSidebarVisible,
              selectedMarkerId: _selectedMarkerId,
              onClose: () => setState(() => _isSidebarVisible = false),
            ),

            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: isFollowing ? Colors.blue : Colors.white,
                onPressed: _locationController.toggleFollowMode,
                child: Icon(
                  isFollowing ? Icons.lock : Icons.lock_open,
                  color: isFollowing ? Colors.white : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _timer.cancel(); // **タイマーを停止**
    _mapController.dispose();
    super.dispose();
  }
}
