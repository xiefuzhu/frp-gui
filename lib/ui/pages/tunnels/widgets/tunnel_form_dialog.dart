import 'package:flutter/material.dart';

import '../../../../controllers/tunnel_list_controller.dart';
import '../../../../models/tunnel_config.dart';
import '../../../../models/tunnel_protocol.dart';
import '../../../utils/app_toast.dart';
import '../../../widgets/labeled_text_field.dart';
import '../../../widgets/responsive_modal.dart';

class TunnelFormDialog extends StatefulWidget {
  final TunnelConfig? initialTunnel;
  final bool isSheet;

  const TunnelFormDialog({
    super.key,
    this.initialTunnel,
    required this.isSheet,
  });

  static Future<bool?> show(
    BuildContext context, {
    TunnelConfig? initialTunnel,
  }) {
    return showResponsiveModal<bool>(
      context: context,
      builder: (modalContext, isSheet) => TunnelFormDialog(
        initialTunnel: initialTunnel,
        isSheet: isSheet,
      ),
    );
  }

  @override
  State<TunnelFormDialog> createState() => _TunnelFormDialogState();
}

class _TunnelFormDialogState extends State<TunnelFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _localIpController;
  late final TextEditingController _localPortController;
  late final TextEditingController _remotePortController;
  late final TextEditingController _customDomainsController;
  late final TextEditingController _subdomainController;
  late final TextEditingController _secretKeyController;
  late TunnelProtocol _protocol;
  bool _saving = false;

  bool get _isEditing => widget.initialTunnel != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTunnel;
    _protocol = initial?.protocol ?? TunnelProtocol.tcp;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _localIpController = TextEditingController(
      text: initial != null ? initial.localIp : '',
    );
    _localPortController = TextEditingController(
      text: (initial != null && initial.localPort > 0)
          ? '${initial.localPort}'
          : '',
    );
    _remotePortController = TextEditingController(
      text: (initial != null && initial.remotePort > 0)
          ? '${initial.remotePort}'
          : '',
    );
    _customDomainsController = TextEditingController(
      text: initial?.customDomains.join(', ') ?? '',
    );
    _subdomainController = TextEditingController(
      text: initial?.subdomain ?? '',
    );
    _secretKeyController = TextEditingController(
      text: initial?.secretKey ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _localIpController.dispose();
    _localPortController.dispose();
    _remotePortController.dispose();
    _customDomainsController.dispose();
    _subdomainController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_saving) return;

    final ipText = _localIpController.text.trim();
    final draft = TunnelConfig(
      name: _nameController.text.trim(),
      protocol: _protocol,
      localIp: ipText.isEmpty ? '127.0.0.1' : ipText,
      localPort: int.tryParse(_localPortController.text.trim()) ?? 0,
      remotePort: int.tryParse(_remotePortController.text.trim()) ?? 0,
      customDomains: TunnelConfig.parseCustomDomains(
        _customDomainsController.text,
      ),
      subdomain: _subdomainController.text.trim(),
      secretKey: _secretKeyController.text.trim(),
      extraFields: widget.initialTunnel?.extraFields ?? const {},
      filePath: widget.initialTunnel?.filePath,
      fileName: widget.initialTunnel?.fileName,
      enabled: widget.initialTunnel?.enabled ?? true,
    );

    final validationError = draft.validate();
    if (validationError != null) {
      AppToast.show(context, validationError);
      return;
    }

    setState(() => _saving = true);
    try {
      final restarted = await TunnelListController.instance.saveTunnel(draft);
      if (!mounted) return;
      AppToast.show(context, restarted ? '保存成功，已生效' : '保存成功');
      Navigator.of(context).pop(true);
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
            _isEditing ? '修改配置' : '添加隧道',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('网络类型:'),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<TunnelProtocol>(
                      showSelectedIcon: false,
                      segments: TunnelProtocol.values
                          .map(
                            (p) => ButtonSegment<TunnelProtocol>(
                              value: p,
                              label: Text(p.value),
                            ),
                          )
                          .toList(),
                      selected: {_protocol},
                      onSelectionChanged: (selection) {
                        setState(() => _protocol = selection.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('基础配置:'),
                  const SizedBox(height: 10),
                  LabeledTextField(
                    controller: _nameController,
                    labelText: '名称',
                    hintText: 'mc_server',
                  ),
                  const SizedBox(height: 16),
                  LabeledTextField(
                    controller: _localIpController,
                    labelText: '本地 IP',
                    hintText: '127.0.0.1',
                  ),
                  const SizedBox(height: 16),
                  LabeledTextField(
                    controller: _localPortController,
                    labelText: '本地端口',
                    hintText: '25565',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  if (_protocol.isHttpLike) ...[
                    LabeledTextField(
                      controller: _customDomainsController,
                      labelText: '自定义域名',
                      hintText: 'example.com (多个用逗号分隔)',
                    ),
                    const SizedBox(height: 16),
                    LabeledTextField(
                      controller: _subdomainController,
                      labelText: '子域名 (可选)',
                      hintText: 'sub',
                    ),
                  ] else if (_protocol.isSecretLike) ...[
                    LabeledTextField(
                      controller: _secretKeyController,
                      labelText: '访问密钥',
                      hintText: 'secret_key',
                    ),
                  ] else ...[
                    LabeledTextField(
                      controller: _remotePortController,
                      labelText: '远程端口',
                      hintText: '25565',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
