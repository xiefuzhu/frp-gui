import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'TerminalUtil.dart';

class FrpService {
  FrpService._();
  static final FrpService instance = FrpService._();

  Process? _frpProcess;

  /// frp 进程是否正在运行
  bool get isRunning => _frpProcess != null;

  /// frp 运行状态变化通知，UI 层可监听此值更新按钮状态
  static final ValueNotifier<bool> runningNotifier = ValueNotifier<bool>(false);

  /// 当 frpc 可执行文件缺失时设为 true，UI 层可监听此值弹出下载引导。
  static final ValueNotifier<bool> frpcMissingNotifier = ValueNotifier<bool>(
    false,
  );

  void _notifyRunningState() {
    runningNotifier.value = _frpProcess != null;
  }

  List<String> _candidateFrpcPaths() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final cwd = Directory.current.path;

    // 按平台优先：Windows 优先 .exe，其他平台优先无后缀
    final binName = Platform.isWindows ? 'frpc.exe' : 'frpc';
    final altName = Platform.isWindows ? 'frpc' : 'frpc.exe';

    return <String>[
      '$cwd${Platform.pathSeparator}frp${Platform.pathSeparator}$binName',
      '$cwd${Platform.pathSeparator}frp${Platform.pathSeparator}$altName',
      'frp${Platform.pathSeparator}$binName',
      'frp${Platform.pathSeparator}$altName',
      '..${Platform.pathSeparator}lib${Platform.pathSeparator}frp${Platform.pathSeparator}$binName',
      '..${Platform.pathSeparator}lib${Platform.pathSeparator}frp${Platform.pathSeparator}$altName',
      '$exeDir${Platform.pathSeparator}frp${Platform.pathSeparator}$binName',
      '$exeDir${Platform.pathSeparator}frp${Platform.pathSeparator}$altName',
      '$exeDir${Platform.pathSeparator}data${Platform.pathSeparator}flutter_assets${Platform.pathSeparator}lib${Platform.pathSeparator}frp${Platform.pathSeparator}$binName',
      '$exeDir${Platform.pathSeparator}data${Platform.pathSeparator}flutter_assets${Platform.pathSeparator}lib${Platform.pathSeparator}frp${Platform.pathSeparator}$altName',
    ];
  }

  Future<String?> _resolveFrpcPath() async {
    for (final path in _candidateFrpcPaths()) {
      if (await File(path).exists()) {
        return path;
      }
    }
    return null;
  }

  /// PID 文件路径，用于追踪 frp 进程
  String get _pidFilePath {
    final cwd = Directory.current.path;
    return '$cwd${Platform.pathSeparator}frp${Platform.pathSeparator}frp.pid';
  }

  /// 将当前进程 PID 写入文件
  Future<void> _writePidFile(int pid) async {
    try {
      await File(_pidFilePath).writeAsString('$pid');
    } catch (_) {}
  }

  /// 读取 PID 文件并尝试清理残留进程
  Future<void> _killOrphanProcess() async {
    final pidFile = File(_pidFilePath);
    if (!await pidFile.exists()) return;

    try {
      final content = await pidFile.readAsString();
      final pid = int.tryParse(content.trim());
      if (pid == null) {
        await pidFile.delete();
        return;
      }

      // 检查该 PID 的进程是否仍在运行
      final result = await Process.run(
        Platform.isWindows ? 'tasklist' : 'kill',
        Platform.isWindows
            ? ['/FI', 'PID eq $pid', '/FO', 'CSV', '/NH']
            : ['-0', '$pid'],
      );

      final alive = Platform.isWindows
          ? (result.stdout as String).contains('$pid')
          : result.exitCode == 0;

      if (alive) {
        TerminalUtil.instance.writeLog('发现残留frp进程 (PID: $pid)，正在清理...');
        if (Platform.isWindows) {
          await Process.run('taskkill', ['/F', '/PID', '$pid']);
        } else {
          Process.killPid(pid);
        }
        TerminalUtil.instance.writeLog('已清理残留frp进程 (PID: $pid)');
      }
    } catch (_) {
      // 读取或解析 PID 文件失败，忽略
    }

    // 清理旧的 PID 文件
    try {
      await pidFile.delete();
    } catch (_) {}
  }

  /// 删除 PID 文件
  Future<void> _deletePidFile() async {
    try {
      final file = File(_pidFilePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  List<String> _candidateConfigPaths() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final cwd = Directory.current.path;
    return <String>[
      '$cwd${Platform.pathSeparator}frp${Platform.pathSeparator}frpc.toml',
      'frp${Platform.pathSeparator}frpc.toml',
      '..${Platform.pathSeparator}lib${Platform.pathSeparator}frp${Platform.pathSeparator}frpc.toml',
      '$exeDir${Platform.pathSeparator}frp${Platform.pathSeparator}frpc.toml',
      '$exeDir${Platform.pathSeparator}data${Platform.pathSeparator}flutter_assets${Platform.pathSeparator}lib${Platform.pathSeparator}frp${Platform.pathSeparator}frpc.toml',
    ];
  }

  Future<String?> _resolveConfigPath() async {
    for (final path in _candidateConfigPaths()) {
      if (await File(path).exists()) {
        return path;
      }
    }
    return null;
  }

  //启动frp服务函数
  Future<void> startFrp() async {
    if (_frpProcess != null) {
      TerminalUtil.instance.writeLog('frp进程已在运行中，PID: ${_frpProcess!.pid}');
      return;
    }

    // 启动前先清理可能残留的旧进程（上次异常退出遗留）
    await _killOrphanProcess();

    try {
      final frpcPath = await _resolveFrpcPath();
      final configPath = await _resolveConfigPath();

      if (frpcPath == null) {
        TerminalUtil.instance.writeLog('启动失败：未找到 frpc 可执行文件。');
        TerminalUtil.instance.writeLog('当前工作目录: ${Directory.current.path}');
        TerminalUtil.instance.writeLog('请将 frpc.exe 放到以下任一位置:');
        for (final path in _candidateFrpcPaths()) {
          TerminalUtil.instance.writeLog(' - $path');
        }
        frpcMissingNotifier.value = true;
        return;
      }

      if (configPath == null) {
        TerminalUtil.instance.writeLog('启动失败：未找到 frpc.toml 配置文件。');
        TerminalUtil.instance.writeLog('当前工作目录: ${Directory.current.path}');
        TerminalUtil.instance.writeLog('已尝试路径:');
        for (final path in _candidateConfigPaths()) {
          TerminalUtil.instance.writeLog(' - $path');
        }
        return;
      }

      final configFile = File(configPath);
      final configDir = configFile.parent.path;
      final tunnelsDir = Directory(
        '$configDir${Platform.pathSeparator}tunnels',
      );
      if (!await tunnelsDir.exists()) {
        await tunnelsDir.create(recursive: true);
      }

      // 将相对路径转为绝对路径，避免 Process.start 在 workingDirectory 下二次拼接
      final absoluteFrpcPath = File(frpcPath).absolute.path;
      final absoluteConfigPath = File(configPath).absolute.path;

      // macOS: 去掉 quarantine 标记，否则 sandbox 拒绝执行下载的二进制
      if (Platform.isMacOS) {
        try {
          await Process.run('xattr', [
            '-d',
            'com.apple.quarantine',
            absoluteFrpcPath,
          ]);
        } catch (_) {}
        try {
          await Process.run('chmod', ['+x', absoluteFrpcPath]);
        } catch (_) {}
      }

      _frpProcess = await Process.start(absoluteFrpcPath, [
        '-c',
        absoluteConfigPath,
      ], workingDirectory: configDir);

      // 记录 PID 到文件，用于下次启动时清理残留进程
      await _writePidFile(_frpProcess!.pid);

      _frpProcess!.stdout.transform(utf8.decoder).listen((data) {
        TerminalUtil.instance.writeLog(data);
      });
      _frpProcess!.stderr.transform(utf8.decoder).listen((data) {
        TerminalUtil.instance.writeLog('ERROR: $data');
      });
      _frpProcess!.exitCode.then((code) {
        TerminalUtil.instance.writeLog('frp进程已退出，exitCode: $code');
        _frpProcess = null;
        _deletePidFile();
        _notifyRunningState();
      });
      TerminalUtil.instance.writeLog('成功启动frp进程，PID: ${_frpProcess!.pid}');
      TerminalUtil.instance.writeLog('使用可执行文件: $frpcPath');
      TerminalUtil.instance.writeLog('使用配置文件: $configPath');
      TerminalUtil.instance.writeLog('进程工作目录: $configDir');
      _notifyRunningState();
    } on ProcessException catch (e) {
      TerminalUtil.instance.writeLog('启动失败,错误原因: $e');
      TerminalUtil.instance.writeLog('当前工作目录: ${Directory.current.path}');
    } catch (e) {
      TerminalUtil.instance.writeLog('启动失败,错误原因: $e');
    }
  }

  //停止frp服务函数
  Future<void> stopFrp() async {
    // 优先通过 PID 文件清理（处理跨会话残留）
    await _killOrphanProcess();

    if (_frpProcess != null) {
      try {
        _frpProcess!.kill();
        TerminalUtil.instance.writeLog('已停止frp进程，PID: ${_frpProcess!.pid}');
      } catch (e) {
        TerminalUtil.instance.writeLog('停止失败,错误原因: $e');
      }
      _frpProcess = null;
    } else {
      TerminalUtil.instance.writeLog('frp进程未在运行中');
    }

    // 确保 PID 文件被清理
    await _deletePidFile();
    _notifyRunningState();
  }

  /// 重启 frp 进程（先停止再启动），用于隧道配置变更后使新配置生效。
  Future<void> restartFrp() async {
    TerminalUtil.instance.writeLog('检测到隧道配置变更，正在重启frp进程...');
    await stopFrp();
    // 等待进程完全退出
    await Future.delayed(const Duration(milliseconds: 500));
    await startFrp();
  }
}
