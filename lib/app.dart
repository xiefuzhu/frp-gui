import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'controllers/theme_controller.dart';
import 'ui/pages/oobe/oobe_page.dart';
import 'ui/shell/main_shell_page.dart';

class FrpGuiApp extends StatelessWidget {
  final bool showOobe;

  const FrpGuiApp({
    super.key,
    this.showOobe = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeCtrl = ThemeController.instance;

    return ListenableBuilder(
      listenable: themeCtrl,
      builder: (context, _) {
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            final seed = themeCtrl.accentColor;
            final lightScheme = ColorScheme.fromSeed(seedColor: seed);
            final darkScheme = ColorScheme.fromSeed(
              seedColor: seed,
              brightness: Brightness.dark,
            );

            return MaterialApp(
              title: 'frp-gui',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(useMaterial3: true, colorScheme: lightScheme),
              darkTheme: ThemeData(useMaterial3: true, colorScheme: darkScheme),
              themeMode: themeCtrl.themeMode,
              locale: const Locale('zh', 'CN'),
              supportedLocales: const [
                Locale('zh', 'CN'),
                Locale('en', 'US'),
              ],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              initialRoute: showOobe ? '/oobe' : '/',
              routes: {
                '/': (_) => const MainShellPage(),
                '/oobe': (_) => const OobePage(),
              },
            );
          },
        );
      },
    );
  }
}
