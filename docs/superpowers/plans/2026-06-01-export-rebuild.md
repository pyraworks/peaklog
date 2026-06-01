# Export / Share Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild ExportScreen with aspect ratio selector, media picker, overlay data toggles, Canvas-based image export (no RepaintBoundary), ffmpeg video export, and gallery save.

**Architecture:** Export rendering is split: widget-based CleanFrame/RoughFrame for live preview; `ui.PictureRecorder`+`CustomPainter` for actual image/overlay export (avoids RepaintBoundary entirely). For video, the PNG overlay is composited onto the user's video via ffmpeg. Frame widgets are refactored to accept `OverlayOptions`.

**Tech Stack:** Flutter, ffmpeg_kit_flutter_full_gpl, image_picker, gal, video_player, share_plus (already installed)

---

## File Map

| Action | File |
|--------|------|
| Modify | `pubspec.yaml` |
| Create | `lib/features/export/export_models.dart` |
| Create | `lib/features/export/frame_painter.dart` |
| Rewrite | `lib/features/export/clean_frame.dart` |
| Rewrite | `lib/features/export/rough_frame.dart` |
| Rewrite | `lib/features/export/export_screen.dart` |
| Modify  | `ios/Runner/Info.plist` |

---

### Task 1: Add dependencies

**Files:** `pubspec.yaml`

- [ ] Add under `dependencies:`:

```yaml
  ffmpeg_kit_flutter_full_gpl: 6.0.3
  image_picker: ^1.1.2
  gal: ^1.1.2
  video_player: ^2.9.2
```

- [ ] Run `flutter pub get` — expect `Got dependencies!`

- [ ] Commit:
```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add ffmpeg_kit, image_picker, gal, video_player for export rebuild"
```

---

### Task 2: Create export_models.dart

**Files:** Create `lib/features/export/export_models.dart`

- [ ] Create file:

```dart
import 'dart:ui';

enum ExportAspectRatio { square, portrait, story }

extension ExportAspectRatioX on ExportAspectRatio {
  String get label => const ['1:1', '4:5', '9:16'][index];

  double get ratio {
    switch (this) {
      case ExportAspectRatio.square:   return 1.0;
      case ExportAspectRatio.portrait: return 4.0 / 5.0;
      case ExportAspectRatio.story:    return 9.0 / 16.0;
    }
  }

  Size get exportSize {
    switch (this) {
      case ExportAspectRatio.square:   return const Size(1080, 1080);
      case ExportAspectRatio.portrait: return const Size(1080, 1350);
      case ExportAspectRatio.story:    return const Size(1080, 1920);
    }
  }
}

enum FrameStyle { clean, rough }

class OverlayOptions {
  final bool showName;
  final bool showPr;
  final bool showDate;
  final bool showDaysSince;

  const OverlayOptions({
    this.showName = true,
    this.showPr = true,
    this.showDate = true,
    this.showDaysSince = true,
  });

  OverlayOptions copyWith({
    bool? showName, bool? showPr, bool? showDate, bool? showDaysSince,
  }) => OverlayOptions(
    showName: showName ?? this.showName,
    showPr: showPr ?? this.showPr,
    showDate: showDate ?? this.showDate,
    showDaysSince: showDaysSince ?? this.showDaysSince,
  );
}
```

---

### Task 3: Create frame_painter.dart

**Files:** Create `lib/features/export/frame_painter.dart`

This file provides Canvas-based rendering for image export — no RepaintBoundary involved.

- [ ] Create file:

```dart
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'export_models.dart';

// ── Public API ─────────────────────────────────────────────────

Future<Uint8List> renderFrameToBytes({
  required FrameStyle style,
  required ExportAspectRatio aspectRatio,
  required String exerciseName,
  required String prValue,
  required String dateStr,
  required String daysSinceStr,
  required OverlayOptions options,
  bool overlayOnly = false, // transparent background for video compositing
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
    overlayOnly: overlayOnly,
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

// ── Internal ───────────────────────────────────────────────────

class _FrameData {
  final String exerciseName;
  final String prValue;
  final String dateStr;
  final String daysSinceStr;
  final OverlayOptions options;
  final bool overlayOnly;

  const _FrameData({
    required this.exerciseName, required this.prValue,
    required this.dateStr, required this.daysSinceStr,
    required this.options, required this.overlayOnly,
  });
}

void _paintClean(Canvas canvas, ui.Size size, _FrameData d) {
  final w = size.width;
  final h = size.height;
  final pad = w * 0.074;
  final accent = const Color(0xFFFF9500);

  if (!d.overlayOnly) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFFF2F2F7),
    );
  }

  // PBPR top-left
  _text(canvas, 'PBPR',
      x: pad, y: pad,
      size: w * 0.038, weight: FontWeight.w900,
      color: accent, spacing: w * 0.006);

  // NEW PR top-right
  _text(canvas, 'NEW PR',
      x: w - pad - w * 0.18, y: pad * 1.05,
      size: w * 0.024, weight: FontWeight.w700,
      color: const Color(0xFF333333), spacing: w * 0.004);

  final midY = h * 0.58;

  if (d.options.showName) {
    _text(canvas, d.exerciseName.toUpperCase(),
        x: pad, y: midY,
        size: w * 0.030, weight: FontWeight.w700,
        color: const Color(0xFF444444), spacing: w * 0.007);
  }

  if (d.options.showPr) {
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

  // Accent bar
  final barY = h * 0.83;
  canvas.drawRect(
    Rect.fromLTWH(pad, barY, w * 0.011, w * 0.042),
    Paint()..color = accent,
  );
  _text(canvas, '개인 최고 기록',
      x: pad + w * 0.018, y: barY + w * 0.006,
      size: w * 0.022, weight: FontWeight.w700,
      color: accent, spacing: w * 0.002);

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
  final accent = const Color(0xFFFF9500);

  if (!d.overlayOnly) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF111111),
    );
    // Background "PR" decoration
    _text(canvas, 'PR',
        x: w * 0.4, y: -h * 0.06,
        size: w * 0.83, weight: FontWeight.w900,
        color: const Color(0xFF1D1D1D));
  }

  // PBPR box top-left
  final boxW = w * 0.17;
  final boxH = w * 0.050;
  canvas.drawRect(
    Rect.fromLTWH(pad, pad, boxW, boxH),
    Paint()..color = accent,
  );
  _text(canvas, 'PBPR',
      x: pad + w * 0.015, y: pad + w * 0.008,
      size: w * 0.026, weight: FontWeight.w900,
      color: Colors.black, spacing: w * 0.003);

  // NEW PR top-right
  _text(canvas, 'NEW PR',
      x: w - pad - w * 0.17, y: pad * 1.05,
      size: w * 0.022, weight: FontWeight.w700,
      color: accent, spacing: w * 0.003);

  final midY = h * 0.58;

  // Accent line
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

  if (d.options.showPr) {
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
        size: w * 0.018,
        color: const Color(0xFF555555));
  }
}

void _text(
  Canvas canvas, String text, {
  required double x, required double y,
  required double size,
  FontWeight weight = FontWeight.w400,
  Color color = Colors.black,
  double spacing = 0,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: size, fontWeight: weight,
        color: color, letterSpacing: spacing,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  painter.layout();
  painter.paint(canvas, Offset(x, y));
}
```

---

### Task 4: Refactor CleanFrame + RoughFrame to accept OverlayOptions

**Files:** `lib/features/export/clean_frame.dart`, `lib/features/export/rough_frame.dart`

- [ ] Replace `clean_frame.dart`:

```dart
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
              Text(exercise.displayName.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                      color: const Color(0xFF444444),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3)),
            if (options.showPr) ...[
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(displayValue,
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.textPrimary,
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2)),
              ),
            ],
            if (options.showDaysSince && daysSinceStr.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(daysSinceStr,
                  style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Container(width: 4, height: 16, color: AppTheme.accent),
                const SizedBox(width: 8),
                Text('개인 최고 기록',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (options.showDate)
                  Text(dateStr,
                      style: const TextStyle(
                          color: Color(0xFF333333), fontSize: 11)),
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
```

- [ ] Replace `rough_frame.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/exercise.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/unit_converter.dart';
import 'export_models.dart';

class RoughFrame extends StatelessWidget {
  final Exercise exercise;
  final double valueInMetric;
  final String weightUnit;
  final String distanceUnit;
  final DateTime date;
  final String daysSinceStr;
  final OverlayOptions options;

  const RoughFrame({
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
        color: const Color(0xFF111111),
        child: Stack(
          children: [
            Positioned(
              right: -10, top: -20,
              child: Text('PR',
                  style: GoogleFonts.spaceGrotesk(
                      color: const Color(0xFF1D1D1D),
                      fontSize: 200,
                      fontWeight: FontWeight.w900)),
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
                        child: Text('PBPR',
                            style: GoogleFonts.spaceGrotesk(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2)),
                      ),
                      Text('NEW PR',
                          style: GoogleFonts.spaceGrotesk(
                              color: AppTheme.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                      width: 40, height: 2,
                      color: AppTheme.accent,
                      margin: const EdgeInsets.only(bottom: 10)),
                  if (options.showName)
                    Text('// ${exercise.displayName.toUpperCase()}',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2)),
                  if (options.showPr) ...[
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(displayValue,
                          style: GoogleFonts.spaceGrotesk(
                              color: AppTheme.textPrimary,
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1)),
                    ),
                  ],
                  if (options.showDaysSince && daysSinceStr.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(daysSinceStr,
                        style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ],
                  const Spacer(),
                  if (options.showDate)
                    Text(dateStr,
                        style: const TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 10,
                            fontFamily: 'monospace')),
                ],
              ),
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
```

---

### Task 5: Rewrite ExportScreen

**Files:** `lib/features/export/export_screen.dart`

- [ ] Replace entire file:

```dart
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../core/models/exercise.dart';
import '../../core/models/record.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/records_provider.dart';
import '../../providers/unit_settings_provider.dart';
import 'clean_frame.dart';
import 'export_models.dart';
import 'frame_painter.dart';
import 'rough_frame.dart';

class ExportScreen extends ConsumerStatefulWidget {
  final Exercise exercise;
  final double newValue;
  final DateTime date;

  const ExportScreen({
    required this.exercise,
    required this.newValue,
    required this.date,
    super.key,
  });

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportAspectRatio _aspectRatio = ExportAspectRatio.story;
  FrameStyle _frameStyle = FrameStyle.clean;
  OverlayOptions _overlay = const OverlayOptions();
  File? _mediaFile;
  bool _isVideo = false;
  VideoPlayerController? _videoCtrl;
  bool _exporting = false;
  String _exportLabel = '';

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(unitSettingsProvider).valueOrNull;
    final weightUnit = settings?.weightUnit ?? 'kg';
    final distanceUnit = settings?.distanceUnit ?? 'km';
    final records = ref.watch(recordsProvider(widget.exercise.id)).valueOrNull ?? [];

    final prValueStr = _formatValue(widget.newValue, widget.exercise.category, weightUnit, distanceUnit);
    final dateStr = _dateStr(widget.date);
    final daysSinceStr = _calcDaysSince(records, widget.exercise.category, widget.newValue, widget.date);

    return Scaffold(
      appBar: AppBar(title: const Text('공유하기')),
      body: Column(
        children: [
          const Divider(height: 0.5, thickness: 0.5, color: AppTheme.separator),
          // ── Preview ───────────────────────────────────────────
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: AspectRatio(
                  aspectRatio: _aspectRatio.ratio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Media background
                        if (_mediaFile != null && !_isVideo)
                          Image.file(_mediaFile!, fit: BoxFit.cover)
                        else if (_mediaFile != null && _isVideo && _videoCtrl != null)
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _videoCtrl!.value.size.width,
                              height: _videoCtrl!.value.size.height,
                              child: VideoPlayer(_videoCtrl!),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        // Frame overlay
                        IgnorePointer(
                          child: _frameStyle == FrameStyle.clean
                              ? CleanFrame(
                                  exercise: widget.exercise,
                                  valueInMetric: widget.newValue,
                                  weightUnit: weightUnit,
                                  distanceUnit: distanceUnit,
                                  date: widget.date,
                                  daysSinceStr: daysSinceStr,
                                  options: _overlay,
                                )
                              : RoughFrame(
                                  exercise: widget.exercise,
                                  valueInMetric: widget.newValue,
                                  weightUnit: weightUnit,
                                  distanceUnit: distanceUnit,
                                  date: widget.date,
                                  daysSinceStr: daysSinceStr,
                                  options: _overlay,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ── Options panel ─────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.background,
              border: Border(top: BorderSide(color: AppTheme.separator, width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 비율
                _OptionRow(
                  label: '비율',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: ExportAspectRatio.values.map((r) {
                      final sel = _aspectRatio == r;
                      return GestureDetector(
                        onTap: () => setState(() => _aspectRatio = r),
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel ? AppTheme.accent : AppTheme.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: sel ? AppTheme.accent : AppTheme.separator,
                            ),
                          ),
                          child: Text(r.label,
                              style: TextStyle(
                                  color: sel ? Colors.white : AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 0.5, thickness: 0.5, color: AppTheme.separator, indent: 16),
                // 미디어
                _OptionRow(
                  label: '미디어',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PickerChip(
                        label: '사진',
                        icon: CupertinoIcons.photo,
                        onTap: () => _pickMedia(video: false),
                      ),
                      const SizedBox(width: 8),
                      _PickerChip(
                        label: '영상',
                        icon: CupertinoIcons.video_camera,
                        onTap: () => _pickMedia(video: true),
                      ),
                      if (_mediaFile != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            _videoCtrl?.dispose();
                            setState(() { _mediaFile = null; _videoCtrl = null; });
                          },
                          child: const Icon(CupertinoIcons.xmark_circle_fill,
                              color: AppTheme.textSecondary, size: 20),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 0.5, thickness: 0.5, color: AppTheme.separator, indent: 16),
                // 프레임
                _OptionRow(
                  label: '프레임',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: FrameStyle.values.map((s) {
                      final sel = _frameStyle == s;
                      return GestureDetector(
                        onTap: () => setState(() => _frameStyle = s),
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel ? AppTheme.accent : AppTheme.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: sel ? AppTheme.accent : AppTheme.separator,
                            ),
                          ),
                          child: Text(
                            s == FrameStyle.clean ? 'CLEAN' : 'ROUGH',
                            style: TextStyle(
                                color: sel ? Colors.white : AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 0.5, thickness: 0.5, color: AppTheme.separator, indent: 16),
                // 데이터 토글
                _OptionRow(
                  label: '데이터',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Toggle(label: '운동명', value: _overlay.showName,
                          onTap: () => setState(() => _overlay = _overlay.copyWith(showName: !_overlay.showName))),
                      const SizedBox(width: 6),
                      _Toggle(label: 'PR', value: _overlay.showPr,
                          onTap: () => setState(() => _overlay = _overlay.copyWith(showPr: !_overlay.showPr))),
                      const SizedBox(width: 6),
                      _Toggle(label: '날짜', value: _overlay.showDate,
                          onTap: () => setState(() => _overlay = _overlay.copyWith(showDate: !_overlay.showDate))),
                      const SizedBox(width: 6),
                      _Toggle(label: '+N일', value: _overlay.showDaysSince,
                          onTap: () => setState(() => _overlay = _overlay.copyWith(showDaysSince: !_overlay.showDaysSince))),
                    ],
                  ),
                ),
                // ── Action buttons ────────────────────────────
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _exporting
                        ? Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppTheme.accent),
                                ),
                                const SizedBox(width: 10),
                                Text(_exportLabel,
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary, fontSize: 14)),
                              ],
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _ActionBtn(
                                  label: '이미지 저장',
                                  icon: CupertinoIcons.arrow_down_to_line,
                                  onTap: () => _saveImage(
                                    prValueStr: prValueStr,
                                    dateStr: dateStr,
                                    daysSinceStr: daysSinceStr,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ActionBtn(
                                  label: '영상 저장',
                                  icon: CupertinoIcons.videocam,
                                  onTap: _mediaFile != null && _isVideo
                                      ? () => _saveVideo(
                                          prValueStr: prValueStr,
                                          dateStr: dateStr,
                                          daysSinceStr: daysSinceStr,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ActionBtn(
                                  label: '공유',
                                  icon: CupertinoIcons.share,
                                  accent: true,
                                  onTap: () => _share(
                                    prValueStr: prValueStr,
                                    dateStr: dateStr,
                                    daysSinceStr: daysSinceStr,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Media picker ───────────────────────────────────────────

  Future<void> _pickMedia({required bool video}) async {
    final picker = ImagePicker();
    XFile? file;
    if (video) {
      file = await picker.pickVideo(source: ImageSource.gallery);
    } else {
      file = await picker.pickImage(source: ImageSource.gallery);
    }
    if (file == null) return;

    _videoCtrl?.dispose();
    VideoPlayerController? ctrl;
    if (video) {
      ctrl = VideoPlayerController.file(File(file.path));
      await ctrl.initialize();
      ctrl.setLooping(true);
      ctrl.play();
    }
    setState(() {
      _mediaFile = File(file!.path);
      _isVideo = video;
      _videoCtrl = ctrl;
    });
  }

  // ── Export helpers ─────────────────────────────────────────

  Future<ui.Image?> _renderOverlayImage({
    required String prValueStr,
    required String dateStr,
    required String daysSinceStr,
    bool overlayOnly = false,
  }) async {
    final bytes = await renderFrameToBytes(
      style: _frameStyle,
      aspectRatio: _aspectRatio,
      exerciseName: widget.exercise.displayName,
      prValue: prValueStr,
      dateStr: dateStr,
      daysSinceStr: daysSinceStr,
      options: _overlay,
      overlayOnly: overlayOnly,
    );
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _saveImage({
    required String prValueStr,
    required String dateStr,
    required String daysSinceStr,
  }) async {
    setState(() { _exporting = true; _exportLabel = '이미지 저장 중...'; });
    try {
      final bytes = await renderFrameToBytes(
        style: _frameStyle,
        aspectRatio: _aspectRatio,
        exerciseName: widget.exercise.displayName,
        prValue: prValueStr,
        dateStr: dateStr,
        daysSinceStr: daysSinceStr,
        options: _overlay,
      );
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/pbpr_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(bytes);
      await Gal.putImage(path, album: 'PBPR');
      if (mounted) _showSnack('갤러리에 저장됐습니다');
    } catch (e) {
      if (mounted) _showSnack('저장 실패: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _saveVideo({
    required String prValueStr,
    required String dateStr,
    required String daysSinceStr,
  }) async {
    if (_mediaFile == null) return;
    setState(() { _exporting = true; _exportLabel = '영상 저장 중...'; });
    try {
      final tempDir = await getTemporaryDirectory();
      final overlayBytes = await renderFrameToBytes(
        style: _frameStyle,
        aspectRatio: _aspectRatio,
        exerciseName: widget.exercise.displayName,
        prValue: prValueStr,
        dateStr: dateStr,
        daysSinceStr: daysSinceStr,
        options: _overlay,
        overlayOnly: true,
      );
      final overlayPath =
          '${tempDir.path}/overlay_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(overlayPath).writeAsBytes(overlayBytes);

      final outputPath =
          '${tempDir.path}/pbpr_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final exportW = _aspectRatio.exportSize.width.toInt();
      final exportH = _aspectRatio.exportSize.height.toInt();

      final cmd = '-i "${_mediaFile!.path}" '
          '-i "$overlayPath" '
          '-filter_complex '
          '"[0:v]scale=${exportW}:${exportH}:force_original_aspect_ratio=increase,'
          'crop=${exportW}:${exportH}[bg];'
          '[bg][1:v]overlay=0:0:format=auto,format=yuv420p[out]" '
          '-map "[out]" -map 0:a? '
          '-c:v libx264 -crf 20 -preset veryfast '
          '-c:a aac -r 30 '
          '"$outputPath"';

      final session = await FFmpegKit.execute(cmd);
      final rc = await session.getReturnCode();
      if (ReturnCode.isSuccess(rc)) {
        await Gal.putVideo(outputPath, album: 'PBPR');
        if (mounted) _showSnack('갤러리에 저장됐습니다');
      } else {
        final logs = await session.getLogs();
        if (mounted) _showSnack('영상 저장 실패');
        debugPrint('ffmpeg error: ${logs.map((l) => l.getMessage()).join('\n')}');
      }
    } catch (e) {
      if (mounted) _showSnack('오류: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _share({
    required String prValueStr,
    required String dateStr,
    required String daysSinceStr,
  }) async {
    setState(() { _exporting = true; _exportLabel = '준비 중...'; });
    try {
      final bytes = await renderFrameToBytes(
        style: _frameStyle,
        aspectRatio: _aspectRatio,
        exerciseName: widget.exercise.displayName,
        prValue: prValueStr,
        dateStr: dateStr,
        daysSinceStr: daysSinceStr,
        options: _overlay,
      );
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/pbpr_share.png';
      await File(path).writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(path, mimeType: 'image/png')],
        subject: 'PBPR — ${widget.exercise.displayName} 신기록!',
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── Value helpers ──────────────────────────────────────────

  String _formatValue(double v, ExerciseCategory cat,
      String weightUnit, String distanceUnit) {
    switch (cat) {
      case ExerciseCategory.strength:
        return UnitConverter.formatWeight(v, weightUnit);
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        return UnitConverter.secondsToDisplay(v.toInt());
      case ExerciseCategory.custom:
        return v.toStringAsFixed(1);
    }
  }

  String _dateStr(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  String _calcDaysSince(
      List<Record> records, ExerciseCategory cat, double newValue, DateTime date) {
    final beforeMs = date.millisecondsSinceEpoch;
    final previous = records.where((r) => r.performedAt < beforeMs).toList();
    if (previous.isEmpty) return '';

    double? _val(Record r) {
      switch (cat) {
        case ExerciseCategory.strength:
          return (r.weight != null && (r.reps == null || r.reps == 1))
              ? r.weight
              : null;
        case ExerciseCategory.running:
        case ExerciseCategory.workout:
          return r.durationSeconds?.toDouble();
        case ExerciseCategory.custom:
          return r.weight;
      }
    }

    final valid = previous.where((r) => _val(r) != null).toList();
    if (valid.isEmpty) return '';

    Record prevBest;
    switch (cat) {
      case ExerciseCategory.strength:
      case ExerciseCategory.custom:
        prevBest = valid.reduce(
            (a, b) => (_val(a) ?? 0) >= (_val(b) ?? 0) ? a : b);
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        prevBest = valid.reduce((a, b) =>
            (_val(a) ?? double.maxFinite) <=
                    (_val(b) ?? double.maxFinite)
                ? a
                : b);
    }

    final prevDate =
        DateTime.fromMillisecondsSinceEpoch(prevBest.performedAt);
    final days = date.difference(prevDate).inDays;
    if (days <= 0) return '';
    return '+${days}일 만에';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }
}

// ── Sub-widgets ────────────────────────────────────────────────

class _OptionRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _OptionRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          child,
        ],
      ),
    );
  }
}

class _PickerChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PickerChip(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.separator),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onTap;
  const _Toggle(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: value
              ? AppTheme.accent.withValues(alpha: 0.12)
              : AppTheme.card,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
              color: value ? AppTheme.accent : AppTheme.separator),
        ),
        child: Text(label,
            style: TextStyle(
                color: value ? AppTheme.accent : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight:
                    value ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool accent;
  const _ActionBtn(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.accent = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: accent
              ? (enabled ? AppTheme.accent : AppTheme.separator)
              : AppTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: accent
              ? null
              : Border.all(
                  color: enabled ? AppTheme.separator : AppTheme.separator),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: accent
                    ? Colors.white
                    : enabled
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: accent
                        ? Colors.white
                        : enabled
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
```

---

### Task 6: iOS permissions

**Files:** `ios/Runner/Info.plist`

- [ ] Add inside the `<dict>` tag:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>운동 기록을 저장하고 미디어를 선택하기 위해 갤러리 접근 권한이 필요합니다.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>운동 기록 이미지를 갤러리에 저장합니다.</string>
```

---

### Task 7: Verify and commit

- [ ] Run `flutter analyze` — expect no errors (only info-level hints acceptable).

- [ ] Fix any type errors from analyze output.

- [ ] Commit:
```bash
git add -A
git commit -m "feat: export screen rebuild — aspect ratio, overlay toggles, Canvas export, ffmpeg video, gallery save"
```
