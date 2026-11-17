import 'package:flutter/material.dart';

import '../../../controllers/tunnel_list_controller.dart';
import 'widgets/tunnel_card_item.dart';
import 'widgets/tunnel_form_dialog.dart';

class TunnelsPage extends StatefulWidget {
  const TunnelsPage({super.key});

  @override
  State<TunnelsPage> createState() => _TunnelsPageState();
}

class _TunnelsPageState extends State<TunnelsPage> {
  @override
  void initState() {
    super.initState();
    TunnelListController.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: ListenableBuilder(
              listenable: TunnelListController.instance,
              builder: (context, _) {
                final controller = TunnelListController.instance;
                if (controller.isLoading && controller.tunnels.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.error != null && controller.tunnels.isEmpty) {
                  return Center(
                    child: Text('读取配置失败: ${controller.error}'),
                  );
                }
                final items = controller.tunnels;
                if (items.isEmpty) {
                  return const Center(child: Text('暂无隧道配置，点击右下角按钮新增'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 84),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    mainAxisExtent: 148,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final tunnel = items[index];
                    return TunnelCardItem(
                      key: ValueKey(tunnel.filePath ?? tunnel.name),
                      tunnel: tunnel,
                    );
                  },
                );
              },
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            heroTag: 'add_tunnel_fab',
            tooltip: '添加隧道',
            onPressed: () => TunnelFormDialog.show(context),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
