import 'package:flutter/material.dart';

import '../../../controllers/connection_timer.dart';
import '../../../services/frp_process_service.dart';
import '../../../services/log_service.dart';
import '../../utils/app_toast.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final mediaHeight = MediaQuery.of(context).size.height;
    final buttonSize = (mediaHeight * 0.45).clamp(120.0, 200.0);
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: FrpProcessService.instance.isRunning,
      builder: (context, isRunning, _) {
        final iconColor =
            isRunning ? Colors.red : scheme.primaryContainer;

        return SizedBox.expand(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: buttonSize,
                            width: buttonSize,
                            child: FloatingActionButton(
                              heroTag: 'frp_connect_fab',
                              shape: const CircleBorder(),
                              backgroundColor: Colors.white,
                              onPressed: () async {
                                if (!FrpProcessService.instance.isRunning.value) {
                                  LogService.instance.clear();
                                  LogService.instance.write('正在启动 frp 进程...');
                                  final started =
                                      await FrpProcessService.instance.start();
                                  if (!started && context.mounted) {
                                    AppToast.show(
                                      context,
                                      FrpProcessService
                                              .instance.lastErrorMessage ??
                                          '启动失败，请查看日志',
                                    );
                                  }
                                } else {
                                  await FrpProcessService.instance.stop();
                                }
                              },
                              child: TweenAnimationBuilder<Color?>(
                                tween: ColorTween(end: iconColor),
                                duration: const Duration(milliseconds: 150),
                                builder: (context, color, _) {
                                  return Icon(
                                    Icons.power_settings_new,
                                    size: buttonSize * 0.72,
                                    color: color,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SizeTransition(
                                  sizeFactor: animation,
                                  axis: Axis.vertical,
                                  child: child,
                                ),
                              );
                            },
                            child: isRunning
                                ? const Center(
                                    key: ValueKey('timer'),
                                    child: ConnectionTimerText(),
                                  )
                                : const SizedBox(key: ValueKey('empty_timer')),
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.12),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              isRunning ? '已连接' : '点击连接',
                              key: ValueKey<bool>(isRunning),
                              style: TextStyle(
                                fontSize: 20,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ConnectionTimerText extends StatelessWidget {
  const ConnectionTimerText({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ConnectionTimer.instance,
      builder: (context, _) {
        return Text(
          ConnectionTimer.instance.formatted,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        );
      },
    );
  }
}
