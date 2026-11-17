import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/kernel_info.dart';
import 'frp_paths.dart';
import 'frp_process_service.dart';
import 'log_service.dart';

Uint8List? _extractFrpcBytesFromArchive(String archivePath, bool isWindows) {
  final targetBinName = isWindows ? 'frpc.exe' : 'frpc';
  final rawBytes = File(archivePath).readAsBytesSync();

  Archive archive;
  if (archivePath.toLowerCase().endsWith('.zip')) {
    archive = ZipDecoder().decodeBytes(rawBytes);
  } else {
    final tarBytes = GZipDecoder().decodeBytes(rawBytes);
    archive = TarDecoder().decodeBytes(tarBytes);
  }

  for (final entry in archive) {
    if (!entry.isFile) continue;
    final normalizedName = entry.name.replaceAll('\\', '/');
    final baseName = normalizedName.split('/').last.toLowerCase();
    if (baseName == targetBinName) {
      return entry.readBytes();
    }
  }
  return null;
}

Future<void> _downloadAndStageWorker(Map<String, dynamic> args) async {
  final sendPort = args['sendPort'] as SendPort;
  final candidateUrls = (args['candidateUrls'] as List).cast<String>();
  final tempArchivePath = args['tempArchivePath'] as String;
  final stagedBinPath = args['stagedBinPath'] as String;
  final tagName = args['tagName'] as String;
  final isWindows = args['isWindows'] as bool;
  final expectedSizeBytes = args['expectedSizeBytes'] as int;

  final controlPort = ReceivePort();
  sendPort.send({'type': 'control', 'port': controlPort.sendPort});

  final cancelToken = CancelToken();
  controlPort.listen((msg) {
    if (msg == 'cancel' && !cancelToken.isCancelled) {
      cancelToken.cancel('用户取消下载');
    }
  });

  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      followRedirects: true,
      maxRedirects: 5,
      headers: const {
        'Accept': '*/*',
        'User-Agent': 'frp_gui_client',
      },
    ),
  );

  try {
    String? lastErrorMessage;
    var lastUrl = candidateUrls.isNotEmpty ? candidateUrls.first : '';
    var staged = false;
    var hadArchiveStructureMissingBin = false;

    for (final url in candidateUrls) {
      if (cancelToken.isCancelled) {
        sendPort.send({'type': 'cancelled'});
        return;
      }
      lastUrl = url;
      try {
        sendPort.send({'type': 'log', 'msg': '正在下载内核 $tagName: $url'});
        sendPort.send({'type': 'progress', 'value': 0.0});

        final response = await dio.get<ResponseBody>(
          url,
          cancelToken: cancelToken,
          options: Options(responseType: ResponseType.stream),
        );
        final body = response.data;
        if (body == null) {
          throw DioException(
            requestOptions: response.requestOptions,
            message: '下载响应流为空',
          );
        }

        final headerLength = int.tryParse(
          body.headers[Headers.contentLengthHeader]?.first ?? '',
        );
        final totalLength = (headerLength != null && headerLength > 0)
            ? headerLength
            : expectedSizeBytes;

        var received = 0;
        var lastPercent = -1;
        var lastSentMs = 0;
        final progressWatch = Stopwatch()..start();

        final raf = await File(tempArchivePath).open(mode: FileMode.write);
        try {
          await for (final chunk in body.stream.timeout(
            const Duration(seconds: 15),
          )) {
            if (cancelToken.isCancelled) {
              throw DioException.requestCancelled(
                requestOptions: response.requestOptions,
                reason: '用户取消下载',
              );
            }
            await raf.writeFrom(chunk);
            received += chunk.length;

            if (totalLength > 0) {
              final progress = (received / totalLength).clamp(0.0, 1.0);
              final percent = (progress * 100).floor();
              final nowMs = progressWatch.elapsedMilliseconds;
              if (percent != lastPercent &&
                  (nowMs - lastSentMs >= 100 || received >= totalLength)) {
                lastPercent = percent;
                lastSentMs = nowMs;
                sendPort.send({'type': 'progress', 'value': progress});
              }
            }
          }
          await raf.flush();
        } finally {
          await raf.close();
        }

        if (received <= 0 ||
            (headerLength != null &&
                headerLength > 0 &&
                received < headerLength)) {
          throw DioException(
            requestOptions: response.requestOptions,
            type: DioExceptionType.connectionError,
            message: '下载数据不完整 ($received / ${headerLength ?? 0} bytes)',
          );
        }

        sendPort.send({'type': 'progress', 'value': -1.0});
        sendPort.send({'type': 'log', 'msg': '下载完成，正在解压提取 frpc 内核...'});

        final extractedBytes = _extractFrpcBytesFromArchive(
          tempArchivePath,
          isWindows,
        );
        if (extractedBytes == null || extractedBytes.isEmpty) {
          hadArchiveStructureMissingBin = true;
          throw const FormatException('压缩包内未找到 frpc 可执行文件');
        }

        await File(stagedBinPath).writeAsBytes(extractedBytes, flush: true);
        staged = true;
        break;
      } on DioException catch (e) {
        if (CancelToken.isCancel(e) || cancelToken.isCancelled) {
          sendPort.send({'type': 'cancelled'});
          return;
        }
        lastErrorMessage = e.message ?? e.type.name;
        sendPort.send({
          'type': 'log',
          'msg': '下载源不可用，尝试备用地址... ($lastErrorMessage)',
        });
      } on TimeoutException {
        if (cancelToken.isCancelled) {
          sendPort.send({'type': 'cancelled'});
          return;
        }
        lastErrorMessage = '数据传输超时 (15s 无响应)';
        sendPort.send({'type': 'log', 'msg': '下载源断流超时，尝试备用地址...'});
      } catch (e) {
        if (cancelToken.isCancelled) {
          sendPort.send({'type': 'cancelled'});
          return;
        }
        lastErrorMessage = '$e';
        sendPort.send({
          'type': 'log',
          'msg': '当前源下载包校验失败，尝试备用地址... ($e)',
        });
      } finally {
        final tempFile = File(tempArchivePath);
        if (await tempFile.exists()) {
          try {
            await tempFile.delete();
          } catch (_) {}
        }
      }
    }

    if (cancelToken.isCancelled) {
      sendPort.send({'type': 'cancelled'});
      return;
    }

    if (!staged) {
      if (hadArchiveStructureMissingBin) {
        sendPort.send({
          'type': 'extract_error',
          'message': '压缩包内未找到 frpc 可执行文件',
        });
      } else {
        sendPort.send({
          'type': 'network_error',
          'url': lastUrl,
          'message': lastErrorMessage ?? '所有下载源均连接失败',
        });
      }
      return;
    }

    sendPort.send({'type': 'done'});
  } finally {
    controlPort.close();
    dio.close(force: true);
  }
}

class KernelDownloadService {
  KernelDownloadService._();
  static final KernelDownloadService instance = KernelDownloadService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'frp_gui_client',
      },
    ),
  );

  final ValueNotifier<bool> useMirror = ValueNotifier<bool>(true);
  final ValueNotifier<String?> downloadingTag = ValueNotifier<String?>(null);
  final ValueNotifier<double> downloadProgress = ValueNotifier<double>(0.0);

  Isolate? _activeIsolate;
  SendPort? _workerControlPort;
  bool _cancelRequested = false;

  Future<void> _cleanupStaleTempFiles(Directory frpDir) async {
    if (!await frpDir.exists()) return;
    try {
      await for (final entity in frpDir.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = FrpPaths.fileNameFromPath(entity.path);
        if (name.startsWith('.downloading_') || name.startsWith('.staged_frpc')) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  String detectPlatformArch() {
    final String os;
    if (Platform.isWindows) {
      os = 'windows';
    } else if (Platform.isMacOS) {
      os = 'darwin';
    } else {
      os = 'linux';
    }

    final verLower = Platform.version.toLowerCase();
    var arch = 'amd64';
    if (verLower.contains('arm64') || verLower.contains('aarch64')) {
      arch = 'arm64';
    } else if (verLower.contains('arm')) {
      arch = 'arm';
    } else if ((verLower.contains('ia32') || verLower.contains('x86')) &&
        !verLower.contains('x64') &&
        !verLower.contains('x86_64')) {
      arch = '386';
    }

    return '${os}_$arch';
  }

  Future<LocalKernelInfo> detectLocalKernel() async {
    if (downloadingTag.value == null) {
      try {
        final frpDir = await FrpPaths.resolveBaseDir();
        await _cleanupStaleTempFiles(frpDir);
      } catch (_) {}
    }

    final platformArch = detectPlatformArch();
    final exePath = await FrpPaths.resolveExecutablePath();
    if (exePath == null || !await File(exePath).exists()) {
      return LocalKernelInfo(
        installed: false,
        platformArch: platformArch,
      );
    }

    String? version;
    try {
      final result = await Process.run(
        exePath,
        ['-v'],
      ).timeout(const Duration(seconds: 5));
      if (result.exitCode == 0) {
        final out = '${result.stdout}'.trim();
        if (out.isNotEmpty) {
          version = out.startsWith('v') ? out : 'v$out';
        }
      }
    } catch (_) {
      version = null;
    }

    return LocalKernelInfo(
      installed: true,
      version: version,
      executablePath: exePath,
      platformArch: platformArch,
    );
  }

  List<FrpReleaseItem> _buildFallbackReleases() {
    final platformArch = detectPlatformArch();
    final ext = Platform.isWindows ? 'zip' : 'tar.gz';
    const fallbackVersions = [
      ('0.61.2', '2025-03'),
      ('0.61.1', '2024-12'),
      ('0.60.0', '2024-07'),
      ('0.59.0', '2024-06'),
      ('0.58.1', '2024-05'),
    ];

    return fallbackVersions.map((entry) {
      final ver = entry.$1;
      final date = entry.$2;
      final tag = 'v$ver';
      final assetName = 'frp_${ver}_$platformArch.$ext';
      final url =
          'https://github.com/fatedier/frp/releases/download/$tag/$assetName';
      return FrpReleaseItem(
        tagName: tag,
        assetName: assetName,
        downloadUrl: url,
        sizeBytes: 0,
        publishedAt: date,
        isFallback: true,
      );
    }).toList();
  }

  Future<List<FrpReleaseItem>> fetchAvailableReleases() async {
    final platformArch = detectPlatformArch();
    final expectedSuffix = Platform.isWindows
        ? '_$platformArch.zip'
        : '_$platformArch.tar.gz';

    try {
      final response = await _dio.get<List<dynamic>>(
        'https://api.github.com/repos/fatedier/frp/releases',
        queryParameters: const {'per_page': 8},
      );
      final data = response.data;
      if (data == null || data.isEmpty) {
        return _buildFallbackReleases();
      }

      final items = <FrpReleaseItem>[];
      for (final raw in data) {
        if (raw is! Map) continue;
        final tagName = '${raw['tag_name'] ?? ''}'.trim();
        final publishedRaw = '${raw['published_at'] ?? ''}'.trim();
        final publishedAt = publishedRaw.length >= 10
            ? publishedRaw.substring(0, 10)
            : publishedRaw;
        final assets = raw['assets'];
        if (assets is! List) continue;

        for (final asset in assets) {
          if (asset is! Map) continue;
          final name = '${asset['name'] ?? ''}';
          if (name.endsWith(expectedSuffix)) {
            final url = '${asset['browser_download_url'] ?? ''}';
            final size = asset['size'] is int ? asset['size'] as int : 0;
            if (url.isNotEmpty) {
              items.add(
                FrpReleaseItem(
                  tagName: tagName,
                  assetName: name,
                  downloadUrl: url,
                  sizeBytes: size,
                  publishedAt: publishedAt,
                ),
              );
            }
            break;
          }
        }
      }

      return items.isNotEmpty ? items : _buildFallbackReleases();
    } catch (_) {
      return _buildFallbackReleases();
    }
  }

  void cancelDownload() {
    _cancelRequested = true;
    _workerControlPort?.send('cancel');
    final iso = _activeIsolate;
    if (iso != null) {
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (identical(_activeIsolate, iso)) {
          iso.kill(priority: Isolate.immediate);
        }
      });
    }
  }

  List<String> _buildCandidateDownloadUrls(String originalUrl) {
    if (!useMirror.value) {
      return [originalUrl];
    }
    return [
      'https://ghfast.top/$originalUrl',
      'https://gh-proxy.com/$originalUrl',
      originalUrl,
    ];
  }

  Future<void> _replaceTargetExecutable(
    String stagedBinPath,
    String targetPath,
  ) async {
    final stagedFile = File(stagedBinPath);
    Object? lastError;

    for (var attempt = 0; attempt < 6; attempt++) {
      try {
        try {
          await stagedFile.rename(targetPath);
          return;
        } on FileSystemException {
          await stagedFile.copy(targetPath);
          await stagedFile.delete();
          return;
        }
      } catch (e) {
        lastError = e;
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }

    throw lastError ?? Exception('无法覆盖写入目标内核文件: $targetPath');
  }

  Future<String> downloadAndInstall(FrpReleaseItem item) async {
    if (downloadingTag.value != null) {
      throw StateError('已有正在进行的内核下载任务');
    }

    downloadingTag.value = item.tagName;
    downloadProgress.value = 0.0;
    _cancelRequested = false;
    _workerControlPort = null;

    final frpDir = await FrpPaths.resolveBaseDir();
    await _cleanupStaleTempFiles(frpDir);

    final sep = Platform.pathSeparator;
    final isWin = Platform.isWindows;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final tempArchivePath =
        '${frpDir.path}$sep.downloading_${stamp}_${item.assetName}';
    final stagedBinPath = '${frpDir.path}$sep.staged_frpc_$stamp.tmp';

    final receivePort = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    final completer = Completer<void>();

    void completeErrorOnce(Object error, [StackTrace? st]) {
      if (!completer.isCompleted) {
        completer.completeError(error, st);
      }
    }

    receivePort.listen((raw) {
      if (raw is! Map) return;
      final type = raw['type'];
      switch (type) {
        case 'control':
          final port = raw['port'];
          if (port is SendPort) {
            _workerControlPort = port;
            if (_cancelRequested) {
              port.send('cancel');
            }
          }
          break;
        case 'log':
          final msg = raw['msg'];
          if (msg is String && msg.isNotEmpty) {
            LogService.instance.write(msg);
          }
          break;
        case 'progress':
          final val = raw['value'];
          if (val is num) {
            downloadProgress.value = val.toDouble();
          }
          break;
        case 'cancelled':
          completeErrorOnce(
            DioException.requestCancelled(
              requestOptions: RequestOptions(path: item.downloadUrl),
              reason: '用户取消下载',
            ),
          );
          break;
        case 'network_error':
          completeErrorOnce(
            DioException(
              requestOptions: RequestOptions(
                path: '${raw['url'] ?? item.downloadUrl}',
              ),
              type: DioExceptionType.connectionError,
              message: '${raw['message'] ?? '下载失败'}',
            ),
          );
          break;
        case 'extract_error':
          completeErrorOnce(Exception('${raw['message'] ?? '解压失败'}'));
          break;
        case 'done':
          if (!completer.isCompleted) {
            completer.complete();
          }
          break;
      }
    });

    errorPort.listen((errData) {
      if (_cancelRequested) {
        completeErrorOnce(
          DioException.requestCancelled(
            requestOptions: RequestOptions(path: item.downloadUrl),
            reason: '用户取消下载',
          ),
        );
      } else {
        completeErrorOnce(Exception('后台下载线程异常: $errData'));
      }
    });

    exitPort.listen((_) {
      if (!completer.isCompleted) {
        if (_cancelRequested) {
          completeErrorOnce(
            DioException.requestCancelled(
              requestOptions: RequestOptions(path: item.downloadUrl),
              reason: '用户取消下载',
            ),
          );
        } else {
          completeErrorOnce(Exception('后台下载线程意外退出'));
        }
      }
    });

    try {
      final candidateUrls = _buildCandidateDownloadUrls(item.downloadUrl);
      _activeIsolate = await Isolate.spawn<Map<String, dynamic>>(
        _downloadAndStageWorker,
        {
          'sendPort': receivePort.sendPort,
          'candidateUrls': candidateUrls,
          'tempArchivePath': tempArchivePath,
          'stagedBinPath': stagedBinPath,
          'tagName': item.tagName,
          'isWindows': isWin,
          'expectedSizeBytes': item.sizeBytes,
        },
        onError: errorPort.sendPort,
        onExit: exitPort.sendPort,
      );

      await completer.future;

      if (_cancelRequested) {
        throw DioException.requestCancelled(
          requestOptions: RequestOptions(path: item.downloadUrl),
          reason: '用户取消下载',
        );
      }

      final stagedFile = File(stagedBinPath);
      if (!await stagedFile.exists() || await stagedFile.length() == 0) {
        throw Exception('未生成有效的 frpc 内核文件');
      }

      final wasRunning = FrpProcessService.instance.isRunning.value;
      if (wasRunning) {
        LogService.instance.write('正在停止运行中的 frpc 以替换内核...');
        await FrpProcessService.instance.stop(resetTimer: false);
      }

      final targetBinName = isWin ? 'frpc.exe' : 'frpc';
      final targetPath = '${frpDir.path}$sep$targetBinName';
      await _replaceTargetExecutable(stagedBinPath, targetPath);

      if (!isWin) {
        if (Platform.isMacOS) {
          try {
            await Process.run('xattr', ['-d', 'com.apple.quarantine', targetPath]);
          } catch (_) {}
        }
        try {
          await Process.run('chmod', ['+x', targetPath]);
        } catch (_) {}
      }

      LogService.instance.write('内核 ${item.tagName} 安装成功: $targetPath');

      if (wasRunning) {
        await FrpProcessService.instance.start(resetTimer: false);
      }

      return targetPath;
    } finally {
      _activeIsolate?.kill(priority: Isolate.immediate);
      _activeIsolate = null;
      _workerControlPort = null;
      _cancelRequested = false;
      receivePort.close();
      errorPort.close();
      exitPort.close();
      downloadingTag.value = null;
      downloadProgress.value = 0.0;

      for (final path in [tempArchivePath, stagedBinPath]) {
        final file = File(path);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }
    }
  }
}
