import 'package:flutter/material.dart';

import '../pages/download/download_page.dart';
import '../pages/home/home_page.dart';
import '../pages/logs/logs_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/tunnels/tunnels_page.dart';
import 'desktop_title_bar.dart';

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _NoScrollbarBehavior extends ScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: '首页',
    ),
    _NavItem(
      icon: Icons.cloud_outlined,
      selectedIcon: Icons.cloud,
      label: '隧道',
    ),
    _NavItem(
      icon: Icons.download_outlined,
      selectedIcon: Icons.download,
      label: '内核',
    ),
    _NavItem(
      icon: Icons.terminal_outlined,
      selectedIcon: Icons.terminal,
      label: '日志',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: '设置',
    ),
  ];

  int _currentIndex = 0;
  int _previousIndex = 0;
  NavigationRailLabelType _railLabelType = NavigationRailLabelType.all;

  void _selectTab(int nextIndex) {
    if (nextIndex == _currentIndex) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = nextIndex;
    });
  }

  Widget _buildActivePage(int index) {
    switch (index) {
      case 0:
        return const HomePage(key: ValueKey('home'));
      case 1:
        return const TunnelsPage(key: ValueKey('tunnels'));
      case 2:
        return const DownloadPage(key: ValueKey('download'));
      case 3:
        return const LogsPage(key: ValueKey('logs'));
      case 4:
        return const SettingsPage(key: ValueKey('settings'));
      default:
        return const HomePage(key: ValueKey('home'));
    }
  }

  Widget _buildAnimatedContent({required bool isDesktopLayout}) {
    final isForward = _currentIndex >= _previousIndex;
    final currentPage = _buildActivePage(_currentIndex);

    return Expanded(
      child: SafeArea(
        child: AnimatedSwitcher(
          switchInCurve: Curves.decelerate,
          switchOutCurve: Curves.decelerate,
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            final isIncoming = child.key == currentPage.key;
            final desktopOffset = isIncoming
                ? (isForward ? const Offset(0, -1) : const Offset(0, 1))
                : (isForward ? const Offset(0, 1) : const Offset(0, -1));
            final compactOffset = isIncoming
                ? (isForward ? const Offset(1, 0) : const Offset(-1, 0))
                : (isForward ? const Offset(-1, 0) : const Offset(1, 0));

            return SlideTransition(
              position: Tween<Offset>(
                begin: isDesktopLayout ? desktopOffset : compactOffset,
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
          child: currentPage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktopLayout = constraints.maxWidth > 600;
        final scheme = Theme.of(context).colorScheme;

        if (isDesktopLayout) {
          return Scaffold(
            appBar: const DesktopTitleBar(),
            body: Row(
              children: [
                ScrollConfiguration(
                  behavior: const _NoScrollbarBehavior(),
                  child: NavigationRail(
                    scrollable: true,
                    backgroundColor: scheme.surfaceContainerLow,
                    selectedIndex: _currentIndex,
                    onDestinationSelected: _selectTab,
                    labelType: _railLabelType,
                    destinations: _navItems
                        .map(
                          (item) => NavigationRailDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon),
                            label: Text(item.label),
                          ),
                        )
                        .toList(),
                    trailingAtBottom: true,
                    trailing: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: IconButton(
                        tooltip: '展开/收起标签',
                        onPressed: () {
                          setState(() {
                            _railLabelType =
                                _railLabelType == NavigationRailLabelType.all
                                    ? NavigationRailLabelType.none
                                    : NavigationRailLabelType.all;
                          });
                        },
                        icon: const Icon(Icons.menu, size: 22),
                      ),
                    ),
                  ),
                ),
                _buildAnimatedContent(isDesktopLayout: true),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: const DesktopTitleBar(),
          body: Column(
            children: [
              _buildAnimatedContent(isDesktopLayout: false),
              NavigationBar(
                backgroundColor: scheme.surfaceContainerLow,
                selectedIndex: _currentIndex,
                onDestinationSelected: _selectTab,
                destinations: _navItems
                    .map(
                      (item) => NavigationDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: item.label,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
