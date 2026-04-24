import 'package:flutter/material.dart';
import '../pages/Main/index.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:system_theme/system_theme.dart';

//声明主题模式和主题色初始值，在后面外观设置功能中用来修改
ThemeMode themeMode = ThemeMode.system;
Color colorMode = SystemTheme.accentColor.accent;

Widget getRootWidge() {
  return DynamicColorBuilder(
    builder: (lightDynamic, darkDynamic) {
      //深色模式与浅色模式的声明
      final lightScheme = ColorScheme.fromSeed(
        //跟随系统强调色
        seedColor: colorMode,
      );

      final darkScheme = ColorScheme.fromSeed(
        //跟随系统强调色
        seedColor: colorMode,
        brightness: Brightness.dark,
      );

      return MaterialApp(
        //浅色模式
        theme: ThemeData(useMaterial3: true, colorScheme: lightScheme),

        //深色模式
        darkTheme: ThemeData(useMaterial3: true, colorScheme: darkScheme),

        //深色浅色模式跟随系统
        themeMode: themeMode,

        //主路由
        initialRoute: "/",

        //命名路由
        routes: getRootRontes(),
      );
    },
  );
}

Map<String, Widget Function(BuildContext)> getRootRontes() {
  return {
    //主页面路由
    "/": (context) => MainPage(),
  };
}

//全局重建（使用AppRestartWrapper.restart(context)触发;）
class AppRestartWrapper extends StatefulWidget {
  const AppRestartWrapper({super.key});

  @override
  State<AppRestartWrapper> createState() => _AppRestartWrapperState();
  // 全局重建入口
  static void restart(BuildContext context) {
    final state = context.findAncestorStateOfType<_AppRestartWrapperState>();
    state?._restart();
  }
}

class _AppRestartWrapperState extends State<AppRestartWrapper> {
  UniqueKey _appKey = UniqueKey();

  void _restart() {
    setState(() {
      _appKey = UniqueKey(); // Key 变化 → 整个子树重建
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _appKey,
      child: getRootWidge(), //要重建的页面
    );
  }
}
