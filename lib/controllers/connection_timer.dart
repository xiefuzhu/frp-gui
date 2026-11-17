import 'dart:async';
import 'package:flutter/foundation.dart';

class ConnectionTimer extends ChangeNotifier {
  ConnectionTimer._();
  static final ConnectionTimer instance = ConnectionTimer._();

  static const Duration _maxDuration = Duration(days: 99 * 365);

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  Duration get elapsed => _stopwatch.elapsed;
  bool get isRunning => _stopwatch.isRunning;

  void start() {
    if (_stopwatch.elapsed >= _maxDuration) return;
    _timer?.cancel();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
      if (_stopwatch.elapsed >= _maxDuration) {
        stop();
      }
    });
    notifyListeners();
  }

  void stop() {
    _stopwatch.stop();
    _timer?.cancel();
    notifyListeners();
  }

  void reset() {
    _stopwatch.reset();
    _timer?.cancel();
    notifyListeners();
  }

  String get formatted {
    final d = _stopwatch.elapsed;
    if (d >= _maxDuration) return '99 年（已满）';
    final days = d.inDays;
    final hours = d.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$days天 $hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
