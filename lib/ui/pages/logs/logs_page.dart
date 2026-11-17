import 'package:flutter/material.dart';

import '../../../services/log_service.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    LogService.instance.logs.addListener(_scrollToBottomIfNearEnd);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToBottomIfNearEnd(),
    );
  }

  void _scrollToBottomIfNearEnd() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (_scrollController.offset >= maxExtent - 120 ||
          _scrollController.offset == 0) {
        _scrollController.animateTo(
          maxExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    LogService.instance.logs.removeListener(_scrollToBottomIfNearEnd);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ValueListenableBuilder<String>(
        valueListenable: LogService.instance.logs,
        builder: (context, logs, _) {
          if (logs.trim().isEmpty) {
            return Center(
              child: Text(
                '暂无日志输出',
                style: TextStyle(
                  color: scheme.onSurface.withAlpha(180),
                  fontSize: 14,
                ),
              ),
            );
          }

          return Stack(
            children: [
              Positioned.fill(
                child: Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(right: 12, bottom: 48),
                    child: SelectableText(
                      logs,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: scheme.primary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 8,
                child: IconButton.filledTonal(
                  tooltip: '清空日志',
                  onPressed: LogService.instance.clear,
                  icon: const Icon(Icons.delete_outline, size: 18),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
