import 'dart:io';
import 'package:flutter/material.dart';
import '../../utils/AutoStartManager.dart';
import '../../utils/ToastUtils.dart';

/// 开机自启动设置组件
/// 仅 macOS 和 Windows 显示，其他平台隐藏
class AutoStartSetting extends StatefulWidget {
  const AutoStartSetting({super.key});

  @override
  State<AutoStartSetting> createState() => _AutoStartSettingState();
}

class _AutoStartSettingState extends State<AutoStartSetting> {
  bool _autoStart = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final enabled = await AutoStartManager.instance.isEnabled();
    if (mounted) {
      setState(() {
        _autoStart = enabled;
        _loading = false;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    final ok = await AutoStartManager.instance.setEnabled(value);
    if (mounted) {
      if (ok) {
        setState(() => _autoStart = value);
        ToastUtils.showToast(context, value ? '已开启开机自启' : '已关闭开机自启');
      } else {
        ToastUtils.showToast(context, '操作失败，请检查权限');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 仅在桌面平台显示此设置项
    if (!Platform.isMacOS && !Platform.isWindows) {
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: const Icon(Icons.power_settings_new),
      title: const Text('开机自启动'),
      subtitle: const Text('系统启动时自动运行 FRP 穿透服务'),
      trailing: _loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(value: _autoStart, onChanged: _toggle),
    );
  }
}
