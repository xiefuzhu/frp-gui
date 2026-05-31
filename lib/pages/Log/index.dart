import 'package:flutter/material.dart';

import '../../utils/TerminalUtil.dart';

/// FRP 日志页面。
///
/// 这里只做“只读日志显示”，不再使用 xterm 的交互式终端，
/// 这样可以避免鼠标点击日志区域时触发输入法/焦点异常。
class LogView extends StatefulWidget {
  const LogView({super.key});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(12),
      child: ValueListenableBuilder<String>(
        valueListenable: TerminalUtil.instance.logs,
        builder: (context, logs, child) {
          // 日志为空时给一个简单提示。
          if (logs.trim().isEmpty) {
            return Center(
              child: Text(
                '暂无日志输出',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontSize: 14,
                ),
              ),
            );
          }

          // 使用可选择文本 + 滚动视图，仅用于展示日志。
          return Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(right: 8),
              child: SelectableText(
                logs,
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
