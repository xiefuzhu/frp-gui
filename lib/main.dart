import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'controllers/theme_controller.dart';
import 'services/frp_process_service.dart';
import 'services/log_service.dart';
import 'services/preferences_service.dart';

class _AppWindowListener extends WindowListener {
  @override
  Future<void> onWindowClose() async {
    final isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await FrpProcessService.instance.stop();
      await windowManager.setPreventClose(false);
      await windowManager.close();
    }
  }
}

final _windowListener = _AppWindowListener();

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await ThemeController.instance.init();

  final isAutoStart = args.contains('--autostart');
  final oobeDone = await PreferencesService.instance.isOobeCompleted();

  final isDesktop =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  if (isDesktop) {
    await windowManager.ensureInitialized();
    windowManager.addListener(_windowListener);
    await windowManager.setPreventClose(true);

    const windowOptions = WindowOptions(
      size: Size(840, 620),
      minimumSize: Size(420, 420),
      center: true,
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(FrpGuiApp(showOobe: !oobeDone && !isAutoStart));

  if (isAutoStart &&
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      LogService.instance.write('系统开机自启，自动启动 frp 服务...');
      await FrpProcessService.instance.start();
    });
  }
}
