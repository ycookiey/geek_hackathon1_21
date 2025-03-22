import 'dart:async';

import 'package:geek_hackathon1_21/constants.dart';

//final SignalData = await Signal_calculator(patternData, intersectionId);

Future<Map<String, dynamic>?> Signal_calculator(
  Map<String, dynamic>? patternData,
  int intersectionId,
) async {
  String _PatternId = patternData!['pattern_id'];
  //print(_PatternId);
  //print("だよーん");

  if (patternData.isNotEmpty) {
    try {
      final PatternResult = await supabase
          .from('intersection_pattern_aichi')
          .select()
          .eq('intersection_id', intersectionId)
          .eq('id', _PatternId);

      if (PatternResult.isNotEmpty) {
        print(PatternResult);
        print("だよーん");

        return PatternResult[0];
      }

      return null;
    } catch (e) {
      print("パターン取得エラーだよ！！ $intersectionId: $e");
      return null;
    }
  }
  print("パターンがねぇやつだよ！！");
  return null;
}
