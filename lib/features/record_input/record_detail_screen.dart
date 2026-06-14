import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/database_helper.dart';
import '../../core/design/app_typography.dart';
import '../../core/models/exercise.dart';
import '../../core/models/record.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/exercises_provider.dart';
import '../../providers/personal_best_provider.dart';
import '../../widgets/pb_badge.dart';
import '../../widgets/screen_header.dart';
import '../../providers/records_provider.dart';

class RecordDetailScreen extends ConsumerStatefulWidget {
  final String exerciseId;
  final String recordId;
  const RecordDetailScreen({
    required this.exerciseId,
    required this.recordId,
    super.key,
  });

  @override
  ConsumerState<RecordDetailScreen> createState() =>
      _RecordDetailScreenState();
}

class _RecordDetailScreenState extends ConsumerState<RecordDetailScreen> {
  Record? _record;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await DatabaseHelper.instance.getRecordById(widget.recordId);
    if (!mounted) return;
    setState(() {
      _record = r;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercise = ref.watch(
      exercisesProvider.select(
        (s) => s.valueOrNull
            ?.where((e) => e.id == widget.exerciseId)
            .firstOrNull,
      ),
    );

    final allRecords =
        ref.watch(recordsProvider(widget.exerciseId)).valueOrNull ?? [];
    final weightUnit = exercise?.baseUnit ?? 'kg';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const ScreenHeader(backLabel: 'Back', title: 'Record Detail'),
          if (_loading || exercise == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_record == null)
            const Expanded(
                child: Center(child: Text('Record not found')))
          else
            Expanded(
              child: _buildBody(context, exercise, _record!, weightUnit, allRecords),
            ),
        ],
      ),
    );
  }


  Widget _buildBody(BuildContext context, Exercise exercise, Record record,
      String weightUnit, List<Record> allRecords) {
    final rt = exercise.recordType;
    final valueStr = rt != null
        ? _formatValue(record, rt, weightUnit)
        : '—';
    final dateStr = _dateStr(record.performedAt);
    final pb = ref.watch(personalBestProvider(widget.exerciseId));
    final isPr = pb?.sourceRecordId == record.id;
    final prLabel = exercise.bestTypeLabel;
    final vsPrev = _vsPrevious(record, exercise, weightUnit, allRecords);
    final vsFirst = _vsFirst(record, exercise, weightUnit, allRecords);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      children: [
        // ── Main card ───────────────────────────────────────────────────────
        GestureDetector(
          onTap: () => context.push('/share/${record.id}'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.separator, width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.hardEdge,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPr) ...[
                      Row(
                        children: [
                          Text(
                            'PERSONAL BEST',
                            style: AppTypography.sectionLabel.copyWith(
                              color: AppColors.label2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          PbBadge(label: prLabel),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
                    _buildPbValue(valueStr),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: AppTypography.footnote.copyWith(
                        color: AppColors.label2,
                      ),
                    ),
                  ],
                ),
                // Right — share button
                GestureDetector(
                  onTap: () => context.push('/share/${record.id}'),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.share, size: 13, color: AppColors.label2),
                      const SizedBox(width: 4),
                      const Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.label2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Comparison card ─────────────────────────────────────────────────
        if (vsPrev != null || vsFirst != null) ...[
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 6),
            child: Text(
              'COMPARISON',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryAlt,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.separatorAlt),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: [
                if (vsPrev != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: _CompareRow(
                        label: 'vs Previous Record', value: vsPrev),
                  ),
                ],
                if (vsPrev != null && vsFirst != null)
                  const Divider(height: 1, color: AppColors.separatorAlt),
                if (vsFirst != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: _CompareRow(
                        label: 'vs First Record', value: vsFirst),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Actions ─────────────────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'ACTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryAlt,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.separatorAlt),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              _ActionRow(
                icon: AppIcons.edit,
                label: 'Edit Record',
                onTap: () => context.push(
                    '/exercise/${widget.exerciseId}/record/${record.id}/edit'),
              ),
              const Divider(height: 1, color: AppColors.separatorAlt),
              _ActionRow(
                icon: AppIcons.share,
                label: 'Share',
                onTap: () => context.push('/share/${record.id}'),
              ),
              const Divider(height: 1, color: AppColors.separatorAlt),
              _ActionRow(
                icon: AppIcons.delete,
                label: 'Delete Record',
                color: AppColors.destructive,
                onTap: () => _confirmDelete(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  String _formatValue(Record r, RecordType rt, String weightUnit) {
    switch (rt) {
      case RecordType.weight:
        final w = UnitConverter.formatWeight(r.weight ?? 0, weightUnit);
        return (r.reps != null && r.reps! > 1) ? '$w × ${r.reps}' : w;
      case RecordType.etc:
        if (r.distance != null) {
          return UnitConverter.formatEtc(r.distance!, r.distanceUnit);
        }
        return '—';
      case RecordType.forTime:
      case RecordType.amrap:
        if (r.durationSeconds != null) {
          return UnitConverter.secondsToDisplay(r.durationSeconds!);
        }
        return '—';
    }
  }

  Widget _buildPbValue(String valueStr) {
    final parts = valueStr.split(' × ');
    if (parts.length == 2) {
      return RichText(
        text: TextSpan(children: [
          TextSpan(
            text: parts[0],
            style: AppTypography.pbValue.copyWith(
              color: AppColors.label1, letterSpacing: -0.8),
          ),
          TextSpan(
            text: ' × ${parts[1]}',
            style: AppTypography.pbValue.copyWith(
              color: AppColors.label2, letterSpacing: -0.8),
          ),
        ]),
      );
    }
    return Text(
      valueStr,
      style: AppTypography.pbValue.copyWith(
        color: AppColors.label1, letterSpacing: -0.8),
    );
  }

  String _dateStr(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  String? _vsPrevious(Record record, Exercise exercise, String weightUnit,
      List<Record> allRecords) {
    final rt = exercise.recordType;
    if (rt == null) return null;
    final before = allRecords
        .where((r) => !r.isDeleted && r.performedAt < record.performedAt)
        .toList();
    if (before.isEmpty) return null;
    return _calcDiff(record, before, rt, weightUnit, 'previous');
  }

  String? _vsFirst(Record record, Exercise exercise, String weightUnit,
      List<Record> allRecords) {
    final rt = exercise.recordType;
    if (rt == null) return null;
    final others = allRecords
        .where((r) => !r.isDeleted && r.id != record.id)
        .toList();
    if (others.isEmpty) return null;
    others.sort((a, b) => a.performedAt.compareTo(b.performedAt));
    return _calcDiff(record, [others.first], rt, weightUnit, 'first');
  }

  String? _calcDiff(Record record, List<Record> comparisons, RecordType rt,
      String weightUnit, String label) {
    switch (rt) {
      case RecordType.weight:
        final valid = comparisons.where((r) => r.weight != null).toList();
        if (valid.isEmpty) return null;
        final bestPrev = valid
            .fold<double>(0, (m, r) => r.weight! > m ? r.weight! : m);
        if (record.weight == null) return null;
        final diff = record.weight! - bestPrev;
        return UnitConverter.formatDiffWeight(diff, weightUnit);
      case RecordType.etc:
        final validEtc = comparisons.where((r) => r.distance != null).toList();
        if (validEtc.isEmpty) return null;
        final bestPrevEtc = validEtc.fold<double>(0, (m, r) => r.distance! > m ? r.distance! : m);
        if (record.distance == null) return null;
        return UnitConverter.formatDiffEtc(record.distance! - bestPrevEtc, record.distanceUnit);
      case RecordType.forTime:
        final valid =
            comparisons.where((r) => r.durationSeconds != null).toList();
        if (valid.isEmpty) return null;
        final bestPrev = valid.fold<int>(
            valid.first.durationSeconds!,
            (m, r) =>
                r.durationSeconds! < m ? r.durationSeconds! : m);
        if (record.durationSeconds == null) return null;
        final diff = record.durationSeconds! - bestPrev;
        final absMin = diff.abs() ~/ 60;
        final absSec = diff.abs() % 60;
        final timeStr = absMin > 0
            ? '${absMin}m ${absSec.toString().padLeft(2, '0')}s'
            : '${absSec}s';
        return '${diff <= 0 ? '-' : '+'}$timeStr';
      case RecordType.amrap:
        final valid = comparisons.where((r) => r.rounds != null).toList();
        if (valid.isEmpty) return null;
        final bestPrev =
            valid.fold<int>(0, (m, r) => r.rounds! > m ? r.rounds! : m);
        if (record.rounds == null) return null;
        final diff = record.rounds! - bestPrev;
        return '${diff >= 0 ? '+' : ''}$diff rounds';
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final router = GoRouter.of(context);
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Record'),
        content: const Text('This record will be permanently deleted.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(recordsProvider(widget.exerciseId).notifier)
        .deleteRecord(widget.recordId);
    if (!mounted) return;
    router.pop();
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _CompareRow extends StatelessWidget {
  final String label;
  final String value;
  const _CompareRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final positive = value.startsWith('+');
    final negative = value.startsWith('-');
    final color = positive
        ? AppColors.success
        : negative
            ? AppColors.destructive
            : AppColors.textTertiary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textTertiary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimaryAlt,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: color,
                ),
              ),
            ),
            Icon(AppIcons.forward,
                size: 16, color: color.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
