import 'package:flutter/material.dart';

import '../../../models/server_config.dart';
import '../../../services/config_repository.dart';
import '../../../services/preferences_service.dart';
import '../../shell/desktop_title_bar.dart';
import '../../utils/app_toast.dart';
import '../../widgets/labeled_text_field.dart';

class OobePage extends StatefulWidget {
  const OobePage({super.key});

  @override
  State<OobePage> createState() => _OobePageState();
}

class _OobePageState extends State<OobePage> {
  final TextEditingController _serverAddrController = TextEditingController();
  final TextEditingController _serverPortController =
      TextEditingController(text: '7000');
  final TextEditingController _tokenController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _serverAddrController.dispose();
    _serverPortController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (_saving) return;

    final portText = _serverPortController.text.trim();
    final parsedPort = portText.isEmpty ? 7000 : (int.tryParse(portText) ?? -1);
    final config = ServerConfig(
      serverAddr: _serverAddrController.text.trim(),
      serverPort: parsedPort,
      token: _tokenController.text.trim(),
    );

    final error = config.validate();
    if (error != null) {
      AppToast.show(context, error);
      return;
    }

    setState(() => _saving = true);
    try {
      await ConfigRepository.instance.saveServerConfig(config);
      await PreferencesService.instance.setOobeCompleted();
      if (!mounted) return;
      AppToast.show(context, '配置已保存');
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, '保存失败: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _skipForNow() async {
    await PreferencesService.instance.setOobeCompleted();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: const DesktopTitleBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.router_rounded, size: 64, color: scheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    '欢迎使用 frp-gui',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '首次使用前，可先配置 FRP 服务端连接信息',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          LabeledTextField(
                            controller: _serverAddrController,
                            labelText: '服务器地址',
                            hintText: '例: 192.168.1.100 或 frp.example.com',
                          ),
                          const SizedBox(height: 16),
                          LabeledTextField(
                            controller: _serverPortController,
                            labelText: '服务器端口',
                            hintText: '7000',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          LabeledTextField(
                            controller: _tokenController,
                            labelText: 'Token (可选)',
                            hintText: '服务端鉴权令牌',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _saveAndContinue,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_saving ? '正在保存...' : '完成配置'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _saving ? null : _skipForNow,
                    child: const Text('稍后在设置中配置'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
