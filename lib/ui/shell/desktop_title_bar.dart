import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../services/frp_process_service.dart';

class DesktopTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const DesktopTitleBar({super.key});

  static bool get _isDesktopWindowSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  @override
  Size get preferredSize => const Size.fromHeight(36);

  Future<void> _toggleMaximize() async {
    if (!_isDesktopWindowSupported) return;
    if (await windowManager.isMaximized()) {
      await windowManager.restore();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      toolbarHeight: 36,
      flexibleSpace: GestureDetector(
        onDoubleTap: _toggleMaximize,
        onPanStart: (_) {
          if (_isDesktopWindowSupported) {
            windowManager.startDragging();
          }
        },
        child: Container(
          alignment: Alignment.centerLeft,
          color: Colors.transparent,
          padding: const EdgeInsets.only(left: 20),
          child: const Text(
            'frp-gui',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: '最小化',
          onPressed: () {
            if (_isDesktopWindowSupported) {
              windowManager.minimize();
            }
          },
          icon: const Icon(Icons.horizontal_rule, size: 18),
        ),
        IconButton(
          tooltip: '最大化/还原',
          onPressed: _toggleMaximize,
          icon: const Icon(Icons.crop_square, size: 18),
        ),
        IconButton(
          tooltip: '关闭',
          onPressed: () async {
            await FrpProcessService.instance.stop();
            if (_isDesktopWindowSupported) {
              await windowManager.setPreventClose(false);
              await windowManager.close();
            }
          },
          icon: const Icon(Icons.close, size: 18),
        ),
      ],
    );
  }
}
