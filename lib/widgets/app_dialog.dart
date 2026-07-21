import 'package:flutter/material.dart';
import '../theme.dart';
import 'app_button.dart';

class AppDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
  }) {
    return showDialog<T>(
      context: context,
      builder: builder,
    );
  }

  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String cancelLabel = 'Batal',
    String confirmLabel = 'OK',
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: AppTextStyles.subheading),
        content: Text(message, style: AppTextStyles.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelLabel, style: AppTextStyles.bodyBold.copyWith(color: AppColors.textLight))),
          AppButton(label: confirmLabel, backgroundColor: confirmColor, onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
  }

  static Future<void> info({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: AppTextStyles.subheading),
        content: content ?? (message != null ? Text(message, style: AppTextStyles.body) : null),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  static Widget themed({required BuildContext context, String? title, required List<Widget> content, required List<Widget> actions}) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: title != null ? Text(title, style: AppTextStyles.subheading) : null,
      content: content.length == 1 ? content.first : Column(mainAxisSize: MainAxisSize.min, children: content),
      actions: actions,
    );
  }
}
