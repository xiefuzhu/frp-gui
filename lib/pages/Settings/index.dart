import 'package:flutter/material.dart';
import 'package:frp_gui/components/Settings/themeModeSetting.dart';

import '../../components/Settings/autoStartSetting.dart';
import '../../components/Settings/serverSetting.dart';

class SettingView extends StatefulWidget {
  const SettingView({super.key});

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsetsGeometry.only(left: 15, right: 15, top: 10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const AutoStartSetting(),
              const SizedBox(height: 10),
              themeModeSetting(context),
              const SizedBox(height: 10),
              serverSetting(context),
            ],
          ),
        ),
      ),
    );
  }
}
