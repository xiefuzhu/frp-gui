import 'package:flutter/material.dart';
import '../../utils/DownloadManager.dart';
import '../../components/Download/PlatformSelector.dart';
import '../../components/Download/DownloadProgressCard.dart';
import '../../components/Download/VersionInfo.dart';

/// FRP 核心下载页面
///
/// 功能：
/// - 自动检测当前平台并显示已安装版本
/// - 从 GitHub Releases 获取最新 FRP 版本
/// - 多线程分块下载对应平台的二进制包
/// - 自动解压并安装到 frp/ 目录
class DownloadView extends StatefulWidget {
  const DownloadView({super.key});

  @override
  State<DownloadView> createState() => _DownloadViewState();
}

class _DownloadViewState extends State<DownloadView> {
  late PlatformAsset _selectedPlatform;

  @override
  void initState() {
    super.initState();
    _selectedPlatform = DownloadManager.instance.currentPlatformAsset;
    _checkInstalledVersion();
  }

  Future<void> _checkInstalledVersion() async {
    final version = await DownloadManager.instance.detectInstalledVersion();
    if (mounted) {
      DownloadManager.instance.installedVersionNotifier.value = version;
    }
  }

  Future<void> _startDownload() async {
    try {
      await DownloadManager.instance.downloadAndInstall(
        platform: _selectedPlatform,
      );
      _checkInstalledVersion();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Scaffold(
      body: ValueListenableBuilder<DownloadState>(
        valueListenable: DownloadManager.instance.stateNotifier,
        builder: (context, state, _) {
          final isBusy =
              state == DownloadState.fetching ||
              state == DownloadState.downloading ||
              state == DownloadState.extracting;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题
                Text(
                  'FRP 核心管理',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '下载和管理 FRP 核心程序',
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withAlpha(150),
                  ),
                ),
                const SizedBox(height: 20),

                // 已安装版本
                _buildInstalledInfo(colorScheme, textColor),
                const SizedBox(height: 12),

                // 平台选择
                PlatformSelector(
                  selectedPlatform: _selectedPlatform,
                  onChanged: isBusy
                      ? (_) {}
                      : (platform) {
                          setState(() => _selectedPlatform = platform);
                        },
                ),
                const SizedBox(height: 12),

                // 版本信息
                const VersionInfoCard(),
                const SizedBox(height: 12),

                // 下载进度
                const DownloadProgressCard(),
                const SizedBox(height: 16),

                // 操作按钮
                _buildActionButtons(colorScheme, state, isBusy),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstalledInfo(ColorScheme colorScheme, Color textColor) {
    return ValueListenableBuilder<String?>(
      valueListenable: DownloadManager.instance.installedVersionNotifier,
      builder: (context, version, _) {
        final isInstalled = version != null && version.isNotEmpty;

        return Card(
          elevation: 0,
          color: isInstalled
              ? Colors.green.withAlpha(25)
              : Colors.orange.withAlpha(25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  isInstalled ? Icons.check_circle : Icons.warning_amber,
                  color: isInstalled ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isInstalled ? 'FRP 核心已安装' : 'FRP 核心未安装',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isInstalled ? '当前版本: v$version' : '请下载 FRP 核心程序以使用穿透功能',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(
    ColorScheme colorScheme,
    DownloadState state,
    bool isBusy,
  ) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: isBusy
                ? null
                : () async {
                    try {
                      await DownloadManager.instance.fetchLatestRelease();
                    } catch (e) {
                      // 错误在 downloadAndInstall 内部已处理
                    }
                  },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('获取版本'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: isBusy
                ? null
                : (state == DownloadState.completed ? null : _startDownload),
            icon: Icon(isBusy ? Icons.hourglass_top : Icons.download, size: 18),
            label: Text(state == DownloadState.completed ? '已安装' : '下载安装'),
            style: FilledButton.styleFrom(
              backgroundColor: state == DownloadState.completed
                  ? Colors.green
                  : colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
