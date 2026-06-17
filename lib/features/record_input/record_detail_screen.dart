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
              child: _buildBody(context, exercise, _record!, weightUnit),
            ),
        ],
      ),
    );
  }


  Widget _buildBody(BuildContext context, Exercise exercise, Record record,
      String weightUnit) {
    final rt = exercise.recordType;
    final valueStr = rt != null ? _formatValue(record, rt, weightUnit) : '—';
    final dateStr = _dateStr(record.performedAt);
    final pb = ref.watch(personalBestProvider(widget.exerciseId));
    final isPr = pb?.sourceRecordId == record.id;
    final prLabel = exercise.bestTypeLabel;

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
              color: AppColors.label1, letterSpacing: -0.8),
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
