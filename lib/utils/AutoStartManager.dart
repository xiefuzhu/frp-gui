import 'dart:io';
import 'TerminalUtil.dart';

/// 跨平台开机自启动管理器
/// macOS: 通过 LaunchAgent plist 实现
/// Windows: 通过注册表 HKCU\Run 实现
class AutoStartManager {
  AutoStartManager._();
  static final AutoStartManager instance = AutoStartManager._();

  /// plist 标签 / 注册表键名
  static const String _launchAgentLabel = 'com.frpgui.frp';

  /// 获取当前可执行文件路径
  String get _executablePath => Platform.resolvedExecutable;

  // ──────────────────────── macOS ────────────────────────

  String get _launchAgentDir {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/Library/LaunchAgents';
  }

  String get _plistPath => '$_launchAgentDir/$_launchAgentLabel.plist';

  String _buildPlistContent() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$_launchAgentLabel</string>
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

  Future<bool> _enableMacOS() async {
    try {
      final dir = Directory(_launchAgentDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      // 只写入 plist 文件，不调用 launchctl load
      // 系统会在下次登录时自动加载 ~/Library/LaunchAgents/ 下的 plist
      await File(_plistPath).writeAsString(_buildPlistContent());
      TerminalUtil.instance.writeLog('已启用开机自启动 (macOS)，将在下次登录时生效');
      return true;
    } catch (e) {
      TerminalUtil.instance.writeLog('启用开机自启动失败: $e');
      return false;
    }
  }

  Future<bool> _disableMacOS() async {
    try {
      final file = File(_plistPath);
      if (await file.exists()) {
        // 如果 plist 之前被 launchd 加载过，先卸载（当前会话我们不会 load，但可能遗留）
        await Process.run('launchctl', ['unload', _plistPath]);
        await file.delete();
      }
      TerminalUtil.instance.writeLog('已禁用开机自启动 (macOS)');
      return true;
    } catch (e) {
      TerminalUtil.instance.writeLog('禁用开机自启动失败: $e');
      return false;
    }
  }

  Future<bool> _isEnabledMacOS() async {
    try {
      return await File(_plistPath).exists();
    } catch (_) {
      return false;
    }
  }

  // ──────────────────────── Windows ────────────────────────

  Future<bool> _enableWindows() async {
    try {
      final result = await Process.run('reg', [
        'add',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
        '/v',
        _launchAgentLabel,
        '/t',
        'REG_SZ',
        '/d',
        '"$_executablePath" --autostart',
        '/f',
      ]);
      if (result.exitCode == 0) {
        TerminalUtil.instance.writeLog('已启用开机自启动 (Windows)');
        return true;
      }
      TerminalUtil.instance.writeLog('启用开机自启动失败: ${result.stderr}');
      return false;
    } catch (e) {
      TerminalUtil.instance.writeLog('启用开机自启动失败: $e');
      return false;
    }
  }

  Future<bool> _disableWindows() async {
    try {
      final result = await Process.run('reg', [
        'delete',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
        '/v',
        _launchAgentLabel,
        '/f',
      ]);
      if (result.exitCode == 0) {
        TerminalUtil.instance.writeLog('已禁用开机自启动 (Windows)');
        return true;
      }
      // exitCode 1 means key not found, still success
      TerminalUtil.instance.writeLog('已禁用开机自启动 (Windows)');
      return true;
    } catch (e) {
      TerminalUtil.instance.writeLog('禁用开机自启动失败: $e');
      return false;
    }
  }

  Future<bool> _isEnabledWindows() async {
    try {
      final result = await Process.run('reg', [
        'query',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run',
        '/v',
        _launchAgentLabel,
      ]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  // ──────────────────────── 公共接口 ────────────────────────

  /// 设置开机自启动状态
  Future<bool> setEnabled(bool enabled) async {
    if (Platform.isMacOS) {
      return enabled ? await _enableMacOS() : await _disableMacOS();
    } else if (Platform.isWindows) {
      return enabled ? await _enableWindows() : await _disableWindows();
    }
    return false;
  }

  /// 查询当前是否已启用开机自启动
  Future<bool> isEnabled() async {
    if (Platform.isMacOS) {
      return await _isEnabledMacOS();
    } else if (Platform.isWindows) {
      return await _isEnabledWindows();
    }
    return false;
  }
}
