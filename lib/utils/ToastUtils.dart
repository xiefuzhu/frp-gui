import 'package:flutter/material.dart';

//底部提示弹窗
class ToastUtils {
  static void showToast(BuildContext context, String? msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), 
        duration: Duration(milliseconds: 500), 
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        width: 100,
        behavior: SnackBarBehavior.floating, 
        content: Text(msg ?? "加载成功", textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),)
      )
    );
  }
}