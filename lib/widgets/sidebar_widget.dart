import 'package:flutter/material.dart';
import 'package:geek_hackathon1_21/widgets/Offset.dart';

class SidebarWidget extends StatelessWidget {
  final bool _isSidebarVisible;
  final String? selectedMarkerId;
  final VoidCallback onClose;

  // 現在時刻を管理するための ValueNotifier
  static final ValueNotifier<String?> _currentTimeNotifier =
      ValueNotifier<String?>(null);

  SidebarWidget({
    Key? key,
    required bool isVisible,
    this.selectedMarkerId,
    required this.onClose,
  }) : _isSidebarVisible = isVisible,
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 200),
      right: _isSidebarVisible ? 0 : -200, // 非表示時は画面外へ
      top: 0,
      bottom: 0,
      width: 200,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "マーカーID:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(selectedMarkerId ?? "選択なし", style: TextStyle(fontSize: 16)),

            SizedBox(height: 20),
            Text(
              "記録時刻:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ValueListenableBuilder<String?>(
              valueListenable: _currentTimeNotifier,
              builder: (context, value, child) {
                return Text(value ?? "未記録", style: TextStyle(fontSize: 16));
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => offset(selectedMarkerId ?? "選択なし"),
              child: Text("現在時刻を記録"),
            ),

            Spacer(),
            ElevatedButton(onPressed: onClose, child: Text("閉じる")),
          ],
        ),
      ),
    );
  }
}
