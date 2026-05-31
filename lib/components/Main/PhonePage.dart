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
      appBar: defaultTargetPlatform == TargetPlatform.android
          ? null
          : appBar(context),
      body: Column(
        children: [
          pages(context),
          NavigationBar(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
            onDestinationSelected: (int index) {
              previousIndex = idx;
              currentIndexNotifier.value = index;
            },
            selectedIndex: idx,
            destinations: getBottomTabBarWidget(),
          ),
        ],
      ),
    );
  }
}
