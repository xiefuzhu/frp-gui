import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../controllers/connection_timer.dart';
import 'config_repository.dart';
import 'frp_paths.dart';
import 'log_service.dart';

class FrpProcessService {
  FrpProcessService._();
  static final FrpProcessService instance = FrpProcessService._();

  Process? _frpProcess;
  bool _isOperating = false;

  final ValueNotifier<bool> isRunning = ValueNotifier<bool>(false);
  String? lastErrorMessage;

  Future<void> _writePidFile(int pid) async {
    try {
      final pidPath = await FrpPaths.resolvePidFilePath();
      await File(pidPath).writeAsString('$pid');
    } catch (_) {}
  }

  Future<void> _deletePidFile() async {
    try {
      final pidPath = await FrpPaths.resolvePidFilePath();
      final file = File(pidPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// 安全清理上次异常退出遗留的孤儿 frpc 进程（校验进程名包含 frpc 防止误杀复用 PID）
  Future<void> _cleanupOrphanFrpc() async {
    try {
      final pidPath = await FrpPaths.resolvePidFilePath();
      final pidFile = File(pidPath);
      if (!await pidFile.exists()) return;

      final content = await pidFile.readAsString();
      final pid = int.tryParse(content.trim());
      if (pid == null) {
        await _deletePidFile();
        return;
      }

      var isFrpcAlive = false;
      if (Platform.isWindows) {
        final result = await Process.run('tasklist', [
          '/FI',
          'PID eq $pid',
          '/FO',
          'CSV',
          '/NH',
        ]);
        final out = '${result.stdout}'.toLowerCase();
        isFrpcAlive = out.contains('$pid') && out.contains('frpc');
      } else {
        final result = await Process.run('ps', ['-p', '$pid', '-o', 'comm=']);
        final out = '${result.stdout}'.toLowerCase();
        isFrpcAlive = result.exitCode == 0 && out.contains('frpc');
      }

      if (isFrpcAlive) {
        LogService.instance.write('发现残留 frpc 进程 (PID: $pid)，正在清理...');
        if (Platform.isWindows) {
          await Process.run('taskkill', ['/F', '/T', '/PID', '$pid']);
        } else {
          Process.killPid(pid, ProcessSignal.sigkill);
        }
        LogService.instance.write('已清理残留 frpc 进程 (PID: $pid)');
      }
    } catch (_) {
      // 忽略孤儿进程探测失败
    } finally {
      await _deletePidFile();
    }
  }

  Future<void> _prepareExecutablePermissions(String executablePath) async {
    if (Platform.isWindows) return;
    if (Platform.isMacOS) {
      try {
        await Process.run('xattr', [
          '-d',
          'com.apple.quarantine',
          executablePath,
        ]);
      } catch (_) {}
    }
    try {
      await Process.run('chmod', ['+x', executablePath]);
    } catch (_) {}
  }

  Future<bool> start({bool resetTimer = true}) async {
    if (_frpProcess != null) {
      LogService.instance.write('frp 进程已在运行中，PID: ${_frpProcess!.pid}');
      isRunning.value = true;
      return true;
    }
    if (_isOperating) {
      return isRunning.value;
    }

    _isOperating = true;
    lastErrorMessage = null;

    try {
      await _cleanupOrphanFrpc();
      await ConfigRepository.instance.ensureLayout();

      final frpcPath = await FrpPaths.resolveExecutablePath();
      final configPath = await FrpPaths.resolveMainConfigPath();

      if (frpcPath == null) {
        lastErrorMessage = '未找到 frpc 内核，请前往【内核】页下载';
        LogService.instance.write('启动失败：未找到 frpc 可执行文件。');
        LogService.instance.write('当前工作目录: ${Directory.current.path}');
        LogService.instance.write('请前往【内核】页面在线下载，或将 frpc 放入以下任一路径:');
        for (final path in await FrpPaths.candidateExecutablePaths()) {
          LogService.instance.write(' - $path');
        }
        return false;
      }

      if (!await File(configPath).exists()) {
        lastErrorMessage = '未找到 frpc.toml 配置文件';
        LogService.instance.write('启动失败：未找到配置文件 ($configPath)。');
        return false;
      }

      final serverCfg = await ConfigRepository.instance.loadServerConfig();
      if (!serverCfg.isConfigured) {
        lastErrorMessage = '请先在【设置】中配置服务器地址';
        LogService.instance.write(
          '启动失败：frpc.toml 中未配置 serverAddr，请前往【设置 -> 服务端】填写。',
        );
        return false;
      }

      final absoluteFrpcPath = File(frpcPath).absolute.path;
      final configFile = File(configPath).absolute;
      final configDir = configFile.parent.path;
      final configName = FrpPaths.fileNameFromPath(configFile.path);

      await _prepareExecutablePermissions(absoluteFrpcPath);

      const utf8SafeDecoder = Utf8Decoder(allowMalformed: true);
      final proc = await Process.start(
        absoluteFrpcPath,
        ['-c', configName],
        workingDirectory: configDir,
      );
      _frpProcess = proc;
      await _writePidFile(proc.pid);

      proc.stdout.transform(utf8SafeDecoder).listen((data) {
        LogService.instance.write(data);
      });
      proc.stderr.transform(utf8SafeDecoder).listen((data) {
        LogService.instance.write('ERROR: $data');
      });

      var exitedImmediately = false;
      int? immediateExitCode;

      proc.exitCode.then((code) {
        exitedImmediately = true;
        immediateExitCode = code;
        LogService.instance.write('frp 进程已退出，exitCode: $code');
        if (identical(_frpProcess, proc)) {
          _frpProcess = null;
          isRunning.value = false;
          ConnectionTimer.instance.reset();
          unawaited(_deletePidFile());
        }
      });

      LogService.instance.write('成功启动 frp 进程，PID: ${proc.pid}');
      LogService.instance.write('使用可执行文件: $absoluteFrpcPath');
      LogService.instance.write('使用配置文件: ${configFile.path}');
      LogService.instance.write('进程工作目录: $configDir');

      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (exitedImmediately || !identical(_frpProcess, proc)) {
        lastErrorMessage =
            'frpc 启动后立即退出 (code: $immediateExitCode)，请查看日志';
        isRunning.value = false;
        ConnectionTimer.instance.reset();
        await _deletePidFile();
        return false;
      }

      isRunning.value = true;
      if (resetTimer) {
        ConnectionTimer.instance.reset();
        ConnectionTimer.instance.start();
      } else if (!ConnectionTimer.instance.isRunning) {
        ConnectionTimer.instance.start();
      }
      return true;
    } on ProcessException catch (e) {
      lastErrorMessage = '进程启动异常: ${e.message}';
      LogService.instance.write('启动失败，错误原因: $e');
      isRunning.value = false;
      return false;
    } catch (e) {
      lastErrorMessage = '启动失败: $e';
      LogService.instance.write('启动失败，错误原因: $e');
      isRunning.value = false;
      return false;
    } finally {
      _isOperating = false;
    }
  }

  Future<void> stop({bool resetTimer = true}) async {
    final proc = _frpProcess;
    if (proc == null) {
      await _cleanupOrphanFrpc();
      isRunning.value = false;
      if (resetTimer) {
        ConnectionTimer.instance.reset();
      }
      LogService.instance.write('frp 进程未在运行中');
      return;
    }

    try {
      _frpProcess = null;
      isRunning.value = false;
      if (resetTimer) {
        ConnectionTimer.instance.reset();
      } else {
        ConnectionTimer.instance.stop();
      }
      final pid = proc.pid;
      proc.kill();
      await proc.exitCode.timeout(
        const Duration(seconds: 3),
        onTimeout: () async {
          if (Platform.isWindows) {
            try {
              await Process.run('taskkill', ['/F', '/T', '/PID', '$pid']);
            } catch (_) {}
          } else {
            proc.kill(ProcessSignal.sigkill);
          }
          return -1;
        },
      );
      LogService.instance.write('已停止 frp 进程，PID: $pid');
    } catch (e) {
      LogService.instance.write('停止失败，错误原因: $e');
    } finally {
      await _deletePidFile();
    }
  }

  Future<bool> restartIfRunning() async {
    if (_frpProcess == null && !isRunning.value) {
      return false;
    }
    LogService.instance.write('检测到配置变更，正在重启 frp 进程以应用新配置...');
    await stop(resetTimer: false);
    return start(resetTimer: false);
  }
}
