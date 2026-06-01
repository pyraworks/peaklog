import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/exercise.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/unit_converter.dart';
import 'export_models.dart';

class CleanFrame extends StatelessWidget {
  final Exercise exercise;
  final double valueInMetric;
  final String weightUnit;
  final String distanceUnit;
  final DateTime date;
  final String daysSinceStr;
  final OverlayOptions options;

  const CleanFrame({
    required this.exercise,
    required this.valueInMetric,
    required this.weightUnit,
    required this.distanceUnit,
    required this.date,
    this.daysSinceStr = '',
    this.options = const OverlayOptions(),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = _formatValue();
    final dateStr =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        color: AppTheme.background,
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PBPR',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4)),
                Text('NEW PR',
                    style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFF333333),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
              ],
            ),
            const Spacer(),
            if (options.showName)
              Text(
                exercise.displayName.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFF444444),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3),
              ),
            if (options.showPr) ...[
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  displayValue,
                  style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.textPrimary,
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2),
                ),
              ),
            ],
            if (options.showDaysSince && daysSinceStr.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                daysSinceStr,
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Container(width: 4, height: 16, color: AppTheme.accent),
                const SizedBox(width: 8),
                Text(
                  '개인 최고 기록',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (options.showDate)
                  Text(
                    dateStr,
                    style: const TextStyle(
                        color: Color(0xFF333333), fontSize: 11),
                  ),
                Container(width: 32, height: 2, color: AppTheme.accent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue() {
    switch (exercise.category) {
      case ExerciseCategory.strength:
        return UnitConverter.formatWeight(valueInMetric, weightUnit);
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        return UnitConverter.secondsToDisplay(valueInMetric.toInt());
      case ExerciseCategory.custom:
        return valueInMetric.toStringAsFixed(1);
    }
  }
}
