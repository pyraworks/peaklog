import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import '../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_helper.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/models/exercise.dart';
import '../../core/models/record.dart';
import '../../core/services/health_sync_service.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/exercises_provider.dart';
import '../../providers/personal_best_provider.dart';
import '../../providers/unit_settings_provider.dart';
import '../../widgets/pb_badge.dart';
import '../../widgets/screen_header.dart';
import '../export/export_screen.dart';
import '../record_input/activity_picker_sheet.dart';

class QuickShareScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const QuickShareScreen({super.key, this.embedded = false});

  @override
  ConsumerState<QuickShareScreen> createState() => _QuickShareScreenState();
}

class _QuickShareScreenState extends ConsumerState<QuickShareScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.embedded) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Text(
                      'Share',
                      style: AppTypography.appTitle.copyWith(
                        color: AppColors.label1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      children: [
                        _ShareOptionCard(
                          icon: AppIcons.medal,
                          iconColor: AppColors.pbGold,
                          title: 'PeakLog Record',
                          subtitle: 'Share your tracked records',
                          onTap: () => _showRecordPicker(),
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        _ShareOptionCard(
                          icon: AppIcons.heart,
                          iconColor: const Color(0xFFFF3B30),
                          title: 'Health Activity',
                          subtitle: 'Share a workout from Apple Health',
                          onTap: () => _showActivityPicker(),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const ScreenHeader(
            backLabel: 'Home',
            title: 'Share',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              children: [
                _ShareOptionCard(
                  icon: AppIcons.medal,
                  iconColor: AppColors.pbGold,
                  title: 'PeakLog Record',
                  subtitle: 'Share your tracked records',
                  onTap: () => _showRecordPicker(),
                ),
                const SizedBox(height: AppSpacing.s12),
                _ShareOptionCard(
                  icon: AppIcons.heart,
                  iconColor: const Color(0xFFFF3B30),
                  title: 'Health Activity',
                  subtitle: 'Share a workout from Apple Health',
                  onTap: () => _showActivityPicker(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRecordPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordPickerSheet(ref: ref),
    );
  }

  Future<void> _showActivityPicker() async {
    final granted = await healthSyncService.requestPermission();
    if (!mounted) return;
    if (!granted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Apple Health 접근 권한이 필요합니다'),
          content: const Text('설정에서 건강 앱 접근을 허용해 주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                AppSettings.openAppSettings();
              },
              child: const Text('설정에서 허용하기'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    final workout = await showActivityPickerSheet(context);
    if (workout == null || !mounted) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ExportScreen(
          activity: workout,
          newValue: workout.durationSeconds.toDouble(),
          date: workout.startTime,
        ),
      ),
    );
  }
}

// ── _ShareOptionCard ──────────────────────────────────────────────────────────

class _ShareOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.separator, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.cardTitle.copyWith(
                      color: AppColors.label1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.label2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.forward, size: 20, color: AppColors.chevron),
          ],
        ),
      ),
    );
  }
}

// ── RecordPickerSheet ─────────────────────────────────────────────────────────

class RecordPickerSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const RecordPickerSheet({required this.ref, super.key});

  @override
  ConsumerState<RecordPickerSheet> createState() => _RecordPickerSheetState();
}

class _RecordPickerSheetState extends ConsumerState<RecordPickerSheet> {
  late final Future<List<Record>> _future;

  @override
  void initState() {
    super.initState();
    _future = DatabaseHelper.instance.getRecentRecords(limit: 30);
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exercisesProvider).valueOrNull ?? [];
    final settings = ref.watch(unitSettingsProvider).valueOrNull;
    final weightUnit = settings?.weightUnit ?? 'kg';
    final distanceUnit = settings?.distanceUnit ?? 'km';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D1D6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'PeakLog Record',
                    style: AppTypography.headline.copyWith(
                      color: AppColors.label1,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(AppIcons.close, color: AppColors.label2),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Record>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final records = snap.data ?? [];
                if (records.isEmpty) {
                  return const Center(
                    child: Text(
                      '기록이 없습니다',
                      style: TextStyle(color: AppColors.label2),
                    ),
                  );
                }
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.separator, width: 0.5),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: AppColors.separator,
                    ),
                    itemBuilder: (context, i) {
                      final r = records[i];
                      final exercise = exercises
                          .where((e) => e.id == r.exerciseId)
                          .firstOrNull;
                      if (exercise == null) return const SizedBox.shrink();

                      final pb = ref.watch(personalBestProvider(exercise.id));
                      final isPb = pb?.sourceRecordId == r.id;

                      return _RecordRow(
                        record: r,
                        exercise: exercise,
                        isPb: isPb,
                        weightUnit: weightUnit,
                        distanceUnit: distanceUnit,
                        onTap: () => _openExport(context, exercise, r, weightUnit),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openExport(
    BuildContext context,
    Exercise exercise,
    Record record,
    String weightUnit,
  ) {
    Navigator.pop(context); // close sheet
    final rt = exercise.recordType;
    if (rt == null) return;
    final double newValue;
    switch (rt) {
      case RecordType.weight:
        newValue = record.weight ?? 0;
      case RecordType.etc:
        newValue = record.distance ?? 0;
      case RecordType.forTime:
        newValue = record.durationSeconds?.toDouble() ?? 0;
      case RecordType.amrap:
        newValue = record.rounds?.toDouble() ?? record.durationSeconds?.toDouble() ?? 0;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ExportScreen(
          exercise: exercise,
          newValue: newValue,
          date: DateTime.fromMillisecondsSinceEpoch(record.performedAt),
        ),
      ),
    );
  }
}

// ── _RecordRow ────────────────────────────────────────────────────────────────

class _RecordRow extends StatelessWidget {
  final Record record;
  final Exercise exercise;
  final bool isPb;
  final String weightUnit;
  final String distanceUnit;
  final VoidCallback onTap;

  const _RecordRow({
    required this.record,
    required this.exercise,
    required this.isPb,
    required this.weightUnit,
    required this.distanceUnit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final valueStr = _formatValue();
    final date = DateTime.fromMillisecondsSinceEpoch(record.performedAt);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final recDate = DateTime(date.year, date.month, date.day);

    final String dateLabel;
    if (recDate == today) {
      dateLabel = 'Today';
    } else if (recDate == yesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel =
          '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s20, vertical: AppSpacing.s16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.displayName,
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.label2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        valueStr,
                        style: AppTypography.cardTitle.copyWith(
                          color: AppColors.label1,
                        ),
                      ),
                      if (isPb) ...[
                        const SizedBox(width: 6),
                        PbBadge(label: exercise.bestTypeLabel),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              dateLabel,
              style: AppTypography.footnote.copyWith(
                color: AppColors.label2,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Icon(AppIcons.forward, size: 18, color: AppColors.chevron),
          ],
        ),
      ),
    );
  }

  String _formatValue() {
    final rt = exercise.recordType;
    if (rt == null) return '—';
    switch (rt) {
      case RecordType.weight:
        final w = UnitConverter.formatWeight(record.weight ?? 0, weightUnit);
        final reps = record.reps;
        return (reps != null && reps > 1) ? '$w × $reps' : w;
      case RecordType.etc:
        final parts = <String>[];
        if (record.distance != null) {
          parts.add(UnitConverter.formatEtc(record.distance!, record.distanceUnit.isNotEmpty ? record.distanceUnit : distanceUnit));
        }
        if (record.durationSeconds != null) {
          parts.add(UnitConverter.secondsToDisplay(record.durationSeconds!));
        }
        return parts.isEmpty ? '—' : parts.join('  ');
      case RecordType.forTime:
      case RecordType.amrap:
        return UnitConverter.secondsToDisplay(record.durationSeconds ?? 0);
    }
  }
}
