import 'package:flutter/material.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_icons.dart';
import '../core/design/app_typography.dart';

class DestructiveActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const DestructiveActionButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.delete, size: 18, color: AppColors.destructive),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.button.copyWith(color: AppColors.destructive),
            ),
          ],
        ),
      ),
    );
  }
}
