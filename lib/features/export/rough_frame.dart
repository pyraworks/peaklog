import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'export_models.dart';

/// See CleanFrame's doc — same already-formatted-strings design so this
/// frame style can present either a workout PR/activity or a Note.
class RoughFrame extends StatelessWidget {
  final String titleText;
  final String valueText;
  final String badgeLabel;
  final DateTime date;
  final String daysSinceStr;
  final OverlayOptions options;
  final bool showPrBadge;

  const RoughFrame({
    required this.titleText,
    required this.valueText,
    required this.badgeLabel,
    required this.date,
    this.daysSinceStr = '',
    this.options = const OverlayOptions(),
    this.showPrBadge = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    const accent = Color(0xFFFF9500);

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final pad = w * 0.074;

          return Container(
            color: const Color(0xFF111111),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                if (showPrBadge)
                  Positioned(
                    right: -w * 0.037,
                    top: -h * 0.060,
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        color: const Color(0xFF1D1D1D),
                        fontSize: w * 0.83,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(pad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: w * 0.015, vertical: w * 0.008),
                            color: accent,
                            child: Text(
                              'PeakLog',
                              style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  color: Colors.black,
                                  fontSize: w * 0.026,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: w * 0.003),
                            ),
                          ),
                          if (showPrBadge)
                            Text(
                              'NEW $badgeLabel',
                              style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  color: accent,
                                  fontSize: w * 0.022,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: w * 0.003),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: w * 0.074,
                        height: w * 0.006,
                        color: accent,
                        margin: EdgeInsets.only(bottom: w * 0.025),
                      ),
                      if (options.showName)
                        Text(
                          '// ${titleText.toUpperCase()}',
                          style: TextStyle(
                              fontFamily: 'Pretendard',
                              color: accent,
                              fontSize: w * 0.026,
                              fontWeight: FontWeight.w800,
                              letterSpacing: w * 0.004),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      if (options.showValue) ...[
                        SizedBox(height: w * 0.020),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            valueText,
                            style: TextStyle(
                                fontFamily: 'Pretendard',
                                color: AppTheme.textPrimary,
                                fontSize: w * 0.145,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -w * 0.002),
                          ),
                        ),
                      ],
                      if (options.showDaysSince && daysSinceStr.isNotEmpty) ...[
                        SizedBox(height: w * 0.020),
                        Text(
                          daysSinceStr,
                          style: TextStyle(
                              fontFamily: 'Pretendard',
                              color: accent,
                              fontSize: w * 0.030,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                      const Spacer(),
                      if (options.showDate)
                        Text(
                          dateStr,
                          style: TextStyle(
                              fontFamily: 'Pretendard',
                              color: const Color(0xFF555555),
                              fontSize: w * 0.018),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
