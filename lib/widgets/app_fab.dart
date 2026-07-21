import 'package:flutter/material.dart';
import '../theme.dart';

class AppFab extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const AppFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        hoverElevation: 0,
        focusElevation: 0,
      ),
    );
  }
}
