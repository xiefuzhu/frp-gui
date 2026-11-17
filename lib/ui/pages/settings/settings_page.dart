import 'package:flutter/material.dart';

import '../../../services/auto_start_service.dart';
import '../../utils/app_toast.dart';
import '../../widgets/setting_tile_card.dart';
import 'widgets/server_config_dialog.dart';
import 'widgets/theme_setting_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _autoStartEnabled = false;
  bool _loadingAutoStart = true;

  @override
  void initState() {
    super.initState();
    _loadAutoStart();
  }

  Future<void> _loadAutoStart() async {
    if (!AutoStartService.instance.isSupported) {
      setState(() => _loadingAutoStart = false);
      return;
    }
    final enabled = await AutoStartService.instance.isEnabled();
    if (!mounted) return;
    setState(() {
      _autoStartEnabled = enabled;
      _loadingAutoStart = false;
    });
  }

  Future<void> _toggleAutoStart(bool value) async {
    final ok = await AutoStartService.instance.setEnabled(value);
    if (!mounted) return;
    if (ok) {
      setState(() => _autoStartEnabled = value);
      AppToast.show(context, value ? '已开启开机自启' : '已关闭开机自启');
    } else {
      AppToast.show(context, '操作失败，请检查系统权限');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 10, 15, 16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SettingTileCard(
                icon: Icons.color_lens_outlined,
                title: '外观',
                subtitle: '切换深浅色模式与自定义主题色',
                onTap: () => ThemeSettingDialog.show(context),
              ),
              const SizedBox(height: 12),
              SettingTileCard(
                icon: Icons.dns_outlined,
                title: '服务端',
                subtitle: '设置穿透服务器地址、端口与鉴权密钥',
                onTap: () => ServerConfigDialog.show(context),
              ),
              if (AutoStartService.instance.isSupported) ...[
                const SizedBox(height: 12),
                SettingTileCard(
                  icon: Icons.power_settings_new_outlined,
                  title: '开机自启动',
                  subtitle: '系统登录时自动后台启动 FRP 穿透服务',
                  onTap: _loadingAutoStart
                      ? null
                      : () => _toggleAutoStart(!_autoStartEnabled),
                  trailing: _loadingAutoStart
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Switch(
                          value: _autoStartEnabled,
                          onChanged: _toggleAutoStart,
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
