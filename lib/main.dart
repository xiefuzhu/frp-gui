import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frp_gui/routes/index.dart';
import 'package:frp_gui/utils/FrpService.dart';
import 'package:frp_gui/utils/TerminalUtil.dart';
import 'package:frp_gui/pages/OOBE/index.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart';

Future<void> main(List<String> args) async {
  //确保 Flutter 绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 加载持久化的主题设置
  await loadPersistedTheme();

  // 检查 OOBE 是否已完成，未完成则引导至 OOBE 页面
  final oobeCompleted = await isOobeCompleted();
  if (!oobeCompleted) {
    initialRoute = '/oobe';
  }

  //初始化 window_manager
  await windowManager.ensureInitialized();

  //配置窗口选项
  if (defaultTargetPlatform == TargetPlatform.windows) {
    WindowOptions windowOptions = const WindowOptions(
      //启动时窗口大小
      size: Size(800, 600),

      //窗口最小大小
      minimumSize: Size(400, 400),

      //窗口是否居中
      center: true,

      //隐藏系统标题栏
      titleBarStyle: TitleBarStyle.hidden,
    );

    //等待窗口准备就绪并显示
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } else if (defaultTargetPlatform == TargetPlatform.android) {}

  runApp(getRootWidget());

  // 桌面平台：仅在系统开机自启动时（携带 --autostart 参数）自动启动 frp
  // 用户手动打开应用时不会自动启动
  if (Platform.isMacOS || Platform.isWindows) {
    final isAutoStart = args.contains('--autostart');
    if (isAutoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        TerminalUtil.instance.writeLog('系统开机自启，自动启动frp服务...');
        await FrpService.instance.startFrp();
      });
    }
  }
}
