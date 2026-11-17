import 'package:flutter/material.dart';

Future<T?> showResponsiveModal<T>({
  required BuildContext context,
  required Widget Function(BuildContext modalContext, bool isSheet) builder,
  double maxWidth = 560,
}) {
  final isCompact = MediaQuery.of(context).size.width < 600;
  if (isCompact) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
            ),
            child: builder(sheetContext, true),
          ),
        );
      },
    );
  }

  return showDialog<T>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.8,
          ),
          child: builder(dialogContext, false),
        ),
      );
    },
  );
}
