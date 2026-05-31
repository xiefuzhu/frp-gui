import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../utils/FrpService.dart';

// 自定义标题栏
// 主要用于桌面端窗口控制：拖动、双击最大化、最小化、关闭等
AppBar appBar(BuildContext context) {
  return AppBar(
    flexibleSpace: GestureDetector(
      // 双击标题栏时：在最大化和还原之间切换
      onDoubleTap: () async {
        if (await windowManager.isMaximized()) {
          windowManager.restore();
        } else {
          windowManager.maximize();
        }
      },
      // 按下并拖动标题栏时：拖动窗口
      // 使用 onPanStart 可以避免和普通点击事件冲突
      onPanStart: (_) {
        windowManager.startDragging();
      },
      child: Container(
        // 让标题整体靠左显示
        alignment: Alignment.centerLeft,
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text("frp_desktop", style: TextStyle()),
        ),
      ),
    ),
    // 标题栏背景颜色
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    // 标题栏高度
    toolbarHeight: 35,

    // 右上角窗口控制按钮
    actions: [
      // 最小化窗口
      IconButton(
        onPressed: () {
          windowManager.minimize();
        },
        icon: const Icon(Icons.horizontal_rule, size: 20),
      ),
      // 最大化/还原窗口
      IconButton(
        onPressed: () async {
          if (await windowManager.isMaximized()) {
            windowManager.restore();
          } else {
            windowManager.maximize();
          }
        },
        icon: const Icon(Icons.crop_square, size: 20),
      ),
      // 关闭窗口
      IconButton(
        onPressed: () {
          FrpService.instance.stopFrp();
          windowManager.close();
        },
        icon: const Icon(Icons.close, size: 20),
      ),
    ],
  );
}
