import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../domain/models/category.dart';
import '../../export/export_models.dart';
import 'month_share_models.dart';

/// Renders a [MonthShareData] to a PNG, entirely from data — no Calendar
/// widgets are built or captured, no BuildContext/Riverpod is used. Same
/// PictureRecorder → Canvas → toImage → PNG technique and 1080×1920
/// "story" canvas size as the daily painter (`day_share_painter.dart`).
///
/// Grid cell visuals mirror the real Calendar grid — see `_CalendarCell`
/// and `_CategoryDots` in `calendar_screen.dart` — but every cell has a
/// fixed slot in a uniform grid, so rows/cells can never overlap by
/// construction; nothing here depends on Flutter widget layout.
Future<Uint8List> renderMonthShareToBytes(MonthShareData data) async {
  final size = ExportAspectRatio.story.exportSize;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

  _MonthShareLayout(size: size, data: data).paint(canvas);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

// ── Layout constants (export pixel space) ──────────────────────────────
const _contentPad = 64.0;
// Instagram Story overlays (profile header, reply bar) sit outside this
// vertical band — content must stay within it. Top pulled up ~80px from
// the previous 280 so content doesn't start with excessive empty space.
const _topSafeY = 200.0;
const _bottomSafeY = 1650.0;
const _maxRows = 6; // grid is always sized for the worst case → never overflows
// Grid intentionally uses less than the full available span (rather than
// stretching to fill it) so rows read as compact/intentional, not padded,
// and so there's always room left below for the category legend — the
// remaining space is left blank, which is fine for shorter months.
const _cellHeightScale = 0.85;
const _cellTopPad = 8.0; // gap from a cell's top to its day-number circle
const _dayCircleSize = 64.0;
const _weekdayFontSize = 28.5; // ~9.6% larger than the previous 26
const _dateNumberFontSize = 32.5; // ~8.3% larger than the previous 30
const _legendFontSize = 30.5; // ~8.9% larger than the previous 28
// Single shared size for every category dot — grid activity dots and
// legend dots are the same indicator system, so they're the same size.
const _dotSize = 10.0;
const _dotGap = 4.0;
const _dotsBelowCircleGap = 10.0; // gap from the day circle to its dots row
const _trophySize = 26.0;
const _summaryTrophySize = 28.0; // inline trophy between workout-day/PR text
const _summaryTrophyGap = 8.0;
const _legendDotGap = 10.0;
const _legendItemGap = 24.0;
const _legendLineGap = 16.0;
// Thin outline around the weekday row + grid only (not the legend) —
// same color/stroke-width/radius language as the Daily Share record card
// border (day_share_painter.dart's _cardRect). Filled white so the
// calendar reads as a distinct surface against the gray Story background.
const _outlineRadius = 32.0;
const _outlineStrokeWidth = 1.5;
const _outlinePad = 36.0; // internal padding on all 4 sides of the outline
// Shared external gap on both sides of the calendar outline — summary→outline
// and outline→legend use the exact same value so the composition reads with
// one consistent vertical rhythm rather than two different-sized gaps.
const _calendarExternalGap = 56.0;
const _weekdayToGridGap = 24.0;

class _MonthShareLayout {
  final Size size;
  final MonthShareData data;
  _MonthShareLayout({required this.size, required this.data});

  double get _contentWidth => size.width - _contentPad * 2;

  void paint(Canvas canvas) {
    // The generated image uses PeakLog's existing app background — the
    // Capture/Save UI around it is pure white, so the image reads as a
    // distinct object against that white surrounding.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.background,
    );

    var y = _topSafeY;

    final monthText = _layoutText(data.monthLabel,
        fontSize: 56, weight: FontWeight.w700, color: AppColors.label1, spacing: -0.4);
    monthText.paint(canvas, Offset(_contentPad, y));
    y += monthText.height + 12;

    // With activity, this is workout-days + the existing PR trophy icon +
    // PR count (matching the on-screen summary); with none, Calendar's
    // existing "no workouts" message alone.
    if (data.workoutDaysLabel != null && data.prCountLabel != null) {
      final workoutDaysText = _layoutText(data.workoutDaysLabel!,
          fontSize: 32, weight: FontWeight.w600, color: AppColors.label2);
      workoutDaysText.paint(canvas, Offset(_contentPad, y));
      var summaryX = _contentPad + workoutDaysText.width + _summaryTrophyGap;

      final trophyY = y + (workoutDaysText.height - _summaryTrophySize) / 2;
      _paintIcon(canvas, AppIcons.trophy,
          x: summaryX, y: trophyY, size: _summaryTrophySize, color: AppColors.pbGold);
      summaryX += _summaryTrophySize + _summaryTrophyGap;

      final prCountText = _layoutText(data.prCountLabel!,
          fontSize: 32, weight: FontWeight.w600, color: AppColors.label2);
      prCountText.paint(canvas, Offset(summaryX, y));

      y += workoutDaysText.height;
    } else {
      final countText = _layoutText(data.countLabel,
          fontSize: 32, weight: FontWeight.w600, color: AppColors.label2);
      countText.paint(canvas, Offset(_contentPad, y));
      y += countText.height;
    }

    // The calendar (weekday row + grid) is grouped by a thin outline, with
    // its own internal padding — the legend sits outside/below it, using
    // the same _calendarExternalGap as the summary-to-outline gap above.
    final weekdayY = y + _calendarExternalGap + _outlinePad;
    final colWidth = _contentWidth / 7;
    // Weekday label painters are measured up front (rather than a hardcoded
    // row height) so the grid's vertical position always tracks the actual
    // rendered text size, including the larger _weekdayFontSize below.
    final weekdayLabels = [
      for (var col = 0; col < 7; col++)
        _layoutText(data.weekdayLabels[col],
            fontSize: _weekdayFontSize, weight: FontWeight.w600, color: AppColors.label4),
    ];
    final weekdayLabelHeight =
        weekdayLabels.map((p) => p.height).reduce((a, b) => a > b ? a : b);
    final gridTop = weekdayY + weekdayLabelHeight + _weekdayToGridGap;

    final cellHeight = (_bottomSafeY - gridTop) / _maxRows * _cellHeightScale;
    final rowCount = data.cells.length ~/ 7;
    final lastRowTop = gridTop + (rowCount - 1) * cellHeight;
    final lastRowContentBottom =
        lastRowTop + _cellTopPad + _dayCircleSize + _dotsBelowCircleGap + _dotSize;

    final outlineRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        _contentPad - _outlinePad,
        weekdayY - _outlinePad,
        _contentPad + _contentWidth + _outlinePad,
        lastRowContentBottom + _outlinePad,
      ),
      const Radius.circular(_outlineRadius),
    );
    canvas.drawRRect(outlineRect, Paint()..color = AppColors.card);
    canvas.drawRRect(
      outlineRect,
      Paint()
        ..color = AppColors.separator
        ..style = PaintingStyle.stroke
        ..strokeWidth = _outlineStrokeWidth,
    );

    for (var col = 0; col < 7; col++) {
      final label = weekdayLabels[col];
      label.paint(
        canvas,
        Offset(_contentPad + col * colWidth + (colWidth - label.width) / 2, weekdayY),
      );
    }

    for (var row = 0; row < rowCount; row++) {
      final rowTop = gridTop + row * cellHeight;
      for (var col = 0; col < 7; col++) {
        final cell = data.cells[row * 7 + col];
        if (cell.day == null) continue;
        _paintCell(
          canvas,
          cell,
          x: _contentPad + col * colWidth,
          y: rowTop,
          width: colWidth,
          height: cellHeight,
        );
      }
    }

    if (data.usedCategories.isNotEmpty || data.noteLegendLabel != null) {
      // _contentPad is the exact x the summary text (workoutDaysText/
      // countText above) is painted at, so the legend's first dot lines up
      // with the left edge of "1일 운동" rather than the grid's day-circle
      // inset. Measured from the outline's own bottom edge, not the raw
      // grid content, so the legend reads as a caption below the outline,
      // not crowding it.
      final outlineBottom = lastRowContentBottom + _outlinePad;
      _paintLegend(canvas,
          top: outlineBottom + _calendarExternalGap, startX: _contentPad);
    }
  }

  // ── Legend ─────────────────────────────────────────────────────────────

  /// Small "marker + name" legend, wrapped across lines as needed. Stops
  /// before crossing the bottom safe boundary rather than overlapping or
  /// overflowing — the calendar above is never shrunk to make room here.
  /// [startX] is the summary text's own left edge (see the caller), so the
  /// first marker aligns exactly with "1일 운동".
  ///
  /// Category entries (circular dots, existing behavior) and the optional
  /// Note entry (a rounded square, same marker language as the on-screen
  /// Calendar's Note indicator — never a circle, so it's never mistaken
  /// for a category regardless of color) share one combined, ordered list
  /// so they wrap together using the exact same line-break logic — the
  /// Note entry itself is never added to [MonthShareData.usedCategories].
  void _paintLegend(Canvas canvas, {required double top, required double startX}) {
    final entries = <({String label, void Function(Offset center) paintMarker})>[
      for (final category in data.usedCategories)
        (
          label: category.name,
          paintMarker: (center) => canvas.drawCircle(
            center,
            _dotSize / 2,
            Paint()..color = CategoryColor.toColor(category.colorKey),
          ),
        ),
      if (data.noteLegendLabel != null)
        (
          label: data.noteLegendLabel!,
          paintMarker: (center) => canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: center, width: _dotSize, height: _dotSize),
              const Radius.circular(_dotSize * 0.3),
            ),
            Paint()..color = AppColors.label1,
          ),
        ),
    ];

    var x = startX;
    var lineY = top;
    var lineHeight = 0.0;

    for (final entry in entries) {
      final label = _layoutText(entry.label,
          fontSize: _legendFontSize, weight: FontWeight.w500, color: AppColors.label2);
      final itemWidth = _dotSize + _legendDotGap + label.width;
      final itemHeight = label.height > _dotSize ? label.height : _dotSize;

      final isFirstOnLine = x == startX;
      if (!isFirstOnLine && x + itemWidth > _contentPad + _contentWidth) {
        // Wrap to a new line.
        lineY += lineHeight + _legendLineGap;
        x = startX;
        lineHeight = 0.0;
      }
      if (lineY + itemHeight > _bottomSafeY) break; // never cross the safe boundary

      final markerCenterY = lineY + itemHeight / 2;
      entry.paintMarker(Offset(x + _dotSize / 2, markerCenterY));
      label.paint(
          canvas, Offset(x + _dotSize + _legendDotGap, lineY + (itemHeight - label.height) / 2));

      x += itemWidth + _legendItemGap;
      lineHeight = lineHeight > itemHeight ? lineHeight : itemHeight;
    }
  }

  void _paintCell(
    Canvas canvas,
    MonthShareCell cell, {
    required double x,
    required double y,
    required double width,
    required double height,
  }) {
    final centerX = x + width / 2;
    final circleTop = y + _cellTopPad;

    final dayLabel = _layoutText('${cell.day}',
        fontSize: _dateNumberFontSize, weight: FontWeight.w500, color: AppColors.label1);
    dayLabel.paint(
      canvas,
      Offset(centerX - dayLabel.width / 2, circleTop + (_dayCircleSize - dayLabel.height) / 2),
    );

    // Category dots and the Note marker share one centered row, dots
    // first then Note last — same relative order as the on-screen grid's
    // CalendarCategoryDots. Note is independent of category count: it's
    // never one of the (max 4) dots, never affects how many dots are
    // shown, and renders even when categoryColorKeys is empty (a Note
    // used as a workout-completed marker with no Record).
    if (cell.categoryColorKeys.isNotEmpty || cell.hasNote) {
      final dots = cell.categoryColorKeys.take(4).toList();
      final markerCount = dots.length + (cell.hasNote ? 1 : 0);
      final rowWidth = markerCount * _dotSize + (markerCount - 1) * _dotGap;
      var markerX = centerX - rowWidth / 2;
      final markerY = circleTop + _dayCircleSize + _dotsBelowCircleGap;
      for (final key in dots) {
        canvas.drawCircle(
          Offset(markerX + _dotSize / 2, markerY + _dotSize / 2),
          _dotSize / 2,
          Paint()..color = CategoryColor.toColor(key),
        );
        markerX += _dotSize + _dotGap;
      }
      if (cell.hasNote) {
        // Same rounded-square/AppColors.label1 marker language as the
        // on-screen date indicator and the legend's Note entry — never a
        // circle, so it can't be mistaken for a category dot.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(markerX, markerY, _dotSize, _dotSize),
            const Radius.circular(_dotSize * 0.3),
          ),
          Paint()..color = AppColors.label1,
        );
      }
    }

    if (cell.hasPr) {
      _paintIcon(canvas, AppIcons.trophy,
          x: x + width - _trophySize - 6, y: y + 2,
          size: _trophySize, color: AppColors.pbGold);
    }
  }

  TextPainter _layoutText(
    String text, {
    required double fontSize,
    required FontWeight weight,
    required Color color,
    double spacing = 0,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          letterSpacing: spacing,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    painter.layout();
    return painter;
  }
}

void _paintIcon(
  Canvas canvas,
  IconData icon, {
  required double x,
  required double y,
  required double size,
  required Color color,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  painter.layout();
  painter.paint(canvas, Offset(x, y));
}
