import 'package:flutter/material.dart';
import 'package:frp_flutter/components/Home/Time.dart';
import 'package:frp_flutter/utils/FrpService.dart';
import 'package:frp_flutter/utils/TerminalUtil.dart';

// 首页连接按钮
int _state = 0; // 0 未连接，1 已连接

class connectButton extends StatefulWidget {
  const connectButton({super.key});

  @override
  State<connectButton> createState() => _connectButtonState();
}

class _connectButtonState extends State<connectButton>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    //按钮大小
    final double buttonSize = MediaQuery.of(context).size.height * 0.5 > 200
        ? 200
        : MediaQuery.of(context).size.height * 0.5;
    //按钮图标颜色（与启动状态绑定）
    final Color power = _state == 1
        ? Colors.red
        : Theme.of(context).colorScheme.primaryContainer;
    //文字颜色（根据当前主题模式自动调整）
    final Color textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                //AnimatedSize用于增加过度动画
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut, //动画曲线

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //启动按钮
                      SizedBox(
                        height: buttonSize,
                        width: buttonSize,
                        child: FloatingActionButton(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(1000),
                          ),
                          backgroundColor: Colors.white,
                          onPressed: () async {
                            if (_state == 0) {
                              GlobalTimer.instance.stop();
                              GlobalTimer.instance.start();
                              TerminalUtil.instance.clear();
                              TerminalUtil.instance.writeLog("正在启动frp进程...");
                              await FrpService.instance.startFrp();
                              _state = 1;
                            } else {
                              GlobalTimer.instance.reset();
                              await FrpService.instance.stopFrp();
                              _state = 0;
                            }
                            setState(() {});
                          },
                          child: TweenAnimationBuilder<Color?>(
                            tween: ColorTween(end: power),
                            duration: const Duration(milliseconds: 100),
                            builder: (context, color, child) {
                              return Icon(
                                Icons.power_settings_new,
                                size: buttonSize * 0.75,
                                color: color,
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20), //分隔用

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 100),
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
                        child: _state == 0
                            ? const SizedBox(key: ValueKey('empty_timer'))
                            : Center(
                                child: TimerDisplay(key: ValueKey('timer')),
                              ),
                      ),

                      const SizedBox(height: 20), //分隔用
                      //连接状态文字（含切换动画）
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.1),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          _state == 0 ? "点击连接" : "已连接",
                          key: ValueKey(_state),
                          style: TextStyle(fontSize: 20, color: textColor),
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
  }
}
