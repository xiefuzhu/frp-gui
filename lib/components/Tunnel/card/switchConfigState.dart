import 'package:flutter/material.dart';

//切换启用禁用开关
Widget switchConfigState({
  required bool enabled,
  required ValueChanged<bool> onChanged,
}) {
  return Switch(
    value: enabled,
    onChanged: onChanged,
  );
}
