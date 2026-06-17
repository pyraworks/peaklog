import 'package:flutter/material.dart';
import '../core/design/app_typography.dart';

class PbBadge extends StatelessWidget {
  final String label;
  const PbBadge({this.label = 'PR', super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFFFE082), width: 0.5),
        ),
        child: Text(
          '🏆 $label',
          style: AppTypography.caption.copyWith(
            fontSize: 10,
            color: const Color(0xFF8D6E00),
            letterSpacing: 0.2,
          ),
        ),
      );
}
