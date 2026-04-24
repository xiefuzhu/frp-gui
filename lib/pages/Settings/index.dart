import 'package:flutter/material.dart';
import 'package:frp_flutter/components/Settings/themeModeSetting.dart';

class SettingView extends StatefulWidget {
  const SettingView({super.key});

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child:  Padding(
        padding: EdgeInsetsGeometry.only(left: 15, right: 15, top: 10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              themeModeSetting(context)
            ]
          ),
        ),
      )
    );
  }
}
