import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geek_hackathon1_21/constants.dart';
import 'package:geek_hackathon1_21/services/signal_pattern_manager.dart';

class SidebarWidget extends ConsumerWidget {
  final bool _isSidebarVisible;
  final String? selectedMarkerId;
  final VoidCallback onClose;

  // 現在時刻を管理するための ValueNotifier
  static final ValueNotifier<String?> _currentTimeNotifier =
      ValueNotifier<String?>(null);

  final SignalPatternManager _patternManager = SignalPatternManager();

  SidebarWidget({
    Key? key,
    required bool isVisible,
    this.selectedMarkerId,
    required this.onClose,
  }) : _isSidebarVisible = isVisible,
       super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 200),
      right: _isSidebarVisible ? 0 : -280,
      top: 0,
      bottom: 0,
      width: 280,
      child: FutureBuilder<PatternInfo?>(
        future:
            selectedMarkerId != null
                ? _patternManager.getPatternInfo(int.parse(selectedMarkerId!))
                : Future.value(null),
        builder: (context, snapshot) {
          final patternInfo = snapshot.data;
          final signalState = patternInfo?.currentState;

          return Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "マーカーID:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  selectedMarkerId ?? "選択なし",
                  style: TextStyle(fontSize: 16),
                ),

                SizedBox(height: 20),
                Text(
                  "サイクル長:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  signalState?.cycle != null
                      ? "${signalState!.cycle}秒"
                      : "データなし",
                  style: TextStyle(fontSize: 16),
                ),

                SizedBox(height: 20),
                Text(
                  "スプリット情報:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                if (signalState?.splits != null &&
                    signalState!.splits.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < signalState.splits.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color:
                                      i == signalState.currentSplitIndex
                                          ? Colors.green
                                          : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "スプリット${i + 1}: ${signalState.splits[i]}% (${(signalState.cycle * signalState.splits[i] / 100).round()}秒)",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      i == signalState.currentSplitIndex
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 10),
                      Text(
                        "現在のスプリット: ${signalState.currentSplitIndex + 1}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  )
                else
                  Text("スプリットデータなし", style: TextStyle(fontSize: 14)),

                SizedBox(height: 20),
                Text(
                  "横断歩道状態:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                if (signalState != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            color:
                                signalState.isPedestrianNSGreen
                                    ? Colors.green
                                    : Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "南北方向: ${signalState.isPedestrianNSGreen ? '青信号' : '赤信号'}",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            color:
                                signalState.isPedestrianEWGreen
                                    ? Colors.green
                                    : Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "東西方向: ${signalState.isPedestrianEWGreen ? '青信号' : '赤信号'}",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Text("データなし", style: TextStyle(fontSize: 14)),

                SizedBox(height: 20),
                Text(
                  "信号パターン:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  patternInfo != null
                      ? "${patternInfo.patternData['pattern_id']}"
                      : "データなし",
                  style: TextStyle(fontSize: 14),
                ),

                SizedBox(height: 10),
                Text(
                  "次のパターン変更:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  patternInfo != null
                      ? "${patternInfo.nextChangeTime.hour}:${patternInfo.nextChangeTime.minute.toString().padLeft(2, '0')} (${patternInfo.nextPatternId})"
                      : "データなし",
                  style: TextStyle(fontSize: 14),
                ),

                Spacer(),
                ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 40),
                  ),
                  child: Text("閉じる"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
