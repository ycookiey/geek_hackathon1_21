import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geek_hackathon1_21/constants.dart';

class SignalState {
  final int intersectionId;
  final int cycle;
  final List<int> splits;
  final int currentSplitIndex;
  final bool isPedestrianNSGreen;
  final bool isPedestrianEWGreen;

  SignalState({
    required this.intersectionId,
    required this.cycle,
    required this.splits,
    required this.currentSplitIndex,
    required this.isPedestrianNSGreen,
    required this.isPedestrianEWGreen,
  });

  Color getCrosswalkColor(bool isNorthSouth) {
    if (isNorthSouth) {
      return isPedestrianNSGreen
          ? Colors.green.withAlpha(200)
          : Colors.red.withAlpha(200);
    } else {
      return isPedestrianEWGreen
          ? Colors.green.withAlpha(200)
          : Colors.red.withAlpha(200);
    }
  }
}

Future<SignalState?> Signal_calculator(
  Map<String, dynamic>? patternData,
  int intersectionId,
) async {
  if (patternData == null || patternData.isEmpty) {
    print("パターンがないよ！！ $intersectionId");
    return null;
  }

  String patternId = patternData['pattern_id'];

  try {
    final patternResult = await supabase
        .from('intersection_pattern_aichi')
        .select()
        .eq('intersection_id', intersectionId)
        .eq('id', patternId);

    if (patternResult.isEmpty) {
      print("パターン取得できないよ $intersectionId: $patternId");
      return null;
    }

    final pattern = patternResult[0];

    int cycle = pattern['cycle'];
    List<int> splits = [];

    for (int i = 1; i <= 6; i++) {
      if (pattern['split$i'] != null) {
        splits.add(pattern['split$i']);
      }
    }

    if (splits.isEmpty) {
      print("スプリットがないよ $intersectionId");
      return null;
    }

    List<double> splitTimesSeconds = [];
    for (int split in splits) {
      // パーセンテージから秒数に変換
      double splitSeconds = cycle * split / 100;
      splitTimesSeconds.add(splitSeconds);
    }

    // 累積スプリット時間の計算
    List<double> accumulatedSplitTimes = [];
    double accumulated = 0;
    for (double splitTime in splitTimesSeconds) {
      accumulated += splitTime;
      accumulatedSplitTimes.add(accumulated);
    }

    // 現在時刻をサイクル長で割った余り
    DateTime now = DateTime.now();
    int secondsSinceMidnight = now.hour * 3600 + now.minute * 60 + now.second;
    double currentCycleTime = (secondsSinceMidnight % cycle).toDouble();

    // 現在どのスプリット内にいるか
    int currentSplitIndex = 0;
    double timeAccumulated = 0;

    for (int i = 0; i < splitTimesSeconds.length; i++) {
      timeAccumulated += splitTimesSeconds[i];
      if (currentCycleTime < timeAccumulated) {
        currentSplitIndex = i;
        break;
      }
    }

    bool isPedestrianNSGreen = false;
    bool isPedestrianEWGreen = false;

    if (splits.length == 4) {
      // スプリット1: 方向A青、スプリット2: 方向A矢印、スプリット3: 方向B青、スプリット4: 方向B矢印
      isPedestrianNSGreen = (currentSplitIndex == 2);

      isPedestrianEWGreen = (currentSplitIndex == 0);
    } else if (splits.length == 3) {
      // スプリットが3つの場合: スプリット1=方向A青、スプリット2=矢印、スプリット3=方向B青
      isPedestrianNSGreen = (currentSplitIndex == 2);
      isPedestrianEWGreen = (currentSplitIndex == 0);
    } else if (splits.length == 2) {
      // スプリットが2つの場合: スプリット1=方向A青、スプリット2=方向B青
      isPedestrianNSGreen = (currentSplitIndex == 1);
      isPedestrianEWGreen = (currentSplitIndex == 0);
    } else {
      // その他のスプリット数の場合は適当
      isPedestrianNSGreen = (currentSplitIndex == 3);
      isPedestrianEWGreen = (currentSplitIndex == 0);
    }

    return SignalState(
      intersectionId: intersectionId,
      cycle: cycle,
      splits: splits,
      currentSplitIndex: currentSplitIndex,
      isPedestrianNSGreen: isPedestrianNSGreen,
      isPedestrianEWGreen: isPedestrianEWGreen,
    );
  } catch (e) {
    print("信号状態計算エラー $intersectionId: $e");
    return null;
  }
}
