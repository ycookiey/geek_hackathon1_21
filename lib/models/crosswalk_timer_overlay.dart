import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CrosswalkTimerOverlay extends StatelessWidget {
  final LatLng position;
  final int remainingSeconds;

  const CrosswalkTimerOverlay({
    Key? key,
    required this.position,
    required this.remainingSeconds,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 残り時間に基づいて色を決定 (赤は使わない)
    Color timerColor = remainingSeconds < 5 ? Colors.amber : Colors.green;

    return MarkerLayer(
      markers: [
        Marker(
          width: 40.0,
          height: 40.0,
          point: position,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
              border: Border.all(color: timerColor, width: 3.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                remainingSeconds.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: timerColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
