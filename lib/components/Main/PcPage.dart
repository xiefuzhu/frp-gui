import 'package:flutter/material.dart';
import '../../components/Main/Appbar.dart';
import '../../pages/Main/index.dart';
import 'Pages.dart';
import 'TabBarButton.dart';

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
      appBar: appBar(context),
      body: Row(
        children: <Widget>[
          // 左侧导航栏
          NavigationRail(
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
            // 底部附加区域
            // 这里放了一个切换标签显示/隐藏的按钮
            trailing: Expanded(
              child: Column(
                // 这里使用 end，所以按钮会被放到底部
                // 如果你想放到顶部，这里应改成 MainAxisAlignment.start
                mainAxisAlignment: MainAxisAlignment.end,
                // 横向居中
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 切换是否隐藏导航按钮文字
                  IconButton(
                    onPressed: () {
                      labelType == NavigationRailLabelType.all
                          ? labelType = NavigationRailLabelType.none
                          : labelType = NavigationRailLabelType.all;
                      setState(() {});
                    },
                    icon: Icon(Icons.menu),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // 右侧主内容区域
          pages(context),
        ],
      ),
    );
  }
}