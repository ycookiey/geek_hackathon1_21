import 'package:flutter/material.dart';

class SidebarWidget extends StatelessWidget {
  final bool _isSidebarVisible;
  final String? selectedMarkerId;
  final VoidCallback onClose;

  const SidebarWidget({
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
            Spacer(),
            ElevatedButton(onPressed: onClose, child: Text("閉じる")),
          ],
        ),
      ),
    );
  }
}
