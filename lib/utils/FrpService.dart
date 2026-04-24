import 'dart:convert';
import 'dart:io';
import 'TerminalUtil.dart';

class FrpService {
  FrpService._();
  static final FrpService instance = FrpService._();

  Process? _frpProcess;
  //启动frp服务函数
  Future<void> startFrp(String configPath) async {
    if (_frpProcess != null) {
      print("frp进程已在运行中，PID: ${_frpProcess!.pid}");
      return;
    }
    try {
      _frpProcess = await Process.start('./frp/frpc.exe', [
        '-c',
        configPath,
      ]);
      _frpProcess!.stdout.transform(utf8.decoder).listen((data) {
        TerminalUtil.instance.writeLog(data);
      });
      _frpProcess!.stderr.transform(utf8.decoder).listen((data) {
        TerminalUtil.instance.writeLog("ERROR: $data");
      });
      TerminalUtil.instance.writeLog("成功启动frp进程，PID: ${_frpProcess!.pid}");
    } catch (e) {
      print("启动失败,错误原因: $e");
    }
  }

  //停止frp服务函数
  Future<void> stopFrp() async {
    if (_frpProcess == null) {
      TerminalUtil.instance.writeLog("frp进程未在运行中");
      return;
    }
    try {
      _frpProcess!.kill();
      TerminalUtil.instance.writeLog("已停止frp进程，PID: ${_frpProcess!.pid}");
      _frpProcess = null;
    } catch (e) {
      TerminalUtil.instance.writeLog("停止失败,错误原因: $e");
    }
  }
}
