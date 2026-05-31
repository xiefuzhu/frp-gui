import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// 下载状态枚举
enum DownloadState {
  idle,
  fetching,
  downloading,
  extracting,
  completed,
  failed,
  cancelled,
}

/// 平台资源描述
class PlatformAsset {
  final String platformName;
  final String assetPattern;
  final String binaryName;
  final String archiveType; // 'zip' | 'tar.gz'

  const PlatformAsset({
    required this.platformName,
    required this.assetPattern,
    required this.binaryName,
    required this.archiveType,
  });
}

/// 下载进度信息
class DownloadProgress {
  final int totalBytes;
  final int downloadedBytes;
  final List<int> chunkBytes;
  final DateTime startTime;

  const DownloadProgress({
    required this.totalBytes,
    required this.downloadedBytes,
    required this.chunkBytes,
    required this.startTime,
  });

  double get percentage =>
      totalBytes > 0 ? (downloadedBytes / totalBytes * 100).clamp(0, 100) : 0;

  String get downloadedSize => _formatBytes(downloadedBytes);
  String get totalSize => _formatBytes(totalBytes);

  String get speed {
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed.inMilliseconds == 0) return '0 B/s';
    final bytesPerSecond = downloadedBytes / elapsed.inMilliseconds * 1000;
    return '${_formatBytes(bytesPerSecond.round())}/s';
  }

  String get remainingTime {
    if (downloadedBytes == 0 || totalBytes == 0) return '计算中...';
    final elapsed = DateTime.now().difference(startTime);
    final speed = downloadedBytes / elapsed.inMilliseconds;
    if (speed == 0) return '计算中...';
    final remainingMs = ((totalBytes - downloadedBytes) / speed).round();
    final remaining = Duration(milliseconds: remainingMs);
    if (remaining.inHours > 0) {
      return '${remaining.inHours}时${remaining.inMinutes.remainder(60)}分';
    }
    if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}分${remaining.inSeconds.remainder(60)}秒';
    }
    return '${remaining.inSeconds}秒';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// FRP 版本信息
class FrpReleaseInfo {
  final String tagName;
  final String publishedAt;
  final String body;
  final List<FrpAsset> assets;

  const FrpReleaseInfo({
    required this.tagName,
    required this.publishedAt,
    required this.body,
    required this.assets,
  });
}

/// FRP 资源文件
class FrpAsset {
  final String name;
  final String downloadUrl;
  final int size;

  const FrpAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });
}

/// 多线程下载管理器（单例）
///
/// 功能：
/// - 从 GitHub Releases 获取最新 FRP 版本信息
/// - 自动检测当前平台并匹配正确的二进制包
/// - 使用 HTTP Range 实现多线程分块并发下载
/// - 下载完成后自动解压并安装 frpc/frps 到 frp/ 目录
/// - 实时进度反馈，支持取消操作
class DownloadManager {
  DownloadManager._();
  static final DownloadManager instance = DownloadManager._();

  static const String _githubApiUrl =
      'https://api.github.com/repos/fatedier/frp/releases/latest';

  /// 分块数量：2 路并发对 ~15MB 文件最佳
  static const int _chunkCount = 2;

  /// 连接握手超时（短）
  static const Duration _connectTimeout = Duration(seconds: 15);

  /// 整体下载超时（长，慢速网络也能完成）
  static const Duration _downloadTimeout = Duration(minutes: 10);

  // 平台资源映射表
  static final List<PlatformAsset> _platformAssets = [
    const PlatformAsset(
      platformName: 'Windows (x64)',
      assetPattern: 'windows_amd64',
      binaryName: 'frpc.exe',
      archiveType: 'zip',
    ),
    const PlatformAsset(
      platformName: 'macOS (Intel)',
      assetPattern: 'darwin_amd64',
      binaryName: 'frpc',
      archiveType: 'tar.gz',
    ),
    const PlatformAsset(
      platformName: 'macOS (Apple Silicon)',
      assetPattern: 'darwin_arm64',
      binaryName: 'frpc',
      archiveType: 'tar.gz',
    ),
    const PlatformAsset(
      platformName: 'Linux (x64)',
      assetPattern: 'linux_amd64',
      binaryName: 'frpc',
      archiveType: 'tar.gz',
    ),
    const PlatformAsset(
      platformName: 'Linux (ARM64)',
      assetPattern: 'linux_arm64',
      binaryName: 'frpc',
      archiveType: 'tar.gz',
    ),
  ];

  // ─── 可观察状态 ───

  final ValueNotifier<DownloadState> stateNotifier = ValueNotifier(
    DownloadState.idle,
  );
  final ValueNotifier<DownloadProgress?> progressNotifier = ValueNotifier(null);
  final ValueNotifier<String> statusMessageNotifier = ValueNotifier('');
  final ValueNotifier<FrpReleaseInfo?> releaseInfoNotifier = ValueNotifier(
    null,
  );
  final ValueNotifier<String?> installedVersionNotifier = ValueNotifier(null);

  // ─── 内部控制 ───

  HttpClient? _httpClient;
  bool _cancelled = false;
  final List<FileSystemEntity> _tempFiles = [];
  final List<HttpClient> _activeClients = [];

  DownloadState get state => stateNotifier.value;
  DownloadProgress? get progress => progressNotifier.value;
  String get statusMessage => statusMessageNotifier.value;

  // ─── 平台检测 ───

  /// 自动检测当前平台对应的资产信息
  PlatformAsset get currentPlatformAsset {
    if (Platform.isWindows) return _platformAssets[0];

    if (Platform.isMacOS) {
      // macOS ARM (Apple Silicon) vs Intel
      try {
        final result = Process.runSync('uname', ['-m']);
        final arch = (result.stdout as String).trim();
        if (arch == 'arm64') return _platformAssets[2];
      } catch (_) {}
      return _platformAssets[1];
    }

    if (Platform.isLinux) {
      try {
        final result = Process.runSync('uname', ['-m']);
        final arch = (result.stdout as String).trim();
        if (arch == 'aarch64') return _platformAssets[4];
      } catch (_) {}
      return _platformAssets[3];
    }

    // Android 默认使用 ARM64 Linux 二进制
    if (Platform.isAndroid) return _platformAssets[4];

    // 未知平台默认 Linux x64
    return _platformAssets[3];
  }

  /// 获取所有支持的平台列表
  List<PlatformAsset> get supportedPlatforms =>
      List.unmodifiable(_platformAssets);

  /// 检测已安装的 FRP 版本
  /// macOS sandbox 下 Process.run 可能被阻止，改为检查文件是否存在 + 大小
  Future<String?> detectInstalledVersion() async {
    try {
      final frpcPath = _resolveFrpcPathForPlatform(currentPlatformAsset);
      if (frpcPath == null) return null;

      final file = File(frpcPath);
      if (!await file.exists()) return null;

      final size = await file.length();
      if (size == 0) return null;

      // 文件存在且非空就算安装成功，版本号从 release 获取
      // 不尝试 Process.run（macOS sandbox 禁止运行未签名二进制）
      return 'installed';
    } catch (_) {
      return null;
    }
  }

  /// 与 FrpService 使用完全一致的候选路径，确保检测和启动查找相同位置
  String? _resolveFrpcPathForPlatform(PlatformAsset asset) {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final cwd = Directory.current.path;
    final candidates = <String>[
      '$cwd${Platform.pathSeparator}frp${Platform.pathSeparator}${asset.binaryName}',
      'frp${Platform.pathSeparator}${asset.binaryName}',
      '..${Platform.pathSeparator}lib${Platform.pathSeparator}frp${Platform.pathSeparator}${asset.binaryName}',
      '$exeDir${Platform.pathSeparator}frp${Platform.pathSeparator}${asset.binaryName}',
      '$exeDir${Platform.pathSeparator}data${Platform.pathSeparator}flutter_assets${Platform.pathSeparator}lib${Platform.pathSeparator}frp${Platform.pathSeparator}${asset.binaryName}',
    ];
    for (final path in candidates) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  // ─── GitHub API ───

  /// 获取最新 FRP 发布信息
  /// 策略：先尝试系统代理，失败则直连，再失败则报错
  Future<FrpReleaseInfo> fetchLatestRelease() async {
    _ensureNotCancelled();
    _setState(DownloadState.fetching, '正在获取版本信息...');

    Object? lastError;

    // 尝试 1：默认（可能走代理）
    try {
      return await _tryFetchApi(null);
    } catch (e) {
      lastError = e;
      if (_cancelled) rethrow;
    }

    // 尝试 2：直连
    _setState(DownloadState.fetching, '代理不通，尝试直连...');
    try {
      return await _tryFetchApi((_) => 'DIRECT');
    } catch (e) {
      lastError = e;
      if (_cancelled) rethrow;
    }

    final msg = lastError is SocketException
        ? '网络连接失败，请检查网络或代理设置'
        : '获取版本失败: $lastError';
    _setState(DownloadState.failed, msg);
    throw Exception(msg);
  }

  Future<FrpReleaseInfo> _tryFetchApi(String Function(Uri)? findProxy) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..userAgent = 'frp-gui/1.0';
    if (findProxy != null) {
      client.findProxy = findProxy;
    }
    _activeClients.add(client);

    try {
      final uri = Uri.parse(_githubApiUrl);
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      _ensureNotCancelled();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final body = await response.transform(utf8.decoder).join();
      _ensureNotCancelled();

      final json = jsonDecode(body) as Map<String, dynamic>;
      final release = _parseReleaseJson(json);
      return release;
    } finally {
      _activeClients.remove(client);
      client.close();
    }
  }

  FrpReleaseInfo _parseReleaseJson(Map<String, dynamic> json) {
    final assets = <FrpAsset>[];
    final assetsList = json['assets'] as List<dynamic>? ?? [];
    for (final a in assetsList) {
      assets.add(
        FrpAsset(
          name: '${a['name'] ?? ''}',
          downloadUrl: '${a['browser_download_url'] ?? ''}',
          size: (a['size'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    final release = FrpReleaseInfo(
      tagName: '${json['tag_name'] ?? ''}',
      publishedAt: '${json['published_at'] ?? ''}',
      body: '${json['body'] ?? ''}',
      assets: assets,
    );

    releaseInfoNotifier.value = release;
    _setState(DownloadState.idle, '版本: ${release.tagName}');
    return release;
  }

  /// 为指定平台查找匹配的资源文件
  FrpAsset? findAssetForPlatform(
    FrpReleaseInfo release,
    PlatformAsset platform,
  ) {
    for (final asset in release.assets) {
      if (asset.name.contains(platform.assetPattern)) {
        return asset;
      }
    }
    return null;
  }

  // ─── 分块下载 ───

  /// 启动下载（完整流程：下载 → 解压 → 安装）
  Future<void> downloadAndInstall({PlatformAsset? platform}) async {
    _cancelled = false;
    _tempFiles.clear();
    final targetPlatform = platform ?? currentPlatformAsset;

    try {
      // 获取 release 信息
      _ensureNotCancelled();
      final release = await fetchLatestRelease();

      // 匹配资源
      _ensureNotCancelled();
      final asset = findAssetForPlatform(release, targetPlatform);
      if (asset == null) {
        throw Exception('未找到匹配 ${targetPlatform.platformName} 的二进制包');
      }

      // 下载
      _ensureNotCancelled();
      final archivePath = await _downloadFile(
        asset.downloadUrl,
        asset.name,
        asset.size,
      );

      // 解压并安装
      _ensureNotCancelled();
      await _extractAndInstall(archivePath, targetPlatform);

      // 清理临时文件
      await _cleanupTempFiles();

      // 检测已安装版本（带追踪）
      final frpDir = Directory('frp');
      String dirInfo = '';
      if (await frpDir.exists()) {
        try {
          final list = await frpDir.list().toList();
          dirInfo = list
              .map((e) {
                final name = e.path.replaceAll('\\', '/').split('/').last;
                final size = e is File ? ' (${e.lengthSync()} bytes)' : '';
                return '$name$size';
              })
              .join(', ');
        } catch (_) {}
      }

      final version = await detectInstalledVersion();
      if (version == null) {
        throw Exception(
          '安装验证失败：未找到 ${targetPlatform.binaryName}\n'
          'CWD: ${Directory.current.path}\n'
          'frp目录内容: ${dirInfo.isEmpty ? "目录为空或不存在" : dirInfo}\n'
          '请确认选择了正确的平台后重试',
        );
      }
      // 用 release 版本号，detectInstalledVersion 只验证文件存在
      installedVersionNotifier.value = release.tagName;

      _setState(DownloadState.completed, '安装完成！版本: ${release.tagName}');
    } on CancelledException {
      _setState(DownloadState.cancelled, '下载已取消');
      await _cleanupTempFiles();
    } catch (e) {
      _setState(DownloadState.failed, '下载失败: $e');
      await _cleanupTempFiles();
      rethrow;
    }
  }

  /// 分块并发下载文件（优化版：复用 HttpClient、批量更新进度）
  Future<String> _downloadFile(
    String url,
    String fileName,
    int totalSize,
  ) async {
    _setState(DownloadState.downloading, '正在下载 $fileName ...');

    final downloadDir = Directory('frp${Platform.pathSeparator}.download');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }

    final archivePath = '${downloadDir.path}${Platform.pathSeparator}$fileName';

    // 直接多线程 Range 下载。若服务器不支持 Range，首分块返回 200 并自动降级。
    final chunkSize = (totalSize / _chunkCount).ceil();

    // 共享进度状态
    final chunkBytes = List<int>.filled(_chunkCount, 0);
    final startTime = DateTime.now();

    // 进度刷新（分块内部已有 100ms 节流，此处直接发布）
    void emitProgress() {
      final totalDownloaded = chunkBytes.fold<int>(0, (sum, b) => sum + b);
      progressNotifier.value = DownloadProgress(
        totalBytes: totalSize,
        downloadedBytes: totalDownloaded,
        chunkBytes: List<int>.from(chunkBytes),
        startTime: startTime,
      );
    }

    emitProgress(); // 初始进度 0%

    // 每个分块独立 HttpClient，避免共享连接池在 CDN 上产生队头阻塞
    final chunkPaths = <String>[];

    try {
      final futures = <Future<void>>[];
      bool rangeSupported = true;

      for (var i = 0; i < _chunkCount; i++) {
        final chunkIndex = i;
        final startByte = chunkIndex * chunkSize;
        final endByte = min(startByte + chunkSize - 1, totalSize - 1);
        final chunkPath = '$archivePath.part$chunkIndex';
        chunkPaths.add(chunkPath);

        futures.add(
          _downloadChunkOptimized(
            url,
            chunkPath,
            startByte,
            endByte,
            chunkIndex,
            chunkBytes,
            emitProgress,
          ).then((resp) {
            if (chunkIndex == 0 && resp == 200) {
              rangeSupported = false;
            }
          }),
        );
      }

      await Future.wait(futures);
      _ensureNotCancelled();

      // 如果不支持 Range，所有分块都下载了完整文件，直接用第一个分块即可
      if (!rangeSupported && chunkPaths.isNotEmpty) {
        _setState(DownloadState.downloading, 'Range 不支持，使用完整下载...');
        final firstChunk = File(chunkPaths[0]);
        if (await firstChunk.exists()) {
          // 删除可能残留的目标文件
          final archiveFile = File(archivePath);
          if (await archiveFile.exists()) await archiveFile.delete();
          await firstChunk.rename(archivePath);

          // 清理剩余分块（它们也是完整文件）
          for (var i = 1; i < chunkPaths.length; i++) {
            final f = File(chunkPaths[i]);
            if (await f.exists()) await f.delete();
          }
          return archivePath;
        }
      }

      // 合并分块文件
      _setState(DownloadState.downloading, '正在合并文件...');
      await _mergeChunksOptimized(chunkPaths, archivePath);
    } finally {
      // 不关闭 sharedClient，_getHttpClient 管理生命周期
    }

    // 将分块文件加入清理列表
    for (final path in chunkPaths) {
      _tempFiles.add(File(path));
    }

    return archivePath;
  }

  /// 分块下载（独立连接 + 流式管道）：每个分块独立 HttpClient，避免 CDN 连接争抢
  Future<int> _downloadChunkOptimized(
    String url,
    String chunkPath,
    int startByte,
    int endByte,
    int chunkIndex,
    List<int> chunkBytes,
    VoidCallback emitProgress,
  ) async {
    final client = HttpClient()
      ..connectionTimeout = _downloadTimeout
      ..userAgent = 'frp-gui/1.0';
    _activeClients.add(client);
    final uri = Uri.parse(url);
    final request = await client.getUrl(uri);
    request.headers.set('Range', 'bytes=$startByte-$endByte');

    final response = await request.close().timeout(_connectTimeout);
    _ensureNotCancelled();

    final statusCode = response.statusCode;

    if (statusCode != 206 && statusCode != 200) {
      throw Exception('HTTP $statusCode: 下载分块失败');
    }

    final file = File(chunkPath);
    final sink = file.openWrite();

    // 进度追踪变量（闭包捕获，在 transformer 内更新）
    var downloaded = 0;
    DateTime lastEmit = DateTime.now();

    // 流式管道：response → progress tracker → file sink
    // addStream 会自动在 sink 满时暂停上游流（背压），避免内存爆炸
    final progressTrackingStream = response.transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (List<int> data, EventSink<List<int>> sink) {
          _ensureNotCancelled();
          downloaded += data.length;
          chunkBytes[chunkIndex] = downloaded;

          // 节流进度通知（最多每 100ms 一次）
          final now = DateTime.now();
          if (now.difference(lastEmit).inMilliseconds >= 100) {
            lastEmit = now;
            emitProgress();
          }

          sink.add(data);
        },
      ),
    );

    try {
      await sink.addStream(progressTrackingStream);
    } finally {
      // 确保最后进度被刷新
      chunkBytes[chunkIndex] = downloaded;
      emitProgress();
      await sink.close();
      _activeClients.remove(client);
      client.close();
    }

    return statusCode;
  }

  /// 合并分块文件（流式写入，避免大文件一次性读入内存）
  Future<void> _mergeChunksOptimized(
    List<String> chunkPaths,
    String outputPath,
  ) async {
    // 单块直接重命名
    if (chunkPaths.length == 1) {
      final src = File(chunkPaths[0]);
      if (await src.exists()) {
        await src.rename(outputPath);
      }
      return;
    }

    final output = File(outputPath);
    final sink = output.openWrite();

    for (final path in chunkPaths) {
      final chunkFile = File(path);
      if (!await chunkFile.exists()) {
        throw Exception('分块文件丢失: $path');
      }
      // 流式读取写入，不一次性加载到内存
      await sink.addStream(chunkFile.openRead());
    }

    await sink.flush();
    await sink.close();
  }

  // ─── 解压安装 ───

  /// 解压归档文件并安装 frpc/frps 到 frp/ 目录
  Future<void> _extractAndInstall(
    String archivePath,
    PlatformAsset platform,
  ) async {
    _setState(DownloadState.extracting, '正在解压并安装...');

    // 确保 frp 目录存在
    final frpDir = Directory('frp');
    if (!await frpDir.exists()) {
      await frpDir.create(recursive: true);
    }

    final archiveFile = File(archivePath);
    if (!await archiveFile.exists()) {
      throw Exception('下载的文件不存在: $archivePath');
    }

    // 根据归档类型使用不同方式解压
    if (platform.archiveType == 'zip') {
      await _extractZip(archivePath, frpDir.path, platform.binaryName);
    } else {
      // tar.gz - 使用系统命令解压（macOS/Linux 自带 tar，Windows 需要额外处理）
      await _extractTarGz(archivePath, frpDir.path, platform.binaryName);
    }
  }

  /// 解压 ZIP 文件
  Future<void> _extractZip(
    String zipPath,
    String outputDir,
    String binaryName,
  ) async {
    try {
      final absZip = File(zipPath).absolute.path;
      final absOutput = Directory(outputDir).absolute.path;

      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-Command',
          'Expand-Archive',
          '-Path',
          absZip,
          '-DestinationPath',
          absOutput,
          '-Force',
        ]);
        if (result.exitCode != 0) {
          throw Exception('PowerShell 解压失败: ${result.stderr}');
        }
      } else {
        final result = await Process.run('unzip', [
          '-o',
          absZip,
          '-d',
          absOutput,
        ]);
        if (result.exitCode != 0) {
          throw Exception('unzip 解压失败: ${result.stderr}');
        }
      }

      await _findAndCopyBinary(absOutput, binaryName);
    } catch (e) {
      throw Exception('ZIP解压失败: $e');
    }
  }

  /// 解压 tar.gz 文件
  Future<void> _extractTarGz(
    String tarGzPath,
    String outputDir,
    String binaryName,
  ) async {
    final absTarGz = File(tarGzPath).absolute.path;
    final absOutput = Directory(outputDir).absolute.path;
    final extractDir = '$absOutput${Platform.pathSeparator}.extract_temp';

    _setState(DownloadState.extracting, '解压中...\n$absTarGz');

    try {
      final tempDir = Directory(extractDir);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      await tempDir.create(recursive: true);

      // 检查下载文件是否存在
      final archiveFile = File(absTarGz);
      if (!await archiveFile.exists()) {
        throw Exception('下载文件丢失: $absTarGz');
      }
      final archiveSize = await archiveFile.length();

      final result = await Process.run('tar', [
        '-xzf',
        absTarGz,
        '-C',
        extractDir,
      ]);
      if (result.exitCode != 0) {
        final result2 = await Process.run('gtar', [
          '-xzf',
          absTarGz,
          '-C',
          extractDir,
        ]);
        if (result2.exitCode != 0) {
          throw Exception(
            'tar 解压失败 (exit=${result.exitCode})\n'
            '文件: $absTarGz ($archiveSize bytes)\n'
            'stderr: ${result.stderr}',
          );
        }
      }

      // 列出解压目录内容供排错
      String extracted = '';
      try {
        final list = await tempDir.list(recursive: false).toList();
        extracted = list.map((e) => e.path.split('/').last).join(', ');
      } catch (_) {}

      // 解压后找到 frpc 二进制并复制到 frp/ 目录
      await _findAndCopyBinary(extractDir, binaryName);

      // 清理临时解压目录
      _tempFiles.add(Directory(extractDir));
    } catch (e) {
      throw Exception('tar.gz解压失败: $e');
    }
  }

  /// 在解压目录中递归查找二进制文件，复制到 frp/ 并验证
  Future<void> _findAndCopyBinary(String searchDir, String binaryName) async {
    // 列出搜索目录顶层内容
    String topLevel = '';
    try {
      final list = await Directory(searchDir).list(recursive: false).toList();
      topLevel = list
          .map((e) => e.path.replaceAll('\\', '/').split('/').last)
          .join(', ');
    } catch (_) {}

    final binary = await _findFile(searchDir, binaryName);
    if (binary == null) {
      throw Exception(
        '未找到 $binaryName\n'
        '搜索目录: ${Directory(searchDir).absolute.path}\n'
        '顶层内容: ${topLevel.isEmpty ? "空" : topLevel}',
      );
    }

    // 使用绝对路径，与 detectInstalledVersion 完全一致
    final frpDir = Directory('frp');
    if (!await frpDir.exists()) {
      await frpDir.create(recursive: true);
    }
    final targetPath =
        '${frpDir.absolute.path}${Platform.pathSeparator}$binaryName';

    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    await File(binary).copy(targetPath);

    // macOS: 去掉 quarantine 标记 + 设可执行权限，否则 sandbox 拒绝执行
    if (Platform.isMacOS) {
      try {
        await Process.run('xattr', ['-d', 'com.apple.quarantine', targetPath]);
      } catch (_) {}
      try {
        await Process.run('chmod', ['+x', targetPath]);
      } catch (_) {}
    }
    if (!Platform.isWindows && !Platform.isMacOS) {
      try {
        await Process.run('chmod', ['+x', targetPath]);
      } catch (_) {}
    }

    if (!await targetFile.exists()) {
      throw Exception('复制后文件不存在: $targetPath');
    }
    final fileSize = await targetFile.length();
    if (fileSize == 0) {
      throw Exception('文件大小为0: $targetPath');
    }

    statusMessageNotifier.value = '已安装: $binaryName (${_formatSize(fileSize)})';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// 递归搜索文件
  Future<String?> _findFile(String dirPath, String fileName) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return null;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final name = entity.path.replaceAll('\\', '/').split('/').last;
        if (name == fileName) {
          return entity.path;
        }
        // 也可能在 macOS .app 包中
        if (fileName == 'frpc' && name == 'frpc') {
          return entity.path;
        }
      }
    }
    return null;
  }

  // ─── 辅助方法 ───

  HttpClient _getHttpClient() {
    _httpClient?.close();
    _httpClient = HttpClient()
      ..connectionTimeout = _downloadTimeout
      ..userAgent = 'frp-gui/1.0';
    _activeClients.add(_httpClient!);
    return _httpClient!;
  }

  void _setState(DownloadState state, String message) {
    stateNotifier.value = state;
    statusMessageNotifier.value = message;
  }

  void _ensureNotCancelled() {
    if (_cancelled) throw CancelledException();
  }

  /// 取消当前下载（强制关闭所有活跃连接）
  void cancel() {
    _cancelled = true;
    for (final c in _activeClients.toList()) {
      try {
        c.close(force: true);
      } catch (_) {}
    }
    _activeClients.clear();
    _httpClient?.close(force: true);
    _httpClient = null;
  }

  /// 清理临时文件
  Future<void> _cleanupTempFiles() async {
    for (final entity in _tempFiles) {
      try {
        if (await entity.exists()) {
          if (entity is Directory) {
            await entity.delete(recursive: true);
          } else {
            await entity.delete();
          }
        }
      } catch (_) {}
    }
    _tempFiles.clear();

    // 清理下载临时目录
    try {
      final downloadDir = Directory('frp${Platform.pathSeparator}.download');
      if (await downloadDir.exists()) {
        final isEmpty = await downloadDir.list().isEmpty;
        if (isEmpty) {
          await downloadDir.delete();
        }
      }
    } catch (_) {}
  }

  /// 清理下载缓存
  Future<void> clearDownloadCache() async {
    try {
      final downloadDir = Directory('frp${Platform.pathSeparator}.download');
      if (await downloadDir.exists()) {
        await downloadDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// 重置状态
  void reset() {
    cancel();
    _cancelled = false;
    _tempFiles.clear();
    stateNotifier.value = DownloadState.idle;
    progressNotifier.value = null;
    statusMessageNotifier.value = '';
  }
}

/// 下载取消异常（内部控制流）
class CancelledException implements Exception {
  @override
  String toString() => '下载已取消';
}
