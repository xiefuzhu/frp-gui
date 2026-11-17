import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frp_gui/app.dart';
import 'package:frp_gui/controllers/tunnel_list_controller.dart';
import 'package:frp_gui/services/auto_start_service.dart';
import 'package:frp_gui/services/config_repository.dart';
import 'package:frp_gui/services/frp_paths.dart';
import 'package:frp_gui/ui/pages/tunnels/tunnels_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('frp_widget_test_');
    FrpPaths.debugBaseDirOverride = tempDir.path;
    AutoStartService.debugOverrideEnabled = false;
    await ConfigRepository.instance.ensureLayout();
  });

  tearDown(() async {
    FrpPaths.debugBaseDirOverride = null;
    AutoStartService.debugOverrideEnabled = null;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('Desktop and compact layout navigation smoke test', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'oobe_completed': true});

    try {
      tester.view.physicalSize = const Size(840, 620);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const FrpGuiApp());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('点击连接'), findsOneWidget);
      expect(find.byType(NavigationRail), findsOneWidget);

      await _openTunnels(tester);
      expect(find.byType(TunnelsPage), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.text('日志'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('暂无日志输出'), findsOneWidget);

      await tester.tap(find.text('设置'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('外观'), findsOneWidget);
      expect(find.text('服务端'), findsOneWidget);

      tester.view.physicalSize = const Size(420, 800);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(NavigationBar), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('OOBE setup wizard skips cleanly to main shell', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    try {
      tester.view.physicalSize = const Size(840, 620);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const FrpGuiApp(showOobe: true));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('欢迎使用 frp-gui'), findsOneWidget);
      await tester.tap(find.text('稍后在设置中配置'));
      await tester.pumpAndSettle();

      expect(find.text('点击连接'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('TunnelFormDialog switches protocol fields and validates input', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'oobe_completed': true});

    try {
      tester.view.physicalSize = const Size(840, 620);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const FrpGuiApp());
      await tester.pump(const Duration(milliseconds: 300));

      await _openTunnels(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('添加隧道'), findsOneWidget);
      expect(find.text('远程端口'), findsOneWidget);

      await tester.tap(find.text('http'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('自定义域名'), findsOneWidget);

      await tester.ensureVisible(find.text('stcp'));
      await tester.pump();
      await tester.tap(find.text('stcp'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('访问密钥'), findsOneWidget);

      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('请输入隧道名称'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}

Future<void> _openTunnels(WidgetTester tester) async {
  final controller = TunnelListController.instance;
  await tester.tap(find.text('隧道'));
  await tester.pump();

  // File I/O needs real time; its continuations also need fake-zone pumps.
  final stopwatch = Stopwatch()..start();
  while (controller.isLoading &&
      stopwatch.elapsed < const Duration(seconds: 10)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }

  expect(controller.isLoading, isFalse, reason: '隧道配置加载超时');
  expect(controller.error, isNull);
  await tester.pumpAndSettle();
  expect(find.text('暂无隧道配置，点击右下角按钮新增'), findsOneWidget);
}
