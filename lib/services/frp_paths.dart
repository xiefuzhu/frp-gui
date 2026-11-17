import 'dart:io';

class FrpPaths {
  FrpPaths._();

  static const String includePattern = './tunnels/*.toml';

  /// 仅供单测与组件测试覆盖工作目录，生产环境保持为 null
  static String? debugBaseDirOverride;

  static Future<Directory> resolveBaseDir() async {
    final override = debugBaseDirOverride?.trim();
    if (override != null && override.isNotEmpty) {
      final overrideDir = Directory(override);
      if (!await overrideDir.exists()) {
        await overrideDir.create(recursive: true);
      }
      return overrideDir;
    }

    final sep = Platform.pathSeparator;
    final cwdPath = Directory.current.path;
    final cwdFrp = Directory('$cwdPath${sep}frp');
    if (await cwdFrp.exists()) {
      return cwdFrp;
    }

    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final exeFrp = Directory('$exeDir${sep}frp');
    if (await exeFrp.exists()) {
      return exeFrp;
    }

    if (await File('$cwdPath${sep}pubspec.yaml').exists()) {
      await cwdFrp.create(recursive: true);
      return cwdFrp;
    }

    try {
      await exeFrp.create(recursive: true);
      return exeFrp;
    } catch (_) {
      final fallback = Directory(
        '${Directory.systemTemp.path}${sep}frp_gui${sep}frp',
      );
      await fallback.create(recursive: true);
      return fallback;
    }
  }

  static Future<String> resolveMainConfigPath() async {
    final dir = await resolveBaseDir();
    return '${dir.path}${Platform.pathSeparator}frpc.toml';
  }

  static Future<String> resolveTunnelDirPath() async {
    final dir = await resolveBaseDir();
    return '${dir.path}${Platform.pathSeparator}tunnels';
  }

  static Future<String> resolvePidFilePath() async {
    final dir = await resolveBaseDir();
    return '${dir.path}${Platform.pathSeparator}frp.pid';
  }

  static Future<List<String>> candidateExecutablePaths() async {
    final sep = Platform.pathSeparator;
    final frpDir = (await resolveBaseDir()).path;
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final primaryBins = Platform.isWindows
        ? const ['frpc.exe', 'frpc']
        : const ['frpc', 'frpc.exe'];

    final candidates = <String>[];
    for (final bin in primaryBins) {
      candidates.add('$frpDir$sep$bin');
    }
    for (final bin in primaryBins) {
      candidates.add('frp$sep$bin');
      candidates.add('$exeDir${sep}frp$sep$bin');
    }
    return candidates.toSet().toList();
  }

  static Future<String?> resolveExecutablePath() async {
    for (final path in await candidateExecutablePaths()) {
      if (await File(path).exists()) {
        return path;
      }
    }
    return null;
  }

  static String fileNameFromPath(String path) {
    return path.replaceAll('\\', '/').split('/').last;
  }

  static String fileStem(String path) {
    final name = fileNameFromPath(path);
    final dotIndex = name.lastIndexOf('.');
    return dotIndex > 0 ? name.substring(0, dotIndex) : name;
  }

  static String sanitizeFileStem(String name) {
    final sanitized = name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return sanitized.isEmpty ? 'tunnel' : sanitized;
  }
}
