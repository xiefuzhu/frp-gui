import 'package:flutter/material.dart';

// 底部/侧边导航栏配置列表
// 每一项包含：默认图标、选中图标、显示文字
final List<Map<String, dynamic>> _tablist = [
  {
    "icon": Icons.home_outlined,
    "active_icon": Icons.home,
    "text": "首页"
  },
  {
    "icon": Icons.cloud_outlined,
    "active_icon": Icons.cloud,
    "text": "隧道"
  },
  {
    "icon": Icons.download_outlined,
    "active_icon": Icons.download,
    "text": "内核"
  },
  {
    "icon": Icons.terminal_outlined,
    "active_icon": Icons.terminal,
    "text": "日志"
  },
  {
    "icon": Icons.settings_outlined,
    "active_icon": Icons.settings,
    "text": "设置"
  },
];

// 构建电脑端左侧 NavigationRail 使用的按钮列表
List<NavigationRailDestination> getSideTabBarWidget() {
  return List.generate(_tablist.length, (int index) {
    return NavigationRailDestination(
      // 未选中图标
      icon: Icon(_tablist[index]["icon"]!),
      // 选中图标
      selectedIcon: Icon(_tablist[index]["active_icon"]!),
      // 按钮文字
      label: Text(_tablist[index]["text"]),
    );
  });
}


// 构建手机端底部 NavigationBar 使用的按钮列表
List<Widget> getBottomTabBarWidget() {
  return List.generate(_tablist.length, (int index) {
    return NavigationDestination(
      // 未选中图标
      icon: Icon(_tablist[index]["icon"]!),
      // 选中图标
      selectedIcon: Icon(_tablist[index]["active_icon"]!),
      // 按钮文字
      label: _tablist[index]["text"],
    );
  });
}
