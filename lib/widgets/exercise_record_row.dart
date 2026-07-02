import 'package:flutter/material.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_icons.dart';
import 'category_color_indicator.dart';

class ExerciseRecordRow extends StatelessWidget {
  final String name;
  final String value;
  final Color categoryColor;
  final bool hasPr;

  const ExerciseRecordRow({
    super.key,
    required this.name,
    required this.value,
    required this.categoryColor,
    required this.hasPr,
  });

  @override
  Widget build(BuildContext context) {
    final showValue = value != '—';
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CategoryColorIndicator(color: categoryColor, size: 10),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.label1,
              ),
            ),
          ),
          if (showValue && hasPr) ...[
            Icon(AppIcons.trophy, size: 13, color: AppColors.pbGold),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.label1,
              ),
            ),
            const SizedBox(width: 4),
          ] else if (showValue) ...[
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.label2,
              ),
            ),
            const SizedBox(width: 4),
          ] else ...[
            const Text(
              '—',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.label2,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Icon(AppIcons.forward, size: 18, color: AppColors.chevron),
        ],
      ),
    );
  }
}
