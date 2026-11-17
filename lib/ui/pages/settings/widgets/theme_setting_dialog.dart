import 'package:flutter/material.dart';

import '../../../../controllers/theme_controller.dart';
import '../../../widgets/responsive_modal.dart';

class ThemeSettingDialog extends StatefulWidget {
  final bool isSheet;

  const ThemeSettingDialog({
    super.key,
    required this.isSheet,
  });

  static Future<void> show(BuildContext context) {
    return showResponsiveModal<void>(
      context: context,
      builder: (_, isSheet) => ThemeSettingDialog(isSheet: isSheet),
    );
  }

  @override
  State<ThemeSettingDialog> createState() => _ThemeSettingDialogState();
}

class _ThemeSettingDialogState extends State<ThemeSettingDialog> {
  static const List<(ThemeMode, String)> _modes = [
    (ThemeMode.system, '跟随系统'),
    (ThemeMode.light, '浅色'),
    (ThemeMode.dark, '深色'),
  ];

  late final ThemeMode _initialMode;
  late final Color _initialColor;
  late final bool _initialFollowSystem;
  bool _committed = false;

  @override
  void initState() {
    super.initState();
    final ctrl = ThemeController.instance;
    _initialMode = ctrl.themeMode;
    _initialColor = ctrl.accentColor;
    _initialFollowSystem = ctrl.followSystemColor;
  }

  @override
  void dispose() {
    if (!_committed) {
      ThemeController.instance.restoreSnapshot(
        mode: _initialMode,
        color: _initialColor,
        followSystem: _initialFollowSystem,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ThemeController.instance;
    final colorOptions = ctrl.presetColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: ListenableBuilder(
        listenable: ctrl,
        builder: (context, _) {
          return Column(
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
                '外观主题',
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
                      const Text('主题模式', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: _modes.map((entry) {
                          return ChoiceChip(
                            side: BorderSide.none,
                            selected: ctrl.themeMode == entry.$1,
                            label: Text(entry.$2),
                            onSelected: (_) => ctrl.setThemeMode(entry.$1),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      const Text('主题色', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(colorOptions.length, (index) {
                          final optionColor = colorOptions[index];
                          final isSystemOption = index == 0;
                          final isSelected = isSystemOption
                              ? ctrl.followSystemColor
                              : (!ctrl.followSystemColor &&
                                    ctrl.accentColor.toARGB32() ==
                                        optionColor.toARGB32());

                          return InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              ctrl.selectColorOption(
                                optionColor,
                                isSystemOption: isSystemOption,
                              );
                            },
                            child: Ink(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                color: optionColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: optionColor.withAlpha(160),
                                    blurRadius: 6,
                                    offset: const Offset(1, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  if (isSelected)
                                    const Center(
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  if (isSystemOption)
                                    const Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Icon(
                                        Icons.colorize,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      _committed = true;
                      await ctrl.persist();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
