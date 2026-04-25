import 'package:flutter/material.dart';
import 'package:frp_flutter/routes/index.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart';

void main() async {
  //确保 Flutter 绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  //初始化 window_manager
  await windowManager.ensureInitialized();

  //配置窗口选项
  if(defaultTargetPlatform == TargetPlatform.windows){
  WindowOptions windowOptions = const WindowOptions(
    //启动时窗口大小
    size: Size(800, 600),

    //窗口最小大小
    minimumSize: Size(400, 300),

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
  }//完美解决git的问题

  runApp(getRootWidget());
}
