import 'dart:async';
import 'package:flutter/material.dart';

/// 全局计时器单例，支持开始、暂停、重置，上限 99 年
class GlobalTimer extends ChangeNotifier {
  GlobalTimer._(); // 私有构造
  static final GlobalTimer _instance = GlobalTimer._();
  static GlobalTimer get instance => _instance;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final Duration _maxDuration = Duration(days: 99 * 365); // 99 年近似

  Duration get elapsed => _stopwatch.elapsed;
  bool get isRunning => _stopwatch.isRunning;

  /// 开始计时，已达上限则忽略
  void start() {
    if (_stopwatch.elapsed >= _maxDuration) return;
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners(); // 每秒刷新
      if (_stopwatch.elapsed >= _maxDuration) {
        stop();
      }
    });
    notifyListeners(); // 立即刷新 UI
  }

  /// 暂停计时
  void stop() {
    _stopwatch.stop();
    _timer?.cancel();
    notifyListeners();
  }

  /// 重置计时
  void reset() {
    _stopwatch.reset();
    _timer?.cancel();
    notifyListeners();
  }

  /// 格式化显示时间
  String get formatted {
    final d = _stopwatch.elapsed;
    if (d >= _maxDuration) return '99 年（已满）';
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${days}天 ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// 显示计时器的组件，自动响应 GlobalTimer 状态变化
class TimerDisplay extends StatelessWidget {
  const TimerDisplay({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GlobalTimer.instance,
      builder: (context, _) {
        return Text(
          GlobalTimer.instance.formatted,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        );
      },
    );
  }
}