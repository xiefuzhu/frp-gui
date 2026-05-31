import 'package:flutter/material.dart';
import '../../utils/DownloadManager.dart';

/// 版本信息卡片
///
/// 展示最新 FRP 版本号、发布日期和更新内容摘要。
class VersionInfoCard extends StatelessWidget {
  const VersionInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return ValueListenableBuilder<FrpReleaseInfo?>(
      valueListenable: DownloadManager.instance.releaseInfoNotifier,
      builder: (context, release, _) {
        if (release == null) {
          return Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('点击"获取版本"查看最新 FRP 版本')),
            ),
          );
        }

        // 提取 release notes 摘要（前200字符）
        final notes = release.body.length > 300
            ? '${release.body.substring(0, 300)}...'
            : release.body;

        return Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 版本号
                Row(
                  children: [
                    Icon(
                      Icons.new_releases,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      release.tagName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 发布日期
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: textColor.withAlpha(150),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '发布于: ${release.publishedAt}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withAlpha(150),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Release notes
                Text(
                  '更新内容',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  notes,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withAlpha(180),
                    height: 1.5,
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
