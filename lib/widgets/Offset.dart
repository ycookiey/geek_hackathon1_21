import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:geek_hackathon1_21/constants.dart';

Future offset(String markerId) async {
  DateTime now = DateTime.now();
  int _Intersection_id = int.parse(markerId);

  int secondsSince0 = now.hour * 3600 + now.minute * 60 + now.second;

  try {
    await supabase
        .from('intersection_regular_time_data')
        .update({'offset': secondsSince0})
        .eq('intersection_id', _Intersection_id)
        .lte(
          'time',
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00",
        )
        .order('time', ascending: false);

    return null;
  } catch (e) {
    //print("エラー!! $markerId: $e");
    return null;
  }
}

Future<String?> PrintOffsetTime(String markerId) async {
  DateTime now = DateTime.now();
  int _Intersection_id = int.parse(markerId);
  String time =
      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

  try {
    final SetTime = await supabase
        .from('intersection_regular_time_data')
        .select('offset')
        .eq('intersection_id', _Intersection_id)
        .lte('time', time)
        .order('time', ascending: false)
        .limit(1);

    if (SetTime.isNotEmpty) {
      print(SetTime);
      print("セット情報");
      return SetTime.toString();
    }

    return null;
  } catch (e) {
    print("エラー!か？! $markerId: $e");
    return null;
  }
}
