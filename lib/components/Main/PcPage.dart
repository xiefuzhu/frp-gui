import 'package:flutter/material.dart';
import '../../components/Main/Appbar.dart';
import '../../pages/Main/index.dart';
import 'Pages.dart';
import 'TabBarButton.dart';
import 'package:flutter/foundation.dart';

class NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child; // 直接返回子组件，不包裹滚动条
  }
}

// 电脑端页面
class PcPage extends StatefulWidget {
  const PcPage({super.key});

  @override
  State<PcPage> createState() => _PcPageState();
}

class _PcPageState extends State<PcPage> {
  // 控制 NavigationRail 标签文字是否显示
  // all = 一直显示，none = 不显示
  NavigationRailLabelType labelType = NavigationRailLabelType.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: defaultTargetPlatform == TargetPlatform.android ? null : appBar(context),
      body: Row(
        children: <Widget>[
          // 左侧导航栏
          ScrollConfiguration(
            behavior: NoScrollbarBehavior(),
            child: NavigationRail(
            //启用滚动
            scrollable: true,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
            // 点击导航项时切换页面
            onDestinationSelected: (int index) {
              previousIndex = currentIndex;
              currentIndex = index;
              setState(() {});
            },
            // 标签显示模式
            labelType: labelType,
            // 左侧导航项列表
            destinations: getSideTabBarWidget(),
            // 当前选中的项
            selectedIndex: currentIndex,
            //trailing置于底部
            trailingAtBottom: true,
            // 底部附加区域
            // 这里放了一个切换标签显示/隐藏的按钮
            trailing:  Container(
              margin: EdgeInsets.only(top: 15, bottom: 15),
              child: IconButton(
                  onPressed: () {
                    labelType == NavigationRailLabelType.all ? labelType = NavigationRailLabelType.none : labelType = NavigationRailLabelType.all;
                    setState(() {});
                  },
                  icon: Icon(Icons.menu, size: 25,),
                ),
              )      
            ),
          ),
          // 右侧主内容区域
          pages(context),
        ],
      ),
    );
  }
}