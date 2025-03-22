import 'package:geek_hackathon1_21/constants.dart';
import 'package:geek_hackathon1_21/repositories/signal_calculator.dart';

class IntersectionRepository {
  Future<List<Map<String, dynamic>>> getIntersectionsInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    try {
      final markerMap = await supabase
          .from('intersection_location')
          .select('lat, lon, intersection_id')
          .gte('lat', minLat)
          .lte('lat', maxLat)
          .gte('lon', minLng)
          .lte('lon', maxLng);

      final markers = <Map<String, dynamic>>[];

      for (final item in markerMap) {
        final intersectionId = item['intersection_id'];
        final patternData = await getLatestPatternData(intersectionId);
        if (patternData?.isEmpty ?? true) {
          print("データがないよ！！");
        } else {
          final SignalData = await Signal_calculator(
            patternData,
            intersectionId,
          );
        }

        markers.add(item);
      }

      return markers;
    } catch (e) {
      print('交差点データ取得エラー: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLatestPatternData(int intersectionId) async {
    DateTime now = DateTime.now();
    int weekdayNumber = now.weekday; // 1:月, 2:火, ..., 7:日
    String time =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";

    String dayType;
    if (weekdayNumber >= 1 && weekdayNumber <= 5) {
      dayType = "weekday";
    } else if (weekdayNumber == 6) {
      dayType = "saturday";
    } else {
      dayType = "sunday";
    }

    try {
      final response = await supabase
          .from('intersection_regular_time_data')
          .select()
          .eq('intersection_id', intersectionId)
          .eq('day_type', dayType)
          .lte('time', time)
          .order('time', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return response[0];
      }

      return null;
    } catch (e) {
      print("パターン取得エラー $intersectionId: $e");
      return null;
    }
  }
}
