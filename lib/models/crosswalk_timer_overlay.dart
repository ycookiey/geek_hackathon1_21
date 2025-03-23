import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CrosswalkTimerOverlay extends StatelessWidget {
  final LatLng position;
  final int remainingSeconds;
  final bool isNextGreen;

  const CrosswalkTimerOverlay({
    Key? key,
    required this.position,
    required this.remainingSeconds,
    this.isNextGreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color timerColor;
    Color borderColor;
    Color textColor;

    if (isNextGreen) {
      timerColor = Colors.white.withOpacity(0.8);
      borderColor = Colors.red;
      textColor = Colors.red;
    } else {
      timerColor = Colors.white.withOpacity(0.8);
      borderColor = remainingSeconds < 5 ? Colors.amber : Colors.green;
      textColor = remainingSeconds < 5 ? Colors.amber : Colors.green;
    }

    return MarkerLayer(
      markers: [
        Marker(
          width: 40.0,
          height: 40.0,
          point: position,
          child: Container(
            decoration: BoxDecoration(
              color: timerColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 3.0),
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
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
