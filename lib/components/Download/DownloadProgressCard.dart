import 'package:flutter/material.dart';
import '../../utils/DownloadManager.dart';

/// 下载进度卡片
///
/// 显示圆形进度指示器、下载状态、百分比、速度、剩余时间。
class DownloadProgressCard extends StatelessWidget {
  const DownloadProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return ValueListenableBuilder<DownloadState>(
      valueListenable: DownloadManager.instance.stateNotifier,
      builder: (context, state, _) {
        if (state == DownloadState.idle) return const SizedBox.shrink();

        return Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 状态图标/进度环
                _buildProgressIndicator(state, colorScheme),

                const SizedBox(height: 16),

                // 状态文本
                ValueListenableBuilder<String>(
                  valueListenable:
                      DownloadManager.instance.statusMessageNotifier,
                  builder: (context, msg, _) {
                    return Text(
                      msg,
                      style: TextStyle(fontSize: 14, color: textColor),
                      textAlign: TextAlign.center,
                    );
                  },
                ),

                // 进度详情（仅下载中显示）
                if (state == DownloadState.downloading) ...[
                  const SizedBox(height: 12),
                  _buildProgressDetails(colorScheme, textColor),
                ],

                // 取消按钮（下载中显示）
                if (state == DownloadState.downloading ||
                    state == DownloadState.fetching) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => DownloadManager.instance.cancel(),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('取消'),
                  ),
                ],

                // 完成状态
                if (state == DownloadState.completed) ...[
                  const SizedBox(height: 8),
                  Icon(Icons.check_circle, color: Colors.green, size: 32),
                ],

                // 失败状态
                if (state == DownloadState.failed) ...[
                  const SizedBox(height: 8),
                  Icon(Icons.error, color: Colors.red, size: 32),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(DownloadState state, ColorScheme colorScheme) {
    switch (state) {
      case DownloadState.fetching:
        return SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            color: colorScheme.primary,
          ),
        );
      case DownloadState.downloading:
        return ValueListenableBuilder<DownloadProgress?>(
          valueListenable: DownloadManager.instance.progressNotifier,
          builder: (context, progress, _) {
            final pct = progress?.percentage ?? 0;
            // 环 + 文字水平排列，互不重叠
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: pct / 100,
                    strokeWidth: 5,
                    backgroundColor: colorScheme.primary.withAlpha(25),
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${progress.downloadedSize} / ${progress.totalSize}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                      Text(
                        progress.speed,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withAlpha(120),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        );
      case DownloadState.extracting:
        return SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            color: colorScheme.secondary,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProgressDetails(ColorScheme colorScheme, Color textColor) {
    return ValueListenableBuilder<DownloadProgress?>(
      valueListenable: DownloadManager.instance.progressNotifier,
      builder: (context, progress, _) {
        if (progress == null) return const SizedBox.shrink();

        return Column(
          children: [
            // 大小
            Text(
              '${progress.downloadedSize} / ${progress.totalSize}',
              style: TextStyle(fontSize: 12, color: textColor.withAlpha(180)),
            ),
            const SizedBox(height: 4),
            // 速度 + 剩余时间
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.speed, size: 14, color: textColor.withAlpha(150)),
                const SizedBox(width: 4),
                Text(
                  progress.speed,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withAlpha(180),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.timer, size: 14, color: textColor.withAlpha(150)),
                const SizedBox(width: 4),
                Text(
                  progress.remainingTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withAlpha(180),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
