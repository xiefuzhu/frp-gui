import 'package:flutter/material.dart';

import '../../../../controllers/tunnel_list_controller.dart';
import '../../../../models/tunnel_config.dart';
import '../../../utils/app_toast.dart';
import 'tunnel_form_dialog.dart';

class TunnelCardItem extends StatefulWidget {
  final TunnelConfig tunnel;

  const TunnelCardItem({
    super.key,
    required this.tunnel,
  });

  @override
  State<TunnelCardItem> createState() => _TunnelCardItemState();
}

class _TunnelCardItemState extends State<TunnelCardItem> {
  bool _toggling = false;

  Future<void> _handleToggle(bool nextValue) async {
    if (_toggling) return;
    setState(() => _toggling = true);
    try {
      final restarted = await TunnelListController.instance.toggleTunnel(
        widget.tunnel,
        nextValue,
      );
      if (!mounted) return;
      AppToast.show(context, restarted ? '更改成功，已重载穿透' : '更改成功');
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, '更改失败');
    } finally {
      if (mounted) {
        setState(() => _toggling = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定删除隧道 "${widget.tunnel.name}" 吗？该操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      final restarted = await TunnelListController.instance.deleteTunnel(
        widget.tunnel,
      );
      if (!mounted) return;
      AppToast.show(context, restarted ? '删除成功，已重载穿透' : '删除成功');
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, '删除失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tunnel = widget.tunnel;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tunnel.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withAlpha(140),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Text(
                    tunnel.protocol.value.toUpperCase(),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                Text(
                  'IP: ${tunnel.localIp}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  '本地端口: ${tunnel.localPort}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  tunnel.targetSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: tunnel.enabled,
                  onChanged: _toggling ? null : _handleToggle,
                ),
              ),
              MenuAnchor(
                menuChildren: [
                  MenuItemButton(
                    onPressed: () {
                      TunnelFormDialog.show(context, initialTunnel: tunnel);
                    },
                    child: const Text('修改'),
                  ),
                  MenuItemButton(
                    onPressed: _confirmDelete,
                    child: const Text('删除'),
                  ),
                ],
                builder: (context, controller, _) {
                  return SizedBox(
                    height: 32,
                    width: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () =>
                          controller.open(position: const Offset(-20, 0)),
                      icon: const Icon(Icons.more_horiz, size: 20),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
