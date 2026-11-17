import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../models/kernel_info.dart';
import '../../../services/kernel_download_service.dart';
import '../../utils/app_toast.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  LocalKernelInfo? _localInfo;
  List<FrpReleaseItem> _releases = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      KernelDownloadService.instance.detectLocalKernel(),
      KernelDownloadService.instance.fetchAvailableReleases(),
    ]);
    if (!mounted) return;
    setState(() {
      _localInfo = results[0] as LocalKernelInfo;
      _releases = results[1] as List<FrpReleaseItem>;
      _loading = false;
    });
  }

  Future<void> _handleDownload(FrpReleaseItem item) async {
    try {
      await KernelDownloadService.instance.downloadAndInstall(item);
      final updatedLocal =
          await KernelDownloadService.instance.detectLocalKernel();
      if (!mounted) return;
      setState(() => _localInfo = updatedLocal);
      AppToast.show(context, '内核 ${item.tagName} 安装成功');
    } on DioException catch (e) {
      if (!mounted) return;
      if (CancelToken.isCancel(e)) {
        AppToast.show(context, '已取消下载');
      } else {
        AppToast.show(context, '下载失败，请检查网络');
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, '安装失败: $e');
    }
  }

  Widget _buildLocalStatusCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = _localInfo;
    final installed = info?.installed == true;
    final versionText = installed
        ? (info?.version ?? '已安装 (版本未知)')
        : '未安装 frpc 内核';
    final subText = installed
        ? (info?.executablePath ?? '')
        : '请从下方版本列表中选择并下载对应内核 (${info?.platformArch ?? ''})';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 480;
        final mirrorChip = ValueListenableBuilder<bool>(
          valueListenable: KernelDownloadService.instance.useMirror,
          builder: (context, mirrorEnabled, _) {
            return ChoiceChip(
              side: BorderSide.none,
              selected: mirrorEnabled,
              label: const Text('镜像加速'),
              onSelected: (val) {
                KernelDownloadService.instance.useMirror.value = val;
              },
            );
          },
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.grey.withAlpha(40),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    installed
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    size: 38,
                    color: installed ? scheme.surfaceTint : Colors.orange,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '当前内核: $versionText',
                          style: TextStyle(
                            color: scheme.surfaceTint.withAlpha(210),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.surfaceTint.withAlpha(150),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 8),
                    mirrorChip,
                  ],
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: '刷新状态与版本列表',
                    onPressed: _loading ? null : _refreshData,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              if (compact) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: mirrorChip,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildReleaseTile(
    BuildContext context,
    FrpReleaseItem item,
    String? activeTag,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final isDownloadingThis = activeTag == item.tagName;
    final isBusyOther = activeTag != null && !isDownloadingThis;
    final isCurrentInstalled =
        _localInfo?.installed == true && _localInfo?.version == item.tagName;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.tagName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isCurrentInstalled) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '当前使用',
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.assetName} · ${item.formattedSize} · ${item.publishedAt}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isDownloadingThis)
                OutlinedButton.icon(
                  onPressed: KernelDownloadService.instance.cancelDownload,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('取消'),
                )
              else
                FilledButton.tonalIcon(
                  onPressed: isBusyOther ? null : () => _handleDownload(item),
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(isCurrentInstalled ? '重新安装' : '下载安装'),
                ),
            ],
          ),
          if (isDownloadingThis) ...[
            const SizedBox(height: 12),
            ValueListenableBuilder<double>(
              valueListenable: KernelDownloadService.instance.downloadProgress,
              builder: (context, progress, _) {
                final isExtracting = progress < 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: isExtracting ? null : progress.clamp(0.0, 1.0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isExtracting
                          ? '正在解压并替换 frpc 内核...'
                          : '下载进度: ${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 10, 15, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocalStatusCard(context),
            const SizedBox(height: 14),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ValueListenableBuilder<String?>(
                      valueListenable:
                          KernelDownloadService.instance.downloadingTag,
                      builder: (context, activeTag, _) {
                        if (_releases.isEmpty) {
                          return const Center(child: Text('暂无可用内核版本'));
                        }
                        return ListView.builder(
                          itemCount: _releases.length,
                          itemBuilder: (context, index) {
                            return _buildReleaseTile(
                              context,
                              _releases[index],
                              activeTag,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
