import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import 'export_models.dart';

// ── Public API ────────────────────────────────────────────────

Future<Uint8List> renderFrameToBytes({
  required FrameStyle style,
  required ExportAspectRatio aspectRatio,
  required String exerciseName,
  required String prValue,
  required String dateStr,
  required String daysSinceStr,
  required OverlayOptions options,
  String badgeLabel = 'PR',
  String personalBestLabel = 'Personal Best',
  bool overlayOnly = false,
  bool showPrBadge = true,
}) async {
  final size = aspectRatio.exportSize;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, size.width, size.height),
  );

  final data = _FrameData(
    exerciseName: exerciseName,
    prValue: prValue,
    dateStr: dateStr,
    daysSinceStr: daysSinceStr,
    options: options,
    badgeLabel: badgeLabel,
    personalBestLabel: personalBestLabel,
    overlayOnly: overlayOnly,
    showPrBadge: showPrBadge,
  );

  if (style == FrameStyle.clean) {
    _paintClean(canvas, size, data);
  } else {
    _paintRough(canvas, size, data);
  }

  final picture = recorder.endRecording();
  final image =
      await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

// ── Internal ──────────────────────────────────────────────────

class _FrameData {
  final String exerciseName;
  final String prValue;
  final String dateStr;
  final String daysSinceStr;
  final OverlayOptions options;
  final String badgeLabel;
  final String personalBestLabel;
  final bool overlayOnly;
  final bool showPrBadge;

  const _FrameData({
    required this.exerciseName,
    required this.prValue,
    required this.dateStr,
    required this.daysSinceStr,
    required this.options,
    this.badgeLabel = 'PR',
    this.personalBestLabel = 'Personal Best',
    required this.overlayOnly,
    this.showPrBadge = true,
  });
}

void _paintClean(Canvas canvas, ui.Size size, _FrameData d) {
  final w = size.width;
  final h = size.height;
  final pad = w * 0.074;
  const accent = Color(0xFFFF9500);

  if (!d.overlayOnly) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = AppColors.background,
    );
  }

  _text(canvas, 'PeakLog',
      x: pad, y: pad,
      size: w * 0.038, weight: FontWeight.w900,
      color: accent, spacing: w * 0.006);

  if (d.showPrBadge) {
    _text(canvas, 'NEW ${d.badgeLabel}',
        x: w - pad - w * 0.18, y: pad * 1.05,
        size: w * 0.024, weight: FontWeight.w700,
        color: const Color(0xFF333333), spacing: w * 0.004);
  }

  final midY = h * 0.58;

  if (d.options.showName) {
    _text(canvas, d.exerciseName.toUpperCase(),
        x: pad, y: midY,
        size: w * 0.030, weight: FontWeight.w700,
        color: const Color(0xFF444444), spacing: w * 0.007);
  }

  if (d.options.showValue) {
    _text(canvas, d.prValue,
        x: pad, y: midY + w * 0.038,
        size: w * 0.155, weight: FontWeight.w900,
        color: const Color(0xFF000000), spacing: -w * 0.003);
  }

  if (d.options.showDaysSince && d.daysSinceStr.isNotEmpty) {
    _text(canvas, d.daysSinceStr,
        x: pad, y: midY + w * 0.038 + w * 0.165,
        size: w * 0.030, weight: FontWeight.w700,
        color: accent, spacing: 0);
  }

  if (d.showPrBadge) {
    final barY = h * 0.83;
    canvas.drawRect(
      Rect.fromLTWH(pad, barY, w * 0.011, w * 0.042),
      Paint()..color = accent,
    );
    _text(canvas, d.personalBestLabel,
        x: pad + w * 0.018, y: barY + w * 0.006,
        size: w * 0.022, weight: FontWeight.w700,
        color: accent, spacing: w * 0.002);
  }

  if (d.options.showDate) {
    _text(canvas, d.dateStr,
        x: pad, y: h - pad * 1.4,
        size: w * 0.019, color: const Color(0xFF333333));
  }
}

void _paintRough(Canvas canvas, ui.Size size, _FrameData d) {
  final w = size.width;
  final h = size.height;
  final pad = w * 0.074;
  const accent = Color(0xFFFF9500);

  if (!d.overlayOnly) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF111111),
    );
    if (d.showPrBadge) {
      _text(canvas, d.badgeLabel,
          x: w * 0.4, y: -h * 0.06,
          size: w * 0.83, weight: FontWeight.w900,
          color: const Color(0xFF1D1D1D));
    }
  }

  final boxW = w * 0.17;
  final boxH = w * 0.050;
  canvas.drawRect(
    Rect.fromLTWH(pad, pad, boxW, boxH),
    Paint()..color = accent,
  );
  _text(canvas, 'PeakLog',
      x: pad + w * 0.015, y: pad + w * 0.008,
      size: w * 0.026, weight: FontWeight.w900,
      color: Colors.black, spacing: w * 0.003);

  if (d.showPrBadge) {
    _text(canvas, 'NEW ${d.badgeLabel}',
        x: w - pad - w * 0.17, y: pad * 1.05,
        size: w * 0.022, weight: FontWeight.w700,
        color: accent, spacing: w * 0.003);
  }

  final midY = h * 0.58;

  canvas.drawRect(
    Rect.fromLTWH(pad, midY - w * 0.04, w * 0.074, w * 0.006),
    Paint()..color = accent,
  );

  if (d.options.showName) {
    _text(canvas, '// ${d.exerciseName.toUpperCase()}',
        x: pad, y: midY - w * 0.022,
        size: w * 0.026, weight: FontWeight.w900,
        color: accent, spacing: w * 0.004);
  }

  if (d.options.showValue) {
    _text(canvas, d.prValue,
        x: pad, y: midY,
        size: w * 0.145, weight: FontWeight.w900,
        color: Colors.white, spacing: -w * 0.002);
  }

  if (d.options.showDaysSince && d.daysSinceStr.isNotEmpty) {
    _text(canvas, d.daysSinceStr,
        x: pad, y: midY + w * 0.155,
        size: w * 0.030, weight: FontWeight.w700,
        color: accent, spacing: 0);
  }

  if (d.options.showDate) {
    _text(canvas, d.dateStr,
        x: pad, y: h - pad * 1.4,
        size: w * 0.018, color: const Color(0xFF555555));
  }
}

void _text(
  Canvas canvas,
  String text, {
  required double x,
  required double y,
  required double size,
  FontWeight weight = FontWeight.w400,
  Color color = Colors.black,
  double spacing = 0,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  painter.layout();
  painter.paint(canvas, Offset(x, y));
}
