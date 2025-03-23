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
  final int remainingSeconds;
  final double remainingSecondsExact;
  final DateTime calculatedAt;
  final int? offset;

  SignalState({
    required this.intersectionId,
    required this.cycle,
    required this.splits,
    required this.currentSplitIndex,
    required this.isPedestrianNSGreen,
    required this.isPedestrianEWGreen,
    required this.remainingSeconds,
    required this.remainingSecondsExact,
    required this.calculatedAt,
    this.offset,
  });

  int getCurrentRemainingSeconds() {
    final now = DateTime.now();
    final elapsedSinceCalculation =
        now.difference(calculatedAt).inMilliseconds / 1000.0;
    final currentRemaining = remainingSecondsExact - elapsedSinceCalculation;
    return currentRemaining > 0 ? currentRemaining.round() : 0;
  }

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

  bool isNextToTurnGreen(bool isNorthSouth) {
    if (splits.length == 4) {
      if (currentSplitIndex == 1) {
        return isNorthSouth;
      } else if (currentSplitIndex == 3) {
        return !isNorthSouth;
      }
    } else if (splits.length == 3) {
      if (currentSplitIndex == 1) {
        return isNorthSouth;
      } else if (currentSplitIndex == 2) {
        return !isNorthSouth;
      }
    } else if (splits.length == 2) {
      if (currentSplitIndex == 0) {
        return isNorthSouth;
      } else {
        return !isNorthSouth;
      }
    }
    return false;
  }

  int getSecondsUntilNextGreen(bool isNorthSouth) {
    if (isGreen(isNorthSouth)) {
      return getCurrentRemainingSeconds();
    }

    if (!isNextToTurnGreen(isNorthSouth)) {
      return -1;
    }

    int secondsToNextSplit = getCurrentRemainingSeconds();
    return secondsToNextSplit;
  }

  bool isGreen(bool isNorthSouth) {
    return isNorthSouth ? isPedestrianNSGreen : isPedestrianEWGreen;
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
  final calculationTime = DateTime.now();

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

    int offsetValue = 0;

    final offsetResult = await supabase
        .from('intersection_regular_time_data')
        .select('offset')
        .eq('intersection_id', intersectionId)
        .eq('pattern_id', patternId)
        .limit(1);

    if (offsetResult.isNotEmpty && offsetResult[0]['offset'] != null) {
      offsetValue = offsetResult[0]['offset'] as int;
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

    DateTime now = calculationTime;
    int secondsSinceMidnight = now.hour * 3600 + now.minute * 60 + now.second;
    double millisecondsFraction = now.millisecond / 1000.0;

    double currentCycleTime;

    int adjustedSeconds = (secondsSinceMidnight - offsetValue) % cycle;
    if (adjustedSeconds < 0) adjustedSeconds += cycle;
    currentCycleTime = adjustedSeconds + millisecondsFraction;

    // 現在どのスプリット内にいるか
    int currentSplitIndex = 0;
    double timeAccumulated = 0;
    double previousTimeAccumulated = 0;

    for (int i = 0; i < splitTimesSeconds.length; i++) {
      previousTimeAccumulated = timeAccumulated;
      timeAccumulated += splitTimesSeconds[i];
      if (currentCycleTime < timeAccumulated) {
        currentSplitIndex = i;
        break;
      }
    }

    double elapsedTimeInCurrentSplit =
        currentCycleTime - previousTimeAccumulated;
    double totalSplitTime = splitTimesSeconds[currentSplitIndex];
    double remainingTimeInCurrentSplit =
        totalSplitTime - elapsedTimeInCurrentSplit;

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
      remainingSeconds: remainingTimeInCurrentSplit.round(),
      remainingSecondsExact: remainingTimeInCurrentSplit,
      calculatedAt: calculationTime,
      offset: offsetValue,
    );
  } catch (e) {
    print("信号状態計算エラー $intersectionId: $e");
    return null;
  }
}
