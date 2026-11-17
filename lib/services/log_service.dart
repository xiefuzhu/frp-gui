import 'package:flutter/foundation.dart';

class LogService {
  LogService._();
  static final LogService instance = LogService._();

  static const int _maxLogLength = 200000;

  final ValueNotifier<String> logs = ValueNotifier<String>('');

  String _sanitize(String message) {
    return message
        .replaceAll(RegExp(r'\x1B\[[0-9;?]*[ -/]*[@-~]'), '')
        .replaceAll('\r', '')
        .replaceAll('\b', '')
        .replaceAll(RegExp(r'[\x00-\x08\x0B-\x1F\x7F]'), '');
  }

  void write(String message) {
    var cleaned = _sanitize(message);
    if (cleaned.isEmpty) return;

    if (!cleaned.endsWith('\n')) {
      cleaned += '\n';
    }

    var next = logs.value + cleaned;
    if (next.length > _maxLogLength) {
      final cutIndex = next.indexOf('\n', next.length - _maxLogLength);
      next = cutIndex >= 0
          ? next.substring(cutIndex + 1)
          : next.substring(next.length - _maxLogLength);
    }
    logs.value = next;
  }

  void clear() {
    logs.value = '';
  }
}
