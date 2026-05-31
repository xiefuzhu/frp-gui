import 'package:flutter/material.dart';
import '../../components/Main/Appbar.dart';
import '../../pages/Main/index.dart';
import 'Pages.dart';
import 'TabBarButton.dart';
import 'package:flutter/foundation.dart';

class NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
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
  NavigationRailLabelType labelType = NavigationRailLabelType.all;

  @override
  void initState() {
    super.initState();
    currentIndexNotifier.addListener(_onIndexChanged);
  }

  @override
  void dispose() {
    currentIndexNotifier.removeListener(_onIndexChanged);
    super.dispose();
  }

  void _onIndexChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final idx = currentIndexNotifier.value;
    return Scaffold(
      appBar: defaultTargetPlatform == TargetPlatform.macOS
          ? null
          : appBar(context),
      body: Row(
        children: <Widget>[
          ScrollConfiguration(
            behavior: NoScrollbarBehavior(),
            child: NavigationRail(
              scrollable: true,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerLow,
              onDestinationSelected: (int index) {
                previousIndex = idx;
                currentIndexNotifier.value = index;
              },
              labelType: labelType,
              destinations: getSideTabBarWidget(),
              selectedIndex: idx,
              trailingAtBottom: true,
              trailing: Container(
                margin: EdgeInsets.only(top: 15, bottom: 15),
                child: IconButton(
                  onPressed: () {
                    labelType == NavigationRailLabelType.all
                        ? labelType = NavigationRailLabelType.none
                        : labelType = NavigationRailLabelType.all;
                    setState(() {});
                  },
                  icon: Icon(Icons.menu, size: 25),
                ),
              ),
            ),
          ),
          pages(context),
        ],
      ),
    );
  }
}
