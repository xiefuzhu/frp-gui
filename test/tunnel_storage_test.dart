import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frp_gui/models/kernel_info.dart';
import 'package:frp_gui/models/server_config.dart';
import 'package:frp_gui/models/tunnel_config.dart';
import 'package:frp_gui/models/tunnel_protocol.dart';
import 'package:frp_gui/services/config_repository.dart';
import 'package:frp_gui/services/frp_paths.dart';
import 'package:frp_gui/services/kernel_download_service.dart';
import 'package:frp_gui/services/log_service.dart';
import 'package:toml/toml.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('frp_gui_test_');
    FrpPaths.debugBaseDirOverride = tempDir.path;
  });

  tearDown(() async {
    FrpPaths.debugBaseDirOverride = null;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('ensureLayout initializes main config and tunnels folder', () async {
    await ConfigRepository.instance.ensureLayout();

    final mainPath = await FrpPaths.resolveMainConfigPath();
    final tunnelDirPath = await FrpPaths.resolveTunnelDirPath();

    expect(await File(mainPath).exists(), isTrue);
    expect(await Directory(tunnelDirPath).exists(), isTrue);

    final parsed = (await TomlDocument.load(mainPath)).toMap();
    expect(parsed['includes'], contains(FrpPaths.includePattern));
  });

  test('saveServerConfig and loadServerConfig preserve custom sections', () async {
    await ConfigRepository.instance.ensureLayout();
    final mainPath = await FrpPaths.resolveMainConfigPath();

    await File(mainPath).writeAsString('''
serverAddr = "1.2.3.4"
serverPort = 7000
includes = ["./tunnels/*.toml"]

[webServer]
addr = "127.0.0.1"
port = 7400
''');

    await ConfigRepository.instance.saveServerConfig(
      const ServerConfig(
        serverAddr: 'frp.example.org',
        serverPort: 7500,
        token: 'my_secret_token',
      ),
    );

    final loaded = await ConfigRepository.instance.loadServerConfig();
    expect(loaded.serverAddr, 'frp.example.org');
    expect(loaded.serverPort, 7500);
    expect(loaded.token, 'my_secret_token');

    final rawMap = (await TomlDocument.load(mainPath)).toMap();
    expect((rawMap['webServer'] as Map)['port'], 7400);
    expect(rawMap['includes'], contains(FrpPaths.includePattern));

    await ConfigRepository.instance.saveServerConfig(
      const ServerConfig(
        serverAddr: 'frp.example.org',
        serverPort: 7500,
        token: '',
      ),
    );
    final loadedAfterClear = await ConfigRepository.instance.loadServerConfig();
    expect(loadedAfterClear.token, isEmpty);
  });

  test('multi-protocol tunnel CRUD, validation, and suffix toggle', () async {
    expect(
      const TunnelConfig(
        name: '',
        protocol: TunnelProtocol.tcp,
        localIp: '127.0.0.1',
        localPort: 80,
        remotePort: 8080,
      ).validate(),
      isNotNull,
    );
    expect(
      const TunnelConfig(
        name: 'web',
        protocol: TunnelProtocol.http,
        localIp: '127.0.0.1',
        localPort: 8080,
      ).validate(),
      isNotNull,
    );
    expect(
      const TunnelConfig(
        name: 'secret_ssh',
        protocol: TunnelProtocol.stcp,
        localIp: '127.0.0.1',
        localPort: 22,
      ).validate(),
      isNotNull,
    );

    final tcpSaved = await ConfigRepository.instance.saveTunnel(
      const TunnelConfig(
        name: 'mc_server',
        protocol: TunnelProtocol.tcp,
        localIp: '127.0.0.1',
        localPort: 25565,
        remotePort: 25565,
        extraFields: {'hostHeaderRewrite': 'keep.me'},
      ),
    );
    expect(tcpSaved.filePath, isNotNull);
    expect(tcpSaved.filePath!.endsWith('.toml'), isTrue);

    await ConfigRepository.instance.saveTunnel(
      TunnelConfig(
        name: 'blog_http',
        protocol: TunnelProtocol.http,
        localIp: '127.0.0.1',
        localPort: 8080,
        customDomains: TunnelConfig.parseCustomDomains(
          'a.example.com, b.example.com',
        ),
        subdomain: 'blog',
      ),
    );

    await ConfigRepository.instance.saveTunnel(
      const TunnelConfig(
        name: 'private_rdp',
        protocol: TunnelProtocol.stcp,
        localIp: '127.0.0.1',
        localPort: 3389,
        secretKey: 'abcdefg',
      ),
    );

    var all = await ConfigRepository.instance.loadTunnels();
    expect(all.length, 3);

    final httpTunnel = all.firstWhere((e) => e.name == 'blog_http');
    expect(httpTunnel.customDomains, ['a.example.com', 'b.example.com']);
    expect(httpTunnel.subdomain, 'blog');
    expect(httpTunnel.toTomlProxyMap().containsKey('remotePort'), isFalse);

    final stcpTunnel = all.firstWhere((e) => e.name == 'private_rdp');
    expect(stcpTunnel.secretKey, 'abcdefg');

    final disabledTunnel = await ConfigRepository.instance.toggleTunnel(
      tcpSaved,
      false,
    );
    expect(disabledTunnel.filePath!.endsWith('.bak'), isTrue);
    expect(disabledTunnel.enabled, isFalse);

    all = await ConfigRepository.instance.loadTunnels();
    final mcTunnel = all.firstWhere((e) => e.name == 'mc_server');
    expect(mcTunnel.enabled, isFalse);
    expect(mcTunnel.extraFields['hostHeaderRewrite'], 'keep.me');

    await ConfigRepository.instance.deleteTunnel(disabledTunnel.filePath!);
    all = await ConfigRepository.instance.loadTunnels();
    expect(all.length, 2);
  });

  test('LogService strips ANSI escape codes cleanly', () {
    LogService.instance.clear();
    LogService.instance.write('\x1B[32m2026/11/17 [I] login to server success\x1B[0m\r');
    expect(
      LogService.instance.logs.value,
      '2026/11/17 [I] login to server success\n',
    );
    LogService.instance.clear();
  });

  test('detectLocalKernel detects local frpc binary if present', () async {
    FrpPaths.debugBaseDirOverride = null;
    final info = await KernelDownloadService.instance.detectLocalKernel();
    expect(info.platformArch, isNotEmpty);
    if (info.installed) {
      expect(info.executablePath, isNotNull);
    }
  });

  test('downloadAndInstall streams and extracts in isolate and supports cancel', () async {
    final binName = Platform.isWindows ? 'frpc.exe' : 'frpc';
    final fakePayload = Uint8List.fromList(
      'FAKE_FRPC_BINARY_CONTENT_072'.codeUnits,
    );

    final archive = Archive()
      ..addFile(
        ArchiveFile('frp_0.72.0_test/$binName', fakePayload.length, fakePayload),
      );
    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    server.listen((req) async {
      if (req.uri.path == '/ok.zip') {
        req.response.headers.contentLength = zipBytes.length;
        final mid = zipBytes.length ~/ 2;
        req.response.add(zipBytes.sublist(0, mid));
        await req.response.flush();
        await Future<void>.delayed(const Duration(milliseconds: 30));
        req.response.add(zipBytes.sublist(mid));
        await req.response.close();
      } else if (req.uri.path == '/stall.zip') {
        req.response.headers.contentLength = 1024 * 1024;
        req.response.add(Uint8List(1024));
        await req.response.flush();
      } else {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
      }
    });

    final prevMirror = KernelDownloadService.instance.useMirror.value;
    KernelDownloadService.instance.useMirror.value = false;
    addTearDown(() {
      KernelDownloadService.instance.useMirror.value = prevMirror;
    });

    final staleFile = File(
      '${tempDir.path}${Platform.pathSeparator}.downloading_stale.zip',
    );
    await staleFile.writeAsString('stale');

    final installedPath = await KernelDownloadService.instance
        .downloadAndInstall(
          FrpReleaseItem(
            tagName: 'v0.72.0',
            assetName: 'frp_0.72.0_test.zip',
            downloadUrl: 'http://127.0.0.1:${server.port}/ok.zip',
            sizeBytes: zipBytes.length,
            publishedAt: '2026-11-17',
          ),
        );

    expect(await staleFile.exists(), isFalse);
    expect(await File(installedPath).readAsBytes(), equals(fakePayload));
    expect(KernelDownloadService.instance.downloadingTag.value, isNull);

    final cancelFuture = KernelDownloadService.instance.downloadAndInstall(
      FrpReleaseItem(
        tagName: 'v0.72.0',
        assetName: 'frp_0.72.0_stall.zip',
        downloadUrl: 'http://127.0.0.1:${server.port}/stall.zip',
        sizeBytes: 1024 * 1024,
        publishedAt: '2026-11-17',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 150));
    KernelDownloadService.instance.cancelDownload();

    await expectLater(
      cancelFuture,
      throwsA(
        isA<DioException>().having(CancelToken.isCancel, 'isCancel', isTrue),
      ),
    );
    expect(KernelDownloadService.instance.downloadingTag.value, isNull);
  });
}
