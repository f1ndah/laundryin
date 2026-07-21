import 'package:flutter/material.dart';
import '../theme.dart';

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    bool isInfo = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isInfo ? Icons.info_outline : (isError ? Icons.error_outline : Icons.check_circle_outline),
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: isInfo ? AppColors.primary : (isError ? AppColors.danger : Colors.green),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        duration: const Duration(seconds: 3),
        elevation: 0,
      ),
    );
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, isError: true);
  }

  static void success(BuildContext context, String message) {
    show(context, message: message, isError: false);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, isInfo: true);
  }
}
