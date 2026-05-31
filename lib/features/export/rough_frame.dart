import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/exercise.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/unit_converter.dart';

class RoughFrame extends StatelessWidget {
  final Exercise exercise;
  final double valueInMetric;
  final String weightUnit;
  final String distanceUnit;
  final DateTime date;

  const RoughFrame({
    required this.exercise,
    required this.valueInMetric,
    required this.weightUnit,
    required this.distanceUnit,
    required this.date,
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
        color: const Color(0xFF111111),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -20,
              child: Text(
                'PR',
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF1D1D1D),
                  fontSize: 200,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        color: AppTheme.accent,
                        child: Text(
                          'PBPR',
                          style: GoogleFonts.spaceGrotesk(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2),
                        ),
                      ),
                      Text(
                        'NEW PR',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 2,
                    color: AppTheme.accent,
                    margin: const EdgeInsets.only(bottom: 10),
                  ),
                  Text(
                    '// ${exercise.name.toUpperCase()}',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      displayValue,
                      style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.textPrimary,
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateStr,
                    style: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 10,
                        fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue() {
    switch (exercise.type) {
      case ExerciseType.weight:
        return UnitConverter.formatWeight(valueInMetric, weightUnit);
      case ExerciseType.time:
        return UnitConverter.secondsToDisplay(valueInMetric.toInt());
      case ExerciseType.distance:
        return UnitConverter.formatDistance(valueInMetric, distanceUnit);
    }
  }
}
