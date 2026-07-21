import 'package:flutter/material.dart';
import '../theme.dart';

enum AppButtonVariant { primary, secondary, outline, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final AppButtonVariant variant;

  final bool iconRight;
  final bool expandContent;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.variant = AppButtonVariant.primary,
    this.iconRight = false,
    this.expandContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final isFilled = variant == AppButtonVariant.primary || variant == AppButtonVariant.secondary;
    final hasBorder = variant == AppButtonVariant.outline;
    final fillColor = backgroundColor ?? (variant == AppButtonVariant.secondary ? AppColors.secondary : AppColors.primary);
    final contentColor = isFilled ? Colors.white : AppColors.primary;

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isFilled ? fillColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: hasBorder ? Border.all(color: AppColors.primary) : (isFilled ? null : null),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(contentColor),
                  ),
                ),
              )
            : Row(
                mainAxisSize: expandContent ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: expandContent ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
                children: [
                  if (icon != null && !iconRight) ...[
                    Icon(icon, size: 20, color: contentColor),
                    if (!expandContent) const SizedBox(width: 8),
                  ],
                  Text(label, style: AppTextStyles.button.copyWith(color: contentColor)),
                  if (icon != null && iconRight) ...[
                    if (!expandContent) const SizedBox(width: 8),
                    Icon(icon, size: 20, color: contentColor),
                  ],
                ],
              ),
      ),
    );
  }
}
