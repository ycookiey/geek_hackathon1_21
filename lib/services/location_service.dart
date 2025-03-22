import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<void> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        print("位置情報の権限が拒否されました");
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        print("位置情報の権限が永久に拒否されています。設定から変更してください。");
        return;
      }

      print("位置情報の権限が許可されました");
    }
  }
}
