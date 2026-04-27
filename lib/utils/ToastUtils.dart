import 'package:flutter/material.dart';

//底部提示弹窗
class ToastUtils {
  static void showToast(BuildContext context, String? msg) {
    // 计算文本宽度，动态调整 SnackBar 宽度
    final TextPainter textPainter = TextPainter(text: TextSpan(text: msg), textDirection: TextDirection.ltr,)..layout();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        width: textPainter.size.width + 40,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), 
        duration: Duration(milliseconds: 500), 
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        behavior: SnackBarBehavior.floating, 
        content: Text(msg ?? "加载成功", textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),)
      )
    );
  }
}