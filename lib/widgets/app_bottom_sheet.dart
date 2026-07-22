import 'package:flutter/material.dart';
import '../theme.dart';

class SheetAction {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Widget? trailing;

  const SheetAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
    this.trailing,
  });
}

class AppBottomSheet {
  static void show({
    required BuildContext context,
    String? title,
    String? subtitle,
    required List<SheetAction> actions,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                const SizedBox(height: 4),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(title, style: AppTextStyles.subheading),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
                const Divider(),
              ],
              ...actions.map((a) => ListTile(
                    leading: Icon(a.icon, color: a.color ?? AppColors.text),
                    title: Text(a.label, style: TextStyle(color: a.color ?? AppColors.text, fontWeight: FontWeight.w500)),
                    trailing: a.trailing,
                    onTap: () {
                      Navigator.pop(context);
                      a.onTap?.call();
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
