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
import '../../l10n/app_localizations.dart';

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

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ScreenHeader(backLabel: l10n.back, title: l10n.recordDetailTitle),
          if (_loading || exercise == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_record == null)
            Expanded(
                child: Center(child: Text(l10n.recordNotFound)))
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
    final l10n = AppLocalizations.of(context)!;
    final rt = exercise.recordType;
    final valueStr = rt != null ? _formatValue(record, rt, weightUnit) : '—';
    final setsBadgeLabel = (rt == RecordType.weight &&
            record.sets != null &&
            record.sets! > 1)
        ? l10n.setsDisplay(record.sets!)
        : null;
    final dateStr = _dateStr(record.performedAt);
    final pb = ref.watch(personalBestProvider(widget.exerciseId));
    final isPr = pb?.sourceRecordId == record.id;
    final prLabel = exercise.bestTypeLabel;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      children: [
        // ── Main card ───────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.separator, width: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.hardEdge,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPr) ...[
                Row(
                  children: [
                    Text(
                      l10n.sectionPersonalBest,
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
              Row(
                children: [
                  Text(
                    dateStr,
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.label2,
                    ),
                  ),
                  if (setsBadgeLabel != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      setsBadgeLabel,
                      style: AppTypography.footnote.copyWith(
                        color: AppColors.label2,
                      ),
                    ),
                  ],
                ],
              ),
              if (rt == RecordType.amrap) ...[
                Builder(builder: (context) {
                  final cap = record.timeCap ?? exercise.timeCap;
                  if (cap == null) return const SizedBox.shrink();
                  final innerL10n = AppLocalizations.of(context)!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        innerL10n.timeCap(UnitConverter.formatTimeCap(cap)),
                        style: AppTypography.footnote.copyWith(
                          color: AppColors.label2,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Actions ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            l10n.sectionActions,
            style: const TextStyle(
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
                label: l10n.editRecord,
                onTap: () async {
                  await context.push(
                      '/exercise/${widget.exerciseId}/record/${record.id}/edit');
                  if (mounted) _load();
                },
              ),
              const Divider(height: 1, color: AppColors.separatorAlt),
              _ActionRow(
                icon: AppIcons.share,
                label: l10n.share,
                onTap: () => context.push('/share/${record.id}'),
              ),
              const Divider(height: 1, color: AppColors.separatorAlt),
              _ActionRow(
                icon: AppIcons.delete,
                label: l10n.deleteRecord,
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
      case RecordType.amrap:
        if (r.rounds != null) {
          final extra = r.reps != null && r.reps! > 0 ? ' ${r.reps}' : '';
          return '${r.rounds}R$extra';
        }
        return '—';
      case RecordType.forTime:
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
    final l10n = AppLocalizations.of(context)!;
    final router = GoRouter.of(context);
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.deleteRecord),
        content: Text(l10n.deleteRecordContent),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
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
