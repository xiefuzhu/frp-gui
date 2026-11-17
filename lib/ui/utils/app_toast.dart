import 'package:flutter/material.dart';

class AppToast {
  AppToast._();

  static void show(BuildContext context, String? message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final text = message ?? '操作完成';
    final screenWidth = MediaQuery.of(context).size.width;
    final estimatedWidth = (text.length * 16.0 + 48.0).clamp(
      120.0,
      screenWidth > 60 ? screenWidth - 40 : 280.0,
    );

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        duration: const Duration(milliseconds: 1500),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        width: estimatedWidth,
        behavior: SnackBarBehavior.floating,
        content: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
