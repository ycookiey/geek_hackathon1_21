import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:geek_hackathon1_21/constants.dart';

Future offset(String markerId) async {
  DateTime now = DateTime.now();
  int _Intersection_id = int.parse(markerId);
  String time =
      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

  try {
    final OffsetTime = await supabase
        .from('intersection_regular_time_data')
        .update({'offset': time})
        //.select()
        .eq('intersection_id', _Intersection_id)
        .lte('time', time)
        .order('time', ascending: false);
    //.limit(1);

    if (OffsetTime.isNotEmpty) {
      //print("エラー!!ですぜい");
    }

    return null;
  } catch (e) {
    //print("エラー!! $markerId: $e");
    return null;
  }
}
