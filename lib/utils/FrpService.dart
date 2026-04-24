import 'dart:convert';
import 'dart:io';
import 'TerminalUtil.dart';

class FrpService {
  FrpService._();
  static final FrpService instance = FrpService._();

  Process? _frpProcess;

  List<String> _candidateFrpcPaths() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    return <String>[
      'frp${Platform.pathSeparator}frpc.exe',
      'frp${Platform.pathSeparator}frpc',
      '..${Platform.pathSeparator}lib${Platform.pathSeparator}frp${Platform.pathSeparator}frpc.exe',
      '..${Platform.pathSeparator}lib${Platform.pathSeparator}frp${Platform.pathSeparator}frpc',
      '$exeDir${Platform.pathSeparator}frp${Platform.pathSeparator}frpc.exe',
      '$exeDir${Platform.pathSeparator}frp${Platform.pathSeparator}frpc',
      '$exeDir${Platform.pathSeparator}data${Platform.pathSeparator}flutter_assets${Platform.pathSeparator}lib${Platform.pathSeparator}frp${Platform.pathSeparator}frpc.exe',
      '$exeDir${Platform.pathSeparator}data${Platform.pathSeparator}flutter_assets${Platform.pathSeparator}lib${Platform.pathSeparator}frp${Platform.pathSeparator}frpc',
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

  List<String> _candidateConfigPaths() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    return <String>[
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
      final configName = configPath.replaceAll('\\', '/').split('/').last;
      final tunnelsDir = Directory(
        '$configDir${Platform.pathSeparator}tunnels',
      );
      if (!await tunnelsDir.exists()) {
        await tunnelsDir.create(recursive: true);
      }

      _frpProcess = await Process.start(frpcPath, [
        '-c',
        configName,
      ], workingDirectory: configDir);
      _frpProcess!.stdout.transform(utf8.decoder).listen((data) {
        TerminalUtil.instance.writeLog(data);
      });
      _frpProcess!.stderr.transform(utf8.decoder).listen((data) {
        TerminalUtil.instance.writeLog('ERROR: $data');
      });
      _frpProcess!.exitCode.then((code) {
        TerminalUtil.instance.writeLog('frp进程已退出，exitCode: $code');
        _frpProcess = null;
      });
      TerminalUtil.instance.writeLog('成功启动frp进程，PID: ${_frpProcess!.pid}');
      TerminalUtil.instance.writeLog('使用可执行文件: $frpcPath');
      TerminalUtil.instance.writeLog('使用配置文件: $configPath');
      TerminalUtil.instance.writeLog('进程工作目录: $configDir');
    } on ProcessException catch (e) {
      TerminalUtil.instance.writeLog('启动失败,错误原因: $e');
      TerminalUtil.instance.writeLog('当前工作目录: ${Directory.current.path}');
    } catch (e) {
      TerminalUtil.instance.writeLog('启动失败,错误原因: $e');
    }
  }

  //停止frp服务函数
  Future<void> stopFrp() async {
    if (_frpProcess == null) {
      TerminalUtil.instance.writeLog('frp进程未在运行中');
      return;
    }
    try {
      _frpProcess!.kill();
      TerminalUtil.instance.writeLog('已停止frp进程，PID: ${_frpProcess!.pid}');
      _frpProcess = null;
    } catch (e) {
      TerminalUtil.instance.writeLog('停止失败,错误原因: $e');
    }
  }
}
