import 'package:flutter/material.dart';

import '../../../../models/server_config.dart';
import '../../../../services/config_repository.dart';
import '../../../../services/frp_process_service.dart';
import '../../../utils/app_toast.dart';
import '../../../widgets/labeled_text_field.dart';
import '../../../widgets/responsive_modal.dart';

class ServerConfigDialog extends StatefulWidget {
  final ServerConfig initialConfig;
  final bool isSheet;

  const ServerConfigDialog({
    super.key,
    required this.initialConfig,
    required this.isSheet,
  });

  static Future<void> show(BuildContext context) async {
    final current = await ConfigRepository.instance.loadServerConfig();
    if (!context.mounted) return;

    await showResponsiveModal<void>(
      context: context,
      builder: (_, isSheet) => ServerConfigDialog(
        initialConfig: current,
        isSheet: isSheet,
      ),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _addrController;
  late final TextEditingController _portController;
  late final TextEditingController _tokenController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _addrController = TextEditingController(
      text: widget.initialConfig.serverAddr,
    );
    _portController = TextEditingController(
      text: '${widget.initialConfig.serverPort}',
    );
    _tokenController = TextEditingController(
      text: widget.initialConfig.token,
    );
  }

  @override
  void dispose() {
    _addrController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_saving) return;

    final portText = _portController.text.trim();
    final parsedPort = portText.isEmpty ? 7000 : (int.tryParse(portText) ?? -1);
    final draft = ServerConfig(
      serverAddr: _addrController.text.trim(),
      serverPort: parsedPort,
      token: _tokenController.text.trim(),
    );

    final error = draft.validate();
    if (error != null) {
      AppToast.show(context, error);
      return;
    }

    setState(() => _saving = true);
    try {
      await ConfigRepository.instance.saveServerConfig(draft);
      final restarted = await FrpProcessService.instance.restartIfRunning();
      if (!mounted) return;
      AppToast.show(context, restarted ? '保存成功，已重连生效' : '保存成功');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, '保存失败: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.isSheet) ...[
            Center(
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(140),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            '服务端配置',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  LabeledTextField(
                    controller: _addrController,
                    labelText: '服务器地址',
                    hintText: '127.0.0.1 或域名',
                  ),
                  const SizedBox(height: 16),
                  LabeledTextField(
                    controller: _portController,
                    labelText: '服务器端口',
                    hintText: '7000',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  LabeledTextField(
                    controller: _tokenController,
                    labelText: '连接密钥 Token (可选)',
                    hintText: '留空则不使用 token 鉴权',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _saving ? null : _handleSave,
                child: Text(_saving ? '保存中...' : '保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
