import 'dart:async';
import 'package:geek_hackathon1_21/constants.dart';
import 'package:geek_hackathon1_21/repositories/signal_calculator.dart';

class PatternInfo {
  final Map<String, dynamic> patternData;
  final DateTime nextChangeTime;
  final String nextPatternId;
  SignalState? currentState;
  DateTime lastUpdated = DateTime.now();

  PatternInfo({
    required this.patternData,
    required this.nextChangeTime,
    required this.nextPatternId,
    this.currentState,
  });

  bool isStateOutdated() {
    final now = DateTime.now();
    // より頻繁に更新するため、100ms以上経過したら更新とする
    return now.difference(lastUpdated).inMilliseconds >= 100;
  }

  Future<void> updateSignalState(int intersectionId) async {
    currentState = await Signal_calculator(patternData, intersectionId);
    lastUpdated = DateTime.now();
  }

  // 現在の残り時間を取得（ステートの更新なしで計算可能）
  int getCurrentRemainingSeconds() {
    if (currentState == null) return 0;
    return currentState!.getCurrentRemainingSeconds();
  }
}

class SignalPatternManager {
  final Map<int, PatternInfo> _patternCache = {};

  Future<PatternInfo?> getPatternInfo(int intersectionId) async {
    final now = DateTime.now();

    if (_patternCache.containsKey(intersectionId)) {
      final cachedInfo = _patternCache[intersectionId]!;

      if (now.isBefore(cachedInfo.nextChangeTime)) {
        if (cachedInfo.isStateOutdated()) {
          await cachedInfo.updateSignalState(intersectionId);
        }
        return cachedInfo;
      }
      _patternCache.remove(intersectionId);
    }

    final dayType = _getDayType(now);

    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";

    try {
      final currentPatternResponse = await supabase
          .from('intersection_regular_time_data')
          .select()
          .eq('intersection_id', intersectionId)
          .eq('day_type', dayType)
          .lte('time', currentTime)
          .order('time', ascending: false)
          .limit(1);

      if (currentPatternResponse.isEmpty) {
        return null;
      }

      final currentPattern = currentPatternResponse[0];
      final currentPatternId = currentPattern['pattern_id'];

      final nextPatternResponse = await supabase
          .from('intersection_regular_time_data')
          .select()
          .eq('intersection_id', intersectionId)
          .eq('day_type', dayType)
          .gt('time', currentTime)
          .order('time', ascending: true)
          .limit(1);

      DateTime nextChangeTime;
      String nextPatternId;

      if (nextPatternResponse.isEmpty) {
        final nextDayResponse = await supabase
            .from('intersection_regular_time_data')
            .select()
            .eq('intersection_id', intersectionId)
            .eq('day_type', _getNextDayType(dayType))
            .order('time', ascending: true)
            .limit(1);

        final nextDay = nextDayResponse[0];
        final timeParts = nextDay['time'].split(':');
        nextChangeTime = DateTime(
          now.year,
          now.month,
          now.day + 1,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
        nextPatternId = nextDay['pattern_id'];
      } else {
        final nextPattern = nextPatternResponse[0];
        final timeParts = nextPattern['time'].split(':');
        nextChangeTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
        nextPatternId = nextPattern['pattern_id'];
      }

      final signalState = await Signal_calculator(
        currentPattern,
        intersectionId,
      );

      final patternInfo = PatternInfo(
        patternData: currentPattern,
        nextChangeTime: nextChangeTime,
        nextPatternId: nextPatternId,
        currentState: signalState,
      );

      _patternCache[intersectionId] = patternInfo;
      return patternInfo;
    } catch (e) {
      print("パターン情報取得エラー $intersectionId: $e");
      return null;
    }
  }

  String _getDayType(DateTime date) {
    final weekday = date.weekday;
    if (weekday >= 1 && weekday <= 5) {
      return "weekday";
    } else if (weekday == 6) {
      return "saturday";
    } else {
      return "sunday";
    }
  }

  String _getNextDayType(String currentDayType) {
    switch (currentDayType) {
      case "weekday":
        return (DateTime.now().weekday == 5) ? "saturday" : "weekday";
      case "saturday":
        return "sunday";
      case "sunday":
        return "weekday";
      default:
        return "weekday";
    }
  }

  void clearCache() {
    _patternCache.clear();
  }

  void clearCacheForIntersection(int intersectionId) {
    _patternCache.remove(intersectionId);
  }
}
