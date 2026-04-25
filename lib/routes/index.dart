import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../pages/Main/index.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:system_theme/system_theme.dart';

//声明主题模式和主题色初始值，在后面外观设置功能中用来修改
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
final colorModeNotifier = ValueNotifier<Color>(SystemTheme.accentColor.accent);


Widget getRootWidget() {
  return ValueListenableBuilder<ThemeMode>(
    valueListenable: themeModeNotifier,
    builder: (context, themeMode, _) {
      
      return ValueListenableBuilder<Color>(
        valueListenable: colorModeNotifier,
        builder: (context, colorMode, _) {

          return DynamicColorBuilder(
            builder: (lightDynamic, darkDynamic) {
              final lightScheme = ColorScheme.fromSeed(seedColor: colorMode);
              final darkScheme = ColorScheme.fromSeed(
                seedColor: colorMode,
                brightness: Brightness.dark,
              );

              return MaterialApp(
                theme: ThemeData(useMaterial3: true, colorScheme: lightScheme),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  colorScheme: darkScheme,
                ),
                themeMode: themeMode,

                //汉化万能搭配
                locale: const Locale('zh', 'CN'),
                supportedLocales: const [
                  Locale('zh', 'CN'),
                  Locale('en', 'US'),
                ],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                //

                initialRoute: "/",
                routes: getRootRoutes(),
              );
            },
          );
        },
      );
    },
  );
}

Map<String, Widget Function(BuildContext)> getRootRoutes() {
  return {
    //主页面路由
    "/": (context) => const MainPage(),
  };
}
