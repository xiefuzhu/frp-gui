import 'package:flutter/foundation.dart';

/// 日志工具类。
///
/// 这里不再使用可交互终端组件，而是改为维护一个只读日志字符串，
/// 避免在 Windows 下点击终端区域时触发输入焦点问题，导致界面卡顿或报错。

class TerminalUtil {
  TerminalUtil.internal();

  static final TerminalUtil instance = TerminalUtil.internal();

  final ValueNotifier<String> logs = ValueNotifier<String>('');

  /// 清理终端输出中的控制字符，避免显示异常。
  String _sanitizeLog(String message) {
    return message
        // 去掉 ANSI 转义序列
        .replaceAll(RegExp(r'\x1B\[[0-9;?]*[ -/]*[@-~]'), '')
        // 去掉回车，避免覆盖同一行内容
        .replaceAll('\r', '')
        // 去掉退格
        .replaceAll('\b', '')
        // 去掉其他不可见控制字符，但保留换行和制表符
        .replaceAll(RegExp(r'[\x00-\x08\x0B-\x1F\x7F]'), '');
  }
  
  //向终端日志中写入message内容
  void writeLog(String message) {
    message = _sanitizeLog(message);

    if (!message.endsWith('\n')) {
      message += '\n';
    }

    logs.value += message;
  }

  void clear(){
    logs.value = '';
  }
}


