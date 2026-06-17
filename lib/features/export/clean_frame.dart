import 'package:flutter/material.dart';
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
  final bool showPrBadge;

  const CleanFrame({
    required this.exercise,
    required this.valueInMetric,
    required this.weightUnit,
    required this.distanceUnit,
    required this.date,
    this.daysSinceStr = '',
    this.options = const OverlayOptions(),
    this.showPrBadge = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = _formatValue();
    final dateStr =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    const accent = Color(0xFFFF9500);

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final pad = w * 0.074;

          return Container(
            color: AppTheme.background,
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PeakLog',
                        style: TextStyle(
                            fontFamily: 'Pretendard',
                            color: accent,
                            fontSize: w * 0.038,
                            fontWeight: FontWeight.w800,
                            letterSpacing: w * 0.006)),
                    if (showPrBadge)
                      Text('NEW ${exercise.bestTypeLabel}',
                          style: TextStyle(
                              fontFamily: 'Pretendard',
                              color: const Color(0xFF333333),
                              fontSize: w * 0.024,
                              fontWeight: FontWeight.w700,
                              letterSpacing: w * 0.004)),
                  ],
                ),
                const Spacer(),
                if (options.showName)
                  Text(
                    exercise.displayName.toUpperCase(),
                    style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: const Color(0xFF444444),
                        fontSize: w * 0.030,
                        fontWeight: FontWeight.w700,
                        letterSpacing: w * 0.007),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                if (options.showValue) ...[
                  SizedBox(height: w * 0.020),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      displayValue,
                      style: TextStyle(
                          fontFamily: 'Pretendard',
                          color: AppTheme.textPrimary,
                          fontSize: w * 0.155,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -w * 0.003),
                    ),
                  ),
                ],
                if (options.showDaysSince && daysSinceStr.isNotEmpty) ...[
                  SizedBox(height: w * 0.015),
                  Text(
                    daysSinceStr,
                    style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: accent,
                        fontSize: w * 0.030,
                        fontWeight: FontWeight.w700),
                  ),
                ],
                SizedBox(height: w * 0.030),
                if (showPrBadge)
                  Row(
                    children: [
                      Container(
                          width: w * 0.011, height: w * 0.042, color: accent),
                      SizedBox(width: w * 0.018),
                      Text(
                        '개인 최고 기록',
                        style: TextStyle(
                            fontFamily: 'Pretendard',
                            color: accent,
                            fontSize: w * 0.022,
                            fontWeight: FontWeight.w700,
                            letterSpacing: w * 0.002),
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
                        style: TextStyle(
                            color: const Color(0xFF333333),
                            fontSize: w * 0.019),
                      ),
                    Container(
                        width: w * 0.118, height: w * 0.007, color: accent),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatValue() {
    switch (exercise.recordType!) {
      case RecordType.weight:
        return UnitConverter.formatWeight(valueInMetric, weightUnit);
      case RecordType.etc:
        return UnitConverter.formatEtc(valueInMetric, distanceUnit);
      case RecordType.forTime:
      case RecordType.amrap:
        return UnitConverter.secondsToDisplay(valueInMetric.toInt());
    }
  }
}
