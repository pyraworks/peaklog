import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import '../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../core/models/exercise.dart';
import '../../core/models/health_workout.dart';
import '../../core/models/record.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/records_provider.dart';
import '../../providers/unit_settings_provider.dart';
import '../../widgets/screen_header.dart';
import 'clean_frame.dart';
import 'export_models.dart';
import 'frame_painter.dart';
import 'rough_frame.dart';

class ExportScreen extends ConsumerStatefulWidget {
  final Exercise? exercise;      // PBPR Record mode: non-null
  final HealthWorkout? activity; // Activity mode: non-null
  final double newValue;
  final DateTime date;

  const ExportScreen({
    this.exercise,
    this.activity,
    required this.newValue,
    required this.date,
    super.key,
  }) : assert(exercise != null || activity != null,
            'Either exercise or activity must be provided');

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

  bool get _isActivityMode => widget.activity != null;

  Exercise _effectiveExercise() {
    if (widget.exercise != null) return widget.exercise!;
    final act = widget.activity!;
    final hasDistance = act.distanceKm > 0;
    final label = _activityLabel(act.activityType);
    final displayName = hasDistance
        ? '$label  ${act.distanceKm.toStringAsFixed(2)} km'
        : label;
    return Exercise(
      id: '',
      displayName: displayName,
      normalizedName: '',
      recordType: hasDistance ? RecordType.distance : RecordType.forTime,
      createdAt: 0,
      updatedAt: 0,
    );
  }

  String _activityLabel(HealthActivityType type) {
    switch (type) {
      case HealthActivityType.running:  return 'Running';
      case HealthActivityType.cycling:  return 'Cycling';
      case HealthActivityType.swimming: return 'Swimming';
      case HealthActivityType.other:    return 'Workout';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(unitSettingsProvider).valueOrNull;
    final distanceUnit = settings?.distanceUnit ?? 'km';

    final exercise = _effectiveExercise();
    final weightUnit = exercise.baseUnit;

    final records = _isActivityMode
        ? <Record>[]
        : ref.watch(recordsProvider(exercise.id)).valueOrNull ?? [];

    final prValueStr = _formatValue(
        widget.newValue, exercise.recordType!, weightUnit, distanceUnit);
    final dateStr = _dateStr(widget.date);
    final daysSinceStr = _isActivityMode
        ? ''
        : _calcDaysSince(records, exercise.recordType!, widget.newValue, widget.date);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ScreenHeader(
            backLabel: 'Back',
            title: 'Share',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: Column(
              children: [
                // ── Preview area ──────────────────────────────────────────
                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final ratio = _aspectRatio.ratio;
                      final maxW = constraints.maxWidth - 40.0;
                      final maxH = constraints.maxHeight - 32.0;
                      double w, h;
                      if (maxW / ratio <= maxH) {
                        w = maxW;
                        h = w / ratio;
                      } else {
                        h = maxH;
                        w = h * ratio;
                      }
                      // Cap width for readability on large screens.
                      if (w > 320) { w = 320; h = w / ratio; }
                      return Center(
                        child: SizedBox(
                          width: w,
                          height: h,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
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
                                IgnorePointer(
                                  child: _frameStyle == FrameStyle.clean
                                      ? CleanFrame(
                                          exercise: exercise,
                                          valueInMetric: widget.newValue,
                                          weightUnit: weightUnit,
                                          distanceUnit: distanceUnit,
                                          date: widget.date,
                                          daysSinceStr: daysSinceStr,
                                          options: _overlay,
                                          showPrBadge: !_isActivityMode,
                                        )
                                      : RoughFrame(
                                          exercise: exercise,
                                          valueInMetric: widget.newValue,
                                          weightUnit: weightUnit,
                                          distanceUnit: distanceUnit,
                                          date: widget.date,
                                          daysSinceStr: daysSinceStr,
                                          options: _overlay,
                                          showPrBadge: !_isActivityMode,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Controls panel ────────────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    border: Border(top: BorderSide(color: AppColors.separatorAlt)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Aspect Ratio
                      _RatioRow(
                        selected: _aspectRatio,
                        onChanged: (r) => setState(() => _aspectRatio = r),
                      ),
                      const Divider(height: 1, thickness: 0.5, color: AppColors.separator),
                      // Frame
                      _OptionRow(
                        label: 'Frame',
                        child: _FrameSelector(
                          selected: _frameStyle,
                          onChanged: (s) => setState(() => _frameStyle = s),
                        ),
                      ),
                      const Divider(height: 1, thickness: 0.5, color: AppColors.separator),
                      // Background media
                      _OptionRow(
                        label: 'Background',
                        child: _MediaPicker(
                          mediaFile: _mediaFile,
                          onPickImage: () => _pickMedia(video: false),
                          onPickVideo: () => _pickMedia(video: true),
                          onClear: () {
                            _videoCtrl?.dispose();
                            setState(() { _mediaFile = null; _videoCtrl = null; });
                          },
                        ),
                      ),
                      const Divider(height: 1, thickness: 0.5, color: AppColors.separator),
                      // Sticker (overlay toggles)
                      _StickerRow(
                        overlay: _overlay,
                        onChanged: (o) => setState(() => _overlay = o),
                      ),
                      // Export actions
                      _ExportActions(
                        isExporting: _exporting,
                        exportLabel: _exportLabel,
                        canSaveVideo: _mediaFile != null && _isVideo,
                        onSaveImage: () => _saveImage(
                          prValueStr: prValueStr,
                          dateStr: dateStr,
                          daysSinceStr: daysSinceStr,
                        ),
                        onSaveVideo: (_mediaFile != null && _isVideo)
                            ? () => _saveVideo(
                                  prValueStr: prValueStr,
                                  dateStr: dateStr,
                                  daysSinceStr: daysSinceStr,
                                )
                            : null,
                        onShare: () => _share(
                          prValueStr: prValueStr,
                          dateStr: dateStr,
                          daysSinceStr: daysSinceStr,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Media picker ──────────────────────────────────────────────

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

  // ── Export ────────────────────────────────────────────────────

  Future<void> _saveImage({
    required String prValueStr,
    required String dateStr,
    required String daysSinceStr,
  }) async {
    setState(() { _exporting = true; _exportLabel = 'Saving image...'; });
    try {
      final ex = widget.exercise ?? _effectiveExercise();
      final bytes = await renderFrameToBytes(
        style: _frameStyle, aspectRatio: _aspectRatio,
        exerciseName: ex.displayName,
        prValue: prValueStr, dateStr: dateStr,
        daysSinceStr: daysSinceStr, options: _overlay,
        badgeLabel: ex.bestTypeLabel,
      );
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/pbpr_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(bytes);
      await Gal.putImage(path, album: 'PBPR');
      if (mounted) _showSnack('Saved to Photos');
    } catch (e) {
      if (mounted) _showSnack('Save failed: $e');
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
    setState(() { _exporting = true; _exportLabel = 'Saving video...'; });
    try {
      final tempDir = await getTemporaryDirectory();
      final exV = widget.exercise ?? _effectiveExercise();
      final overlayBytes = await renderFrameToBytes(
        style: _frameStyle, aspectRatio: _aspectRatio,
        exerciseName: exV.displayName,
        prValue: prValueStr, dateStr: dateStr,
        daysSinceStr: daysSinceStr, options: _overlay, overlayOnly: true,
        badgeLabel: exV.bestTypeLabel,
      );
      final overlayPath = '${tempDir.path}/overlay_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(overlayPath).writeAsBytes(overlayBytes);

      final outputPath = '${tempDir.path}/pbpr_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final exportW = _aspectRatio.exportSize.width.toInt();
      final exportH = _aspectRatio.exportSize.height.toInt();

      final cmd = '-i "${_mediaFile!.path}" '
          '-i "$overlayPath" '
          '-filter_complex '
          '"[0:v]scale=$exportW:$exportH:force_original_aspect_ratio=increase,'
          'crop=$exportW:$exportH[bg];'
          '[bg][1:v]overlay=0:0:format=auto,format=yuv420p[out]" '
          '-map "[out]" -map 0:a? '
          '-c:v libx264 -crf 20 -preset veryfast '
          '-c:a aac -r 30 '
          '"$outputPath"';

      final session = await FFmpegKit.execute(cmd);
      final rc = await session.getReturnCode();
      if (ReturnCode.isSuccess(rc)) {
        await Gal.putVideo(outputPath, album: 'PBPR');
        if (mounted) _showSnack('Saved to Photos');
      } else {
        if (mounted) _showSnack('Video save failed');
        debugPrint('ffmpeg failed: ${(await session.getLogs()).map((l) => l.getMessage()).join('\n')}');
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _share({
    required String prValueStr,
    required String dateStr,
    required String daysSinceStr,
  }) async {
    setState(() { _exporting = true; _exportLabel = 'Preparing...'; });
    try {
      final exS = widget.exercise ?? _effectiveExercise();
      final bytes = await renderFrameToBytes(
        style: _frameStyle, aspectRatio: _aspectRatio,
        exerciseName: exS.displayName,
        prValue: prValueStr, dateStr: dateStr,
        daysSinceStr: daysSinceStr, options: _overlay,
        badgeLabel: exS.bestTypeLabel,
      );
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/pbpr_share.png';
      await File(path).writeAsBytes(bytes);

      final box = context.findRenderObject() as RenderBox?;
      final exerciseName = (widget.exercise ?? _effectiveExercise()).displayName;
      await Share.shareXFiles(
        [XFile(path, mimeType: 'image/png')],
        subject: 'PBPR — $exerciseName${_isActivityMode ? '' : ' New PR!'}',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      if (mounted) _showSnack('Share error: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────

  String _formatValue(
      double v, RecordType recordType, String weightUnit, String distanceUnit) {
    switch (recordType) {
      case RecordType.weight:
        return UnitConverter.formatWeight(v, weightUnit);
      case RecordType.distance:
      case RecordType.forTime:
      case RecordType.amrap:
        return UnitConverter.secondsToDisplay(v.toInt());
    }
  }

  String _dateStr(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  String _calcDaysSince(List<Record> records, RecordType recordType,
      double newValue, DateTime date) {
    final beforeMs = date.millisecondsSinceEpoch;
    final previous = records.where((r) => r.performedAt < beforeMs).toList();
    if (previous.isEmpty) return '';

    double? valOf(Record r) {
      switch (recordType) {
        case RecordType.weight:
          return (r.weight != null && (r.reps == null || r.reps == 1))
              ? r.weight
              : null;
        case RecordType.distance:
        case RecordType.forTime:
        case RecordType.amrap:
          return r.durationSeconds?.toDouble();
      }
    }

    final valid = previous.where((r) => valOf(r) != null).toList();
    if (valid.isEmpty) return '';

    Record prevBest;
    switch (recordType) {
      case RecordType.weight:
        prevBest =
            valid.reduce((a, b) => (valOf(a) ?? 0) >= (valOf(b) ?? 0) ? a : b);
      case RecordType.distance:
      case RecordType.forTime:
      case RecordType.amrap:
        prevBest = valid.reduce((a, b) =>
            (valOf(a) ?? double.maxFinite) <= (valOf(b) ?? double.maxFinite)
                ? a
                : b);
    }

    final prevDate = DateTime.fromMillisecondsSinceEpoch(prevBest.performedAt);
    final days = date.difference(prevDate).inDays;
    if (days <= 0) return '';
    return '+$days일 만에';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }
}

// ── Section widgets ───────────────────────────────────────────

/// Aspect ratio row: fixed "Ratio" label on left, horizontally scrollable
/// chips on the right. Handles any number of ratios without overflow.
class _RatioRow extends StatelessWidget {
  final ExportAspectRatio selected;
  final ValueChanged<ExportAspectRatio> onChanged;
  const _RatioRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: AppSpacing.s16),
            child: Text(
              'Ratio',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.label2,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: ExportAspectRatio.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final r = ExportAspectRatio.values[i];
                final sel = selected == r;
                return GestureDetector(
                  onTap: () => onChanged(r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.actionDark : AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(
                        color: sel ? AppColors.actionDarkBorder : AppColors.separator,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        r.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: sel ? Colors.white : AppColors.label1,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.s16),
        ],
      ),
    );
  }
}

/// Sticker row: fixed "Sticker" label on left, horizontally scrollable overlay
/// toggles on the right.
class _StickerRow extends StatelessWidget {
  final OverlayOptions overlay;
  final ValueChanged<OverlayOptions> onChanged;
  const _StickerRow({required this.overlay, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: AppSpacing.s16),
            child: Text(
              'Sticker',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.label2,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _Toggle(
                  label: 'Name',
                  value: overlay.showName,
                  onTap: () => onChanged(overlay.copyWith(showName: !overlay.showName)),
                ),
                const SizedBox(width: 6),
                _Toggle(
                  label: 'Value',
                  value: overlay.showValue,
                  onTap: () => onChanged(overlay.copyWith(showValue: !overlay.showValue)),
                ),
                const SizedBox(width: 6),
                _Toggle(
                  label: 'Date',
                  value: overlay.showDate,
                  onTap: () => onChanged(overlay.copyWith(showDate: !overlay.showDate)),
                ),
                const SizedBox(width: 6),
                _Toggle(
                  label: 'Days',
                  value: overlay.showDaysSince,
                  onTap: () => onChanged(overlay.copyWith(showDaysSince: !overlay.showDaysSince)),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s16),
        ],
      ),
    );
  }
}

// ── Generic option row ────────────────────────────────────────

class _OptionRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _OptionRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.label2,
            ),
          ),
          const Spacer(),
          child,
        ],
      ),
    );
  }
}

// ── Frame selector ────────────────────────────────────────────

class _FrameSelector extends StatelessWidget {
  final FrameStyle selected;
  final ValueChanged<FrameStyle> onChanged;
  const _FrameSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: FrameStyle.values.map((s) {
          final sel = selected == s;
          return GestureDetector(
            onTap: () => onChanged(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppColors.actionDark : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s == FrameStyle.clean ? 'Clean' : 'Rough',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : AppColors.label1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Background media picker ───────────────────────────────────

class _MediaPicker extends StatelessWidget {
  final File? mediaFile;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onClear;
  const _MediaPicker({
    required this.mediaFile,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PickerChip(label: 'Photo', icon: AppIcons.image, onTap: onPickImage),
        const SizedBox(width: 8),
        _PickerChip(label: 'Video', icon: AppIcons.video, onTap: onPickVideo),
        if (mediaFile != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClear,
            child: Icon(AppIcons.xCircle, color: AppColors.label2, size: 20),
          ),
        ],
      ],
    );
  }
}

// ── Export actions ────────────────────────────────────────────

class _ExportActions extends StatelessWidget {
  final bool isExporting;
  final String exportLabel;
  final bool canSaveVideo;
  final VoidCallback onSaveImage;
  final VoidCallback? onSaveVideo;
  final VoidCallback onShare;

  const _ExportActions({
    required this.isExporting,
    required this.exportLabel,
    required this.canSaveVideo,
    required this.onSaveImage,
    required this.onSaveVideo,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: isExporting
            ? Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.actionDark),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      exportLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.label2,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Actions: Share = primary (filled), Save Image = secondary (outlined).
                  // Share is the user's primary intent on this screen; Save is a convenience.
                  Row(
                    children: [
                      Expanded(
                        child: _PrimaryButton(
                          label: 'Save Image',
                          icon: AppIcons.download,
                          onTap: onSaveImage,
                          secondary: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PrimaryButton(
                          label: 'Share',
                          icon: AppIcons.share,
                          onTap: onShare,
                        ),
                      ),
                    ],
                  ),
                  // Secondary: Save Video — only visible when a video is loaded
                  if (canSaveVideo) ...[
                    const SizedBox(height: 8),
                    _PrimaryButton(
                      label: 'Save Video',
                      icon: AppIcons.video,
                      onTap: onSaveVideo,
                      secondary: true,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ── Primitive sub-widgets ─────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.separator),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.label2),
            const SizedBox(width: AppSpacing.s4),
            Text(label,
                style: AppTypography.caption
                    .copyWith(color: AppColors.label1)),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
        decoration: BoxDecoration(
          color: value ? AppColors.actionDark : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.badge),
          border: Border.all(
              color: value ? AppColors.actionDarkBorder : AppColors.separator),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: value ? Colors.white : AppColors.label2,
            fontWeight: value ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Equal-priority action button. `secondary: true` uses an outlined style.
class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool secondary;

  const _PrimaryButton({
    required this.label,
    this.icon,
    required this.onTap,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final Color bg = secondary
        ? AppColors.card
        : (enabled ? AppColors.actionDark : AppColors.separator);
    final Color border = secondary ? AppColors.separator : AppColors.actionDarkBorder;
    final Color fg = secondary
        ? (enabled ? AppColors.label1 : AppColors.label2)
        : (enabled ? Colors.white : AppColors.label2);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
