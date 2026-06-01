import 'dart:io';
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
    final records =
        ref.watch(recordsProvider(widget.exercise.id)).valueOrNull ?? [];

    final prValueStr = _formatValue(
        widget.newValue, widget.exercise.category, weightUnit, distanceUnit);
    final dateStr = _dateStr(widget.date);
    final daysSinceStr = _calcDaysSince(
        records, widget.exercise.category, widget.newValue, widget.date);

    return Scaffold(
      appBar: AppBar(title: const Text('공유하기')),
      body: Column(
        children: [
          const Divider(
              height: 0.5, thickness: 0.5, color: AppTheme.separator),
          // ── Preview ─────────────────────────────────────────
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
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
                        else if (_mediaFile != null &&
                            _isVideo &&
                            _videoCtrl != null &&
                            _videoCtrl!.value.isInitialized)
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _videoCtrl!.value.size.width,
                              height: _videoCtrl!.value.size.height,
                              child: VideoPlayer(_videoCtrl!),
                            ),
                          ),
                        // Frame overlay (widget-based preview)
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
          // ── Options panel ────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.background,
              border: Border(
                  top: BorderSide(
                      color: AppTheme.separator, width: 0.5)),
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
                        onTap: () =>
                            setState(() => _aspectRatio = r),
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppTheme.accent
                                : AppTheme.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: sel
                                  ? AppTheme.accent
                                  : AppTheme.separator,
                            ),
                          ),
                          child: Text(r.label,
                              style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: AppTheme.separator,
                    indent: 16),
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
                            setState(() {
                              _mediaFile = null;
                              _videoCtrl = null;
                            });
                          },
                          child: const Icon(
                              CupertinoIcons.xmark_circle_fill,
                              color: AppTheme.textSecondary,
                              size: 20),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: AppTheme.separator,
                    indent: 16),
                // 프레임
                _OptionRow(
                  label: '프레임',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: FrameStyle.values.map((s) {
                      final sel = _frameStyle == s;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _frameStyle = s),
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppTheme.accent
                                : AppTheme.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: sel
                                  ? AppTheme.accent
                                  : AppTheme.separator,
                            ),
                          ),
                          child: Text(
                            s == FrameStyle.clean
                                ? 'CLEAN'
                                : 'ROUGH',
                            style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: AppTheme.separator,
                    indent: 16),
                // 데이터 토글
                _OptionRow(
                  label: '데이터',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Toggle(
                        label: '운동명',
                        value: _overlay.showName,
                        onTap: () => setState(() => _overlay =
                            _overlay.copyWith(
                                showName: !_overlay.showName)),
                      ),
                      const SizedBox(width: 6),
                      _Toggle(
                        label: 'PR',
                        value: _overlay.showPr,
                        onTap: () => setState(() => _overlay =
                            _overlay.copyWith(
                                showPr: !_overlay.showPr)),
                      ),
                      const SizedBox(width: 6),
                      _Toggle(
                        label: '날짜',
                        value: _overlay.showDate,
                        onTap: () => setState(() => _overlay =
                            _overlay.copyWith(
                                showDate: !_overlay.showDate)),
                      ),
                      const SizedBox(width: 6),
                      _Toggle(
                        label: '+N일',
                        value: _overlay.showDaysSince,
                        onTap: () => setState(() => _overlay =
                            _overlay.copyWith(
                                showDaysSince:
                                    !_overlay.showDaysSince)),
                      ),
                    ],
                  ),
                ),
                // ── Action buttons ─────────────────────────────
                SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _exporting
                        ? Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.accent),
                                ),
                                const SizedBox(width: 10),
                                Text(_exportLabel,
                                    style: const TextStyle(
                                        color:
                                            AppTheme.textSecondary,
                                        fontSize: 14)),
                              ],
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _ActionBtn(
                                  label: '이미지 저장',
                                  icon: CupertinoIcons
                                      .arrow_down_to_line,
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
                                  onTap:
                                      (_mediaFile != null && _isVideo)
                                          ? () => _saveVideo(
                                                prValueStr:
                                                    prValueStr,
                                                dateStr: dateStr,
                                                daysSinceStr:
                                                    daysSinceStr,
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

  // ── Media picker ─────────────────────────────────────────────

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

  // ── Export ───────────────────────────────────────────────────

  Future<void> _saveImage({
    required String prValueStr,
    required String dateStr,
    required String daysSinceStr,
  }) async {
    setState(() {
      _exporting = true;
      _exportLabel = '이미지 저장 중...';
    });
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
      final path =
          '${tempDir.path}/pbpr_${DateTime.now().millisecondsSinceEpoch}.png';
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
    setState(() {
      _exporting = true;
      _exportLabel = '저장 중...';
    });
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
        if (mounted) _showSnack('영상 저장 실패');
        debugPrint(
            'ffmpeg failed: ${(await session.getLogs()).map((l) => l.getMessage()).join('\n')}');
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
    setState(() {
      _exporting = true;
      _exportLabel = '준비 중...';
    });
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

  // ── Helpers ──────────────────────────────────────────────────

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

  String _calcDaysSince(List<Record> records, ExerciseCategory cat,
      double newValue, DateTime date) {
    final beforeMs = date.millisecondsSinceEpoch;
    final previous =
        records.where((r) => r.performedAt < beforeMs).toList();
    if (previous.isEmpty) return '';

    double? valOf(Record r) {
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

    final valid = previous.where((r) => valOf(r) != null).toList();
    if (valid.isEmpty) return '';

    Record prevBest;
    switch (cat) {
      case ExerciseCategory.strength:
      case ExerciseCategory.custom:
        prevBest = valid
            .reduce((a, b) => (valOf(a) ?? 0) >= (valOf(b) ?? 0) ? a : b);
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        prevBest = valid.reduce((a, b) =>
            (valOf(a) ?? double.maxFinite) <=
                    (valOf(b) ?? double.maxFinite)
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 2)),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────

class _OptionRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _OptionRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
      {required this.label,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
      {required this.label,
      required this.value,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
                color:
                    value ? AppTheme.accent : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: value
                    ? FontWeight.w600
                    : FontWeight.w400)),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool accent;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.accent = false,
  });

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
              : Border.all(color: AppTheme.separator),
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
