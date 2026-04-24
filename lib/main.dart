import 'package:flutter/material.dart';
import 'package:frp_flutter/routes/index.dart';
import 'package:toml/toml.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  //确保 Flutter 绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();

  //初始化 window_manager
  await windowManager.ensureInitialized();

  //配置窗口选项
  WindowOptions windowOptions = const WindowOptions(
    //启动时窗口大小
    size: Size(800, 600),

    //窗口最小大小
    minimumSize: Size(400, 480),

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

  runApp(AppRestartWrapper());
}

//加载toml文件并转成map类型(调用方式：var data = await frpToml()，需要future)
Future<Map> frpToml() async {
  var document = await TomlDocument.load('lib/frp/frpc.toml');

  //转换为标准Map类型进行存取
  var config = document.toMap();
  return config;
}
