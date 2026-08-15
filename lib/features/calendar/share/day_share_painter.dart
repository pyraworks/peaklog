import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../domain/models/category.dart';
import '../../export/export_models.dart';
import 'day_share_models.dart';

/// Renders a [DayShareData] to a PNG, entirely from data — no Calendar or
/// Day Detail widgets are built or captured, and no BuildContext/Riverpod
/// is used. Uses the same PictureRecorder → Canvas → toImage → PNG
/// technique as the existing per-record exporter (`frame_painter.dart`),
/// and reuses its exact 1080×1920 "story" canvas size via
/// [ExportAspectRatio]. All coordinates below are in that fixed export
/// pixel space — never Flutter logical/screen dimensions.
///
/// Layout is computed in passes so nothing can overlap: every element's
/// position is derived from the *measured* size of the elements before it
/// (via [TextPainter].layout), never from a guessed fixed offset. The
/// visual language (colors, radius, dot style, PR trophy, dividers, note
/// card style) mirrors the real Day Detail UI — see `exercise_record_row.dart`,
/// `category_color_indicator.dart`, and `_NoteCard` in `calendar_screen.dart`,
/// which this intentionally does not import (the renderer must stay
/// independent of Calendar/UI widgets) but whose exact metrics are
/// replicated here.
Future<Uint8List> renderDayShareToBytes(DayShareData data) async {
  final size = ExportAspectRatio.story.exportSize;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

  _DayShareLayout(size: size, data: data).paint(canvas);

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
const _cardRadius = 32.0;
const _rowHPad = 44.0;
const _rowVPad = 34.0;
const _dotSize = 28.0;
const _dotGap = 28.0;
const _minNameToValueGap = 24.0;
const _iconGap = 12.0;
const _setsGap = 14.0;
const _sectionGap = 32.0;
const _notePadH = 40.0;
const _notePadV = 32.0;
const _noteGap = 20.0;
const _noteTitleBodyGap = 12.0;
const _noteBodyMaxLines = 6;

class _DayShareLayout {
  final Size size;
  final DayShareData data;
  _DayShareLayout({required this.size, required this.data});

  double get _contentWidth => size.width - _contentPad * 2;

  void paint(Canvas canvas) {
    // The generated image uses PeakLog's existing app background — the
    // Capture/Save UI around it is pure white, so the image reads as a
    // distinct object against that white surrounding.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.background,
    );

    // Date is the primary top-level element — no wordmark/branding above it.
    // Starts at the Instagram Story safe-area top, not the canvas edge.
    var y = _topSafeY;
    final dateText = _layoutText(data.dateLabel,
        fontSize: 50, weight: FontWeight.w700, color: AppColors.label1, spacing: -0.4);
    dateText.paint(canvas, Offset(_contentPad, y));
    y += dateText.height + 32; // header region ends here — sections start below

    if (data.records.isNotEmpty) {
      final sectionTitle = _layoutText(data.recordsSectionLabel,
          fontSize: 28, weight: FontWeight.w600, color: AppColors.label2);
      sectionTitle.paint(canvas, Offset(_contentPad, y));
      y += sectionTitle.height + 16;
      y = _paintRecordsCard(canvas, top: y);
    }

    if (data.notes.isNotEmpty) {
      y += _sectionGap;
      final notesTitle = _layoutText(data.notesSectionLabel,
          fontSize: 28, weight: FontWeight.w600, color: AppColors.label2);
      notesTitle.paint(canvas, Offset(_contentPad, y));
      y += notesTitle.height + 16;
      _paintNotes(canvas, top: y);
    }
  }

  // ── Records ────────────────────────────────────────────────────────────

  /// Returns the Y position immediately below the painted card (or [top]
  /// unchanged if nothing fit/there was nothing to paint).
  double _paintRecordsCard(Canvas canvas, {required double top}) {
    // Pass 1: measure every row without painting, so the card's total
    // height — and therefore its background rect — is known up front.
    final rows = <_MeasuredRow>[];
    var contentHeight = 0.0;
    for (final record in data.records) {
      final row = _measureRow(record);
      final rowTotalHeight = row.contentHeight + _rowVPad * 2;
      if (top + contentHeight + rowTotalHeight > _bottomSafeY) {
        // Stop rather than overflow the canvas or push the last row past
        // the safe bottom margin. No overlap beats no pagination for a
        // single static image.
        break;
      }
      rows.add(row);
      contentHeight += rowTotalHeight;
    }
    if (rows.isEmpty) return top;

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(_contentPad, top, _contentWidth, contentHeight),
      const Radius.circular(_cardRadius),
    );
    canvas.drawRRect(cardRect, Paint()..color = AppColors.card);
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = AppColors.separator
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Pass 2: paint each row at its accumulated Y, plus a divider between
    // (not after) rows — identical to Day Detail's own record list.
    var rowTop = top;
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        canvas.drawLine(
          Offset(_contentPad, rowTop),
          Offset(_contentPad + _contentWidth, rowTop),
          Paint()
            ..color = AppColors.separator
            ..strokeWidth = 1.5,
        );
      }
      _paintRow(canvas, rows[i], top: rowTop);
      rowTop += rows[i].contentHeight + _rowVPad * 2;
    }
    return top + contentHeight;
  }

  _MeasuredRow _measureRow(DayShareRecord record) {
    final valueColor = record.isPr ? AppColors.label1 : AppColors.label2;
    final valueWeight = record.isPr ? FontWeight.w500 : FontWeight.w400;

    final value = _layoutText(record.valueLabel,
        fontSize: 38, weight: valueWeight, color: valueColor);
    final sets = record.setsLabel != null
        ? _layoutText(record.setsLabel!, fontSize: 26, weight: FontWeight.w500, color: AppColors.label2)
        : null;

    // Width of the right-aligned [trophy?] [value] [sets?] block.
    var valueBlockWidth = value.width;
    var valueBlockHeight = value.height;
    if (record.isPr) {
      valueBlockWidth += _trophySize + _iconGap;
      valueBlockHeight = valueBlockHeight > _trophySize ? valueBlockHeight : _trophySize;
    }
    if (sets != null) {
      valueBlockWidth += _setsGap + sets.width;
      valueBlockHeight = valueBlockHeight > sets.height ? valueBlockHeight : sets.height;
    }

    // Name gets whatever width remains after the dot, gaps, and the
    // value block — guaranteeing it can never collide with the value
    // block, however long the exercise name is.
    final nameMaxWidth = _contentWidth -
        _rowHPad * 2 -
        _dotSize -
        _dotGap -
        _minNameToValueGap -
        valueBlockWidth;
    final name = _layoutText(record.exerciseName,
        fontSize: 40, weight: FontWeight.w500, color: AppColors.label1,
        maxWidth: nameMaxWidth < 0 ? 0 : nameMaxWidth);

    final contentHeight = name.height > valueBlockHeight ? name.height : valueBlockHeight;
    return _MeasuredRow(
      record: record,
      name: name,
      value: value,
      sets: sets,
      valueBlockWidth: valueBlockWidth,
      contentHeight: contentHeight,
    );
  }

  void _paintRow(Canvas canvas, _MeasuredRow row, {required double top}) {
    final centerY = top + _rowVPad + row.contentHeight / 2;
    const rowLeft = _contentPad + _rowHPad;
    final rowRight = _contentPad + _contentWidth - _rowHPad;

    // Category dot — soft tinted outer circle + solid inner dot, matching
    // CategoryColorIndicator exactly (innerSize = size * 0.4).
    final dotColor = CategoryColor.toColor(row.record.categoryColorKey);
    final dotCenter = Offset(rowLeft + _dotSize / 2, centerY);
    canvas.drawCircle(dotCenter, _dotSize / 2, Paint()..color = dotColor.withValues(alpha: 0.18));
    canvas.drawCircle(dotCenter, _dotSize * 0.4 / 2, Paint()..color = dotColor);

    // Name — vertically centered within the row's content band.
    const nameX = rowLeft + _dotSize + _dotGap;
    row.name.paint(canvas, Offset(nameX, centerY - row.name.height / 2));

    // Value block — right-aligned, [trophy?] [value] [sets?].
    var x = rowRight - row.valueBlockWidth;
    if (row.record.isPr) {
      _paintIcon(canvas, AppIcons.trophy,
          x: x, y: centerY - _trophySize / 2, size: _trophySize, color: AppColors.pbGold);
      x += _trophySize + _iconGap;
    }
    row.value.paint(canvas, Offset(x, centerY - row.value.height / 2));
    x += row.value.width;
    if (row.sets != null) {
      x += _setsGap;
      row.sets!.paint(canvas, Offset(x, centerY - row.sets!.height / 2));
    }
  }

  // ── Notes ──────────────────────────────────────────────────────────────

  void _paintNotes(Canvas canvas, {required double top}) {
    var y = top;
    final innerWidth = _contentWidth - _notePadH * 2;
    for (final note in data.notes) {
      final hasTitle = note.title.isNotEmpty;
      final hasBody = note.body.isNotEmpty;
      if (!hasTitle && !hasBody) continue;

      final title = hasTitle
          ? _layoutText(note.title,
              fontSize: 38, weight: FontWeight.w600, color: AppColors.label1,
              spacing: -0.4, maxWidth: innerWidth)
          : null;
      final body = hasBody
          ? _layoutText(note.body,
              fontSize: 34, weight: FontWeight.w400, color: AppColors.label2,
              maxWidth: innerWidth, maxLines: _noteBodyMaxLines, lineHeight: 1.55)
          : null;

      var contentHeight = 0.0;
      if (title != null) contentHeight += title.height;
      if (title != null && body != null) contentHeight += _noteTitleBodyGap;
      if (body != null) contentHeight += body.height;

      final cardHeight = contentHeight + _notePadV * 2;
      if (y + cardHeight > _bottomSafeY) break; // Instagram Story safe-area bottom

      final cardRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(_contentPad, y, _contentWidth, cardHeight),
        const Radius.circular(_cardRadius),
      );
      canvas.drawRRect(cardRect, Paint()..color = AppColors.card);
      canvas.drawRRect(
        cardRect,
        Paint()
          ..color = AppColors.separator
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      var innerY = y + _notePadV;
      const innerX = _contentPad + _notePadH;
      if (title != null) {
        title.paint(canvas, Offset(innerX, innerY));
        innerY += title.height + _noteTitleBodyGap;
      }
      if (body != null) {
        body.paint(canvas, Offset(innerX, innerY));
      }

      y += cardHeight + _noteGap;
    }
  }

  TextPainter _layoutText(
    String text, {
    required double fontSize,
    required FontWeight weight,
    required Color color,
    double spacing = 0,
    double maxWidth = double.infinity,
    int maxLines = 1,
    double? lineHeight,
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
          height: lineHeight,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    );
    painter.layout(maxWidth: maxWidth);
    return painter;
  }
}

const _trophySize = 34.0;

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

class _MeasuredRow {
  final DayShareRecord record;
  final TextPainter name;
  final TextPainter value;
  final TextPainter? sets;
  final double valueBlockWidth;
  final double contentHeight;

  _MeasuredRow({
    required this.record,
    required this.name,
    required this.value,
    required this.sets,
    required this.valueBlockWidth,
    required this.contentHeight,
  });
}
