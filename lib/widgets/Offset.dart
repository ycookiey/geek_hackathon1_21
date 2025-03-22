import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geek_hackathon1_21/constants.dart';

Future offset(String markerId) async {
  DateTime now = DateTime.now();
  String time =
      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";

  try {
    final OffsetTime = await supabase
        .from('intersection_regular_time_data')
        //.update({'offset': time})
        .select()
        .eq('intersection_id', markerId)
        .lte('time', time)
        .order('time', ascending: false)
        .limit(1);

    if (OffsetTime.isNotEmpty) {}

    return null;
  } catch (e) {
    print("エラー!! $markerId: $e");
    return null;
  }
}
