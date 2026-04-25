import 'package:flutter/material.dart';
import '../../../pages/popupwindows/changeTunnel.dart';

//显示更多内容的弹出菜单
MenuAnchor moreMenu(
  BuildContext context,
  Map<String, dynamic> tunnel, {
  VoidCallback? onTunnelUpdated,
  VoidCallback? onTunnelDeleted,
}) {
  return MenuAnchor(
    childFocusNode: FocusNode(),

    menuChildren: <Widget>[
      MenuItemButton(
        onPressed: () => (MediaQuery.of(context).size.width < 600)
            ? changeTunnel2(context, tunnel, onUpdated: onTunnelUpdated)
            : changeTunnel(context, tunnel, onUpdated: onTunnelUpdated),
        child: const Text('修改'),
      ),
      MenuItemButton(
        onPressed: () =>
            deletTunnel(context, tunnel, onDeleted: onTunnelDeleted),
        child: const Text('删除'),
      ),
    ],
    builder: (BuildContext context, MenuController controller, Widget? child) {
      return SizedBox(
        height: 35,
        width: 35,
        child: IconButton(
          alignment: Alignment.center,
          // 通过负 X 偏移让菜单从按钮左侧弹出。
          onPressed: () => controller.open(position: const Offset(-20, 0)),
          icon: Icon(Icons.more_horiz, size: 20),
        ),
      );
    },
  );
}
