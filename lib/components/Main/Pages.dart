import 'package:flutter/material.dart';

// 导入各个页面组件，供主页面按索引切换显示
import '../../pages/Download/index.dart';
import '../../pages/Home/index.dart';
import '../../pages/Log/index.dart';
import '../../pages/Main/index.dart';
import '../../pages/Settings/index.dart';
import '../../pages/Tunnel/index.dart';

// 主内容区域
// 使用 AnimatedSwitcher 在页面切换时添加淡入淡出/切换动画
Expanded pages(BuildContext context) {
  final bool isForward = currentIndex > previousIndex;
  final currentPage = _buildPage(currentIndex);
  return Expanded(
    // SafeArea 用于避开系统状态栏、刘海、圆角等安全区域
    child: SafeArea(
        // 页面切换动画
        child: AnimatedSwitcher(
        // 新页面切入时的动画曲线
        switchInCurve: Curves.decelerate,
        switchOutCurve: Curves.decelerate,
        // 动画时长
        duration: Duration(milliseconds: 200),
        // 根据当前索引构建对应页面
        transitionBuilder: (child, animation) {

          // 根据新旧页面相对位置的情况，选择对应进入动画，即是从左往右还是从右往左进入
          final pcBeginOffset = (child.key == currentPage.key) ? (isForward ? const Offset(0, 1) : const Offset(0, -1)) : (isForward ? const Offset(0, -1) : const Offset(0, 1));
          final phoneBeginOffset = (child.key == currentPage.key) ? (isForward ? const Offset(1, 0) : const Offset(-1, 0)) : (isForward ? const Offset(-1, 0) : const Offset(1, 0));

          return SlideTransition(
            position: Tween<Offset>(
              //设置页面偏移量，以形成页面从左到右的进入动画
              begin: MediaQuery.of(context).size.width > 600 ? pcBeginOffset : phoneBeginOffset,
              end:  Offset.zero,
              ).animate(animation),
            child: child,
          );
        },
        

          child: currentPage,
        )
      )
  );
}

// 根据索引返回对应页面组件
// 这里给每个页面设置了不同的 ValueKey，
// 这样 AnimatedSwitcher 才能识别为“不同页面”并执行动画
Widget _buildPage(int index) {
  switch (index) {
    case 0:
      return const HomeView(key: ValueKey('home'));
    case 1:
      return const ProxyView(key: ValueKey('tunnel'));
    case 2:
      return const DownloadView(key: ValueKey('download'));
    case 3:
      return const LogView(key: ValueKey('log'));
    case 4:
      return const SettingView(key: ValueKey('setting'));
    default:
      return const HomeView(key: ValueKey('home'));
  }
}
