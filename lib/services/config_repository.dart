import 'dart:io';
import 'package:toml/toml.dart';

import '../models/server_config.dart';
import '../models/tunnel_config.dart';
import 'frp_paths.dart';

class ConfigRepository {
  ConfigRepository._();
  static final ConfigRepository instance = ConfigRepository._();

  Future<void> ensureLayout() async {
    final tunnelDirPath = await FrpPaths.resolveTunnelDirPath();
    final mainConfigPath = await FrpPaths.resolveMainConfigPath();

    final tunnelDir = Directory(tunnelDirPath);
    if (!await tunnelDir.exists()) {
      await tunnelDir.create(recursive: true);
    }

    final mainConfigFile = File(mainConfigPath);
    if (!await mainConfigFile.exists()) {
      final defaultDoc = TomlDocument.fromMap({
        'serverAddr': '127.0.0.1',
        'serverPort': 7000,
        'includes': [FrpPaths.includePattern],
      }).toString();
      await mainConfigFile.writeAsString(defaultDoc, mode: FileMode.write);
      return;
    }

    try {
      final document = await TomlDocument.load(mainConfigPath);
      final config = Map<String, dynamic>.from(document.toMap());
      final includesRaw = config['includes'];
      final includes = <String>[];

      if (includesRaw is List) {
        includes.addAll(includesRaw.map((item) => item.toString()));
      }

      if (!includes.contains(FrpPaths.includePattern)) {
        includes.add(FrpPaths.includePattern);
        config['includes'] = includes;
        await mainConfigFile.writeAsString(
          TomlDocument.fromMap(config).toString(),
          mode: FileMode.write,
        );
      }
    } catch (_) {
      final rawContent = await mainConfigFile.readAsString();
      if (rawContent.trim().isEmpty) {
        final defaultDoc = TomlDocument.fromMap({
          'serverAddr': '127.0.0.1',
          'serverPort': 7000,
          'includes': [FrpPaths.includePattern],
        }).toString();
        await mainConfigFile.writeAsString(defaultDoc, mode: FileMode.write);
      }
    }
  }

  Future<ServerConfig> loadServerConfig() async {
    await ensureLayout();
    final mainConfigPath = await FrpPaths.resolveMainConfigPath();
    try {
      final document = await TomlDocument.load(mainConfigPath);
      final config = document.toMap();
      final serverAddr = '${config['serverAddr'] ?? ''}'.trim();
      final rawPort = config['serverPort'];
      final serverPort = rawPort is int
          ? rawPort
          : (int.tryParse('$rawPort') ?? 7000);

      var token = '';
      final authRaw = config['auth'];
      if (authRaw is Map && authRaw['token'] != null) {
        token = '${authRaw['token']}';
      } else if (config['token'] != null) {
        token = '${config['token']}';
      }

      return ServerConfig(
        serverAddr: serverAddr,
        serverPort: serverPort,
        token: token,
      );
    } catch (_) {
      return const ServerConfig();
    }
  }

  Future<void> saveServerConfig(ServerConfig serverConfig) async {
    await ensureLayout();
    final mainConfigPath = await FrpPaths.resolveMainConfigPath();
    final mainConfigFile = File(mainConfigPath);

    var config = <String, dynamic>{};
    try {
      final document = await TomlDocument.load(mainConfigPath);
      config = Map<String, dynamic>.from(document.toMap());
    } catch (_) {
      config = <String, dynamic>{};
    }

    config['serverAddr'] = serverConfig.serverAddr.trim();
    config['serverPort'] = serverConfig.serverPort;

    final includes = <String>[];
    final includesRaw = config['includes'];
    if (includesRaw is List) {
      includes.addAll(includesRaw.map((item) => item.toString()));
    }
    if (!includes.contains(FrpPaths.includePattern)) {
      includes.add(FrpPaths.includePattern);
    }
    config['includes'] = includes;

    final trimmedToken = serverConfig.token.trim();
    final existingAuth = config['auth'];
    final authMap = existingAuth is Map
        ? Map<String, dynamic>.from(existingAuth)
        : <String, dynamic>{};

    if (trimmedToken.isNotEmpty) {
      authMap['token'] = trimmedToken;
      config['auth'] = authMap;
    } else {
      authMap.remove('token');
      config.remove('token');
      if (authMap.isEmpty) {
        config.remove('auth');
      } else {
        config['auth'] = authMap;
      }
    }

    await mainConfigFile.writeAsString(
      TomlDocument.fromMap(config).toString(),
      mode: FileMode.write,
    );
  }

  Future<List<TunnelConfig>> loadTunnels() async {
    await ensureLayout();
    final tunnelDirPath = await FrpPaths.resolveTunnelDirPath();
    final tunnelDir = Directory(tunnelDirPath);
    final entries = <TunnelConfig>[];

    await for (final entity in tunnelDir.list(followLinks: false)) {
      if (entity is! File) continue;

      final path = entity.path;
      final fileName = FrpPaths.fileNameFromPath(path);
      final lower = fileName.toLowerCase();

      final isEnabled = lower.endsWith('.toml');
      final isDisabled = lower.endsWith('.bak') || lower.endsWith('.disabled');
      if (!isEnabled && !isDisabled) continue;

      try {
        final parsed = (await TomlDocument.load(path)).toMap();
        entries.add(
          TunnelConfig.fromTomlDocument(
            parsed,
            filePath: path,
            fileName: fileName,
            enabled: isEnabled,
          ),
        );
      } catch (_) {
        // 忽略单个损坏的配置文件，避免影响其余隧道加载
      }
    }

    entries.sort((a, b) => a.name.compareTo(b.name));
    return entries;
  }

  Future<TunnelConfig> saveTunnel(TunnelConfig tunnel) async {
    await ensureLayout();
    final tunnelDirPath = await FrpPaths.resolveTunnelDirPath();
    final dir = Directory(tunnelDirPath);
    final targetExt = tunnel.enabled ? '.toml' : '.bak';
    final sourcePath = tunnel.filePath?.trim();

    String targetPath;
    if (sourcePath != null && sourcePath.isNotEmpty) {
      final stem = FrpPaths.fileStem(sourcePath);
      targetPath = '${dir.path}${Platform.pathSeparator}$stem$targetExt';
    } else {
      final baseStem = FrpPaths.sanitizeFileStem(tunnel.name);
      targetPath = '${dir.path}${Platform.pathSeparator}$baseStem$targetExt';
      var counter = 1;
      while (await File(targetPath).exists()) {
        targetPath =
            '${dir.path}${Platform.pathSeparator}${baseStem}_$counter$targetExt';
        counter++;
      }
    }

    if (sourcePath != null && sourcePath.isNotEmpty && sourcePath != targetPath) {
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.delete();
      }
    }

    final tomlText = TomlDocument.fromMap(
      tunnel.toTomlDocumentMap(),
    ).toString();
    await File(targetPath).writeAsString(tomlText, mode: FileMode.write);

    return tunnel.copyWith(
      filePath: targetPath,
      fileName: FrpPaths.fileNameFromPath(targetPath),
    );
  }

  Future<TunnelConfig> toggleTunnel(TunnelConfig tunnel, bool enabled) async {
    final path = tunnel.filePath;
    if (path == null || path.trim().isEmpty) {
      throw FileSystemException('隧道配置文件路径为空');
    }

    final currentFile = File(path);
    if (!await currentFile.exists()) {
      throw FileSystemException('隧道配置文件不存在', path);
    }

    final stem = FrpPaths.fileStem(path);
    final dir = currentFile.parent.path;
    final targetPath =
        '$dir${Platform.pathSeparator}$stem${enabled ? '.toml' : '.bak'}';

    final resolvedPath = targetPath == path
        ? path
        : (await currentFile.rename(targetPath)).path;

    return tunnel.copyWith(
      enabled: enabled,
      filePath: resolvedPath,
      fileName: FrpPaths.fileNameFromPath(resolvedPath),
    );
  }

  Future<void> deleteTunnel(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
