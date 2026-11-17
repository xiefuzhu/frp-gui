import 'dart:io';

import 'log_service.dart';

class AutoStartService {
  AutoStartService._();
  static final AutoStartService instance = AutoStartService._();

  static const String _appId = 'com.frpgui.frp';

  /// 仅供组件测试隔离系统注册表/LaunchAgent 调用，生产环境保持为 null
  static bool? debugOverrideEnabled;

  String get _executablePath => Platform.resolvedExecutable;

  bool get isSupported =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  // ── macOS LaunchAgent ──

  String get _macPlistPath {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/Library/LaunchAgents/$_appId.plist';
  }

  String _buildMacPlist() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$_appId</string>
    <key>ProgramArguments</key>
    <array>
        <string>$_executablePath</string>
        <string>--autostart</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>''';
  }

  Future<bool> _setMacEnabled(bool enabled) async {
    try {
      final file = File(_macPlistPath);
      if (enabled) {
        await file.parent.create(recursive: true);
        await file.writeAsString(_buildMacPlist());
        LogService.instance.write('已启用开机自启动 (macOS)');
      } else {
        if (await file.exists()) {
          await Process.run('launchctl', ['unload', _macPlistPath]);
          await file.delete();
        }
        LogService.instance.write('已禁用开机自启动 (macOS)');
      }
      return true;
    } catch (e) {
      LogService.instance.write('设置 macOS 开机自启动失败: $e');
      return false;
    }
  }

  // ── Windows Registry HKCU\Run ──

  Future<bool> _setWindowsEnabled(bool enabled) async {
    try {
      if (enabled) {
        final result = await Process.run('reg', [
          'add',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
          '/v',
          _appId,
          '/t',
          'REG_SZ',
          '/d',
          '"$_executablePath" --autostart',
          '/f',
        ]);
        if (result.exitCode == 0) {
          LogService.instance.write('已启用开机自启动 (Windows)');
          return true;
        }
        LogService.instance.write('启用开机自启动失败: ${result.stderr}');
        return false;
      } else {
        await Process.run('reg', [
          'delete',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
          '/v',
          _appId,
          '/f',
        ]);
        LogService.instance.write('已禁用开机自启动 (Windows)');
        return true;
      }
    } catch (e) {
      LogService.instance.write('设置 Windows 开机自启动失败: $e');
      return false;
    }
  }

  // ── Linux XDG Autostart ──

  String get _linuxDesktopPath {
    final configHome =
        Platform.environment['XDG_CONFIG_HOME'] ??
        '${Platform.environment['HOME'] ?? ''}/.config';
    return '$configHome/autostart/$_appId.desktop';
  }

  String _buildLinuxDesktopEntry() {
    return '''[Desktop Entry]
Type=Application
Name=frp-gui
Exec="$_executablePath" --autostart
Terminal=false
X-GNOME-Autostart-enabled=true
''';
  }

  Future<bool> _setLinuxEnabled(bool enabled) async {
    try {
      final file = File(_linuxDesktopPath);
      if (enabled) {
        await file.parent.create(recursive: true);
        await file.writeAsString(_buildLinuxDesktopEntry());
        LogService.instance.write('已启用开机自启动 (Linux)');
      } else {
        if (await file.exists()) {
          await file.delete();
        }
        LogService.instance.write('已禁用开机自启动 (Linux)');
      }
      return true;
    } catch (e) {
      LogService.instance.write('设置 Linux 开机自启动失败: $e');
      return false;
    }
  }

  Future<bool> setEnabled(bool enabled) async {
    if (debugOverrideEnabled != null) {
      debugOverrideEnabled = enabled;
      return true;
    }
    if (Platform.isMacOS) return _setMacEnabled(enabled);
    if (Platform.isWindows) return _setWindowsEnabled(enabled);
    if (Platform.isLinux) return _setLinuxEnabled(enabled);
    return false;
  }

  Future<bool> isEnabled() async {
    if (debugOverrideEnabled != null) {
      return debugOverrideEnabled!;
    }
    try {
      if (Platform.isMacOS) {
        return await File(_macPlistPath).exists();
      }
      if (Platform.isWindows) {
        final result = await Process.run('reg', [
          'query',
          r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
          '/v',
          _appId,
        ]);
        return result.exitCode == 0;
      }
      if (Platform.isLinux) {
        return await File(_linuxDesktopPath).exists();
      }
    } catch (_) {}
    return false;
  }
}
