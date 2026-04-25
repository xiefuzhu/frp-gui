import 'package:flutter/material.dart';
import '../../components/Main/Appbar.dart';
import '../../pages/Main/index.dart';
import 'Pages.dart';
import 'TabBarButton.dart';
import 'package:flutter/foundation.dart';


// 手机端页面
class PhonePage extends StatefulWidget {
  const PhonePage({super.key});

  @override
  State<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: defaultTargetPlatform == TargetPlatform.android ? null : appBar(context),
      body: Column(
        children: [
          // 主内容区域
          pages(context),
          // 底部导航栏
          NavigationBar(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
            // 点击底部按钮时切换页面
            onDestinationSelected: (int index) {
              previousIndex = currentIndex;
              currentIndex = index;
              setState(() {});
            },
            // 当前选中的索引
            selectedIndex: currentIndex,
            // 底部按钮列表
            destinations: getBottomTabBarWidget(),
          ),
        ],
      ),
    );
  }
}
