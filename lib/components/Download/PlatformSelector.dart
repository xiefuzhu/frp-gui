import 'package:flutter/material.dart';
import '../../utils/DownloadManager.dart';

/// 平台选择器组件
///
/// 默认自动检测当前平台，也可手动切换其他平台下载对应的 FRP 二进制。
class PlatformSelector extends StatelessWidget {
  final PlatformAsset selectedPlatform;
  final ValueChanged<PlatformAsset> onChanged;

  const PlatformSelector({
    super.key,
    required this.selectedPlatform,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final platforms = DownloadManager.instance.supportedPlatforms;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '选择平台',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: platforms.map((platform) {
                final isSelected =
                    platform.platformName == selectedPlatform.platformName;
                return ChoiceChip(
                  label: Text(
                    platform.platformName,
                    style: TextStyle(fontSize: 12),
                  ),
                  selected: isSelected,
                  onSelected: (_) => onChanged(platform),
                  selectedColor: colorScheme.primaryContainer,
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
