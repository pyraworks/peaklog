import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/models/exercise.dart';
import '../../core/models/record.dart';
import '../../providers/personal_best_provider.dart';
import '../../domain/models/category.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/exercises_provider.dart';
import '../../providers/records_provider.dart';
import '../../widgets/pb_badge.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/swipeable_row.dart';
import '../home/add_exercise_sheet.dart';
import '../record_input/add_record_sheet.dart';
import '../../l10n/app_localizations.dart';

class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final String exerciseId;
  const ExerciseDetailScreen({required this.exerciseId, super.key});

  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  bool _addRecordOpened = false;

  void _maybeOpenAddRecord(BuildContext context, Exercise exercise) {
    if (exercise.recordType == null && !_addRecordOpened) {
      _addRecordOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showAddRecordSheet(context, ref, exercise);
      });
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  String _formatHistoryValue(Record r, RecordType? rt, String unit) {
    if (rt == null) return '—';
    switch (rt) {
      case RecordType.weight:
        final w = UnitConverter.formatWeight(r.weight!, unit);
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

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final exercise = ref.watch(
      exercisesProvider.select(
        (s) => s.valueOrNull
            ?.where((e) => e.id == widget.exerciseId)
            .firstOrNull,
      ),
    );
    final records =
        ref.watch(recordsProvider(widget.exerciseId)).valueOrNull ?? [];

    if (exercise == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final weightUnit = exercise.baseUnit;

    // Auto-open Add Record when recordType not yet set
    _maybeOpenAddRecord(context, exercise);

    final rt = exercise.recordType;
    final pb = ref.watch(personalBestProvider(widget.exerciseId));
    final bestRecordId = pb?.sourceRecordId;
    final bestRecord = bestRecordId != null
        ? records.where((r) => r.id == bestRecordId).firstOrNull
        : null;
    final bestValue = bestRecord != null && rt != null
        ? _formatHistoryValue(bestRecord, rt, weightUnit)
        : '—';
    final bestDate = bestRecord != null
        ? DateFormatter.relative(
            DateTime.fromMillisecondsSinceEpoch(bestRecord.performedAt))
        : null;
    final bestKg =
        (rt == RecordType.weight && bestRecord?.weight != null)
            ? bestRecord!.weight!
            : null;

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _ExerciseHeader(exercise: exercise),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16, vertical: AppSpacing.s24),
              children: [
                // 1. PB Card (only when recordType is set)
                if (bestRecord != null && rt != null) ...[
                  _PbCard(
                    valueText: bestValue,
                    dateText: bestDate ?? '',
                    pbLabel: exercise.bestTypeLabel,
                    onTap: () => context.push(
                        '/exercise/${widget.exerciseId}/record/${bestRecord.id}'),
                    onShare: () => context.push('/share/${bestRecord.id}'),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                ],

                // 2. Time cap (AMRAP only)
                if (rt == RecordType.amrap && exercise.timeCap != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border.all(
                          color: AppColors.separator, width: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          l10n.sectionTimeCap,
                          style: AppTypography.sectionLabel
                              .copyWith(color: AppColors.label2),
                        ),
                        const Spacer(),
                        Text(
                          UnitConverter.formatTimeCap(exercise.timeCap!),
                          style: AppTypography.cardTitle
                              .copyWith(color: AppColors.label1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                ],

                // 3. 1RM Calculator (weight only)
                if (rt == RecordType.weight && bestKg != null) ...[
                  _OneRMCalculator(
                    bestKg: bestKg,
                    weightUnit: weightUnit,
                    onViewTable: () => context
                        .push('/exercise/${widget.exerciseId}/1rm-table'),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                ],

                // 3. Add Record button
                _AddRecordButton(
                  onTap: () => showAddRecordSheet(context, ref, exercise),
                ),
                const SizedBox(height: AppSpacing.s24),

                // 4. History (only when there are records)
                if (rt != null && records.isNotEmpty)
                  _HistorySection(
                    records: records,
                    prRecordId: bestRecordId,
                    exercise: exercise,
                    weightUnit: weightUnit,
                    formatValue: (r) =>
                        _formatHistoryValue(r, rt, weightUnit),
                    onTap: (r) => context.push(
                        '/exercise/${widget.exerciseId}/record/${r.id}'),
                    onShare: (r) => context.push('/share/${r.id}'),
                    onDelete: (r) => ref
                        .read(recordsProvider(widget.exerciseId).notifier)
                        .deleteRecord(r.id),
                  ),

                const SizedBox(height: AppSpacing.s32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── _ExerciseHeader ──────────────────────────────────────────────────────────

class _ExerciseHeader extends StatelessWidget {
  final Exercise exercise;
  const _ExerciseHeader({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoryName = Category.nameForId(exercise.categoryId);
    return ScreenHeader(
      backLabel: l10n.back,
      titleWidget: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: exercise.displayName,
                    style: AppTypography.pageTitle.copyWith(
                      color: AppColors.label1,
                    ),
                  ),
                  if (categoryName.isNotEmpty)
                    TextSpan(
                      text: '  $categoryName',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.label2,
                      ),
                    ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => showEditExerciseSheet(context, exercise),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(AppIcons.settings, size: 20, color: AppColors.label2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _PbCard ──────────────────────────────────────────────────────────────────

class _PbCard extends StatelessWidget {
  final String valueText;
  final String dateText;
  final String pbLabel;
  final VoidCallback onTap;
  final VoidCallback onShare;

  const _PbCard({
    required this.valueText,
    required this.dateText,
    required this.pbLabel,
    required this.onTap,
    required this.onShare,
  });

  Widget _buildValue() {
    final parts = valueText.split(' × ');
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
      valueText,
      style: AppTypography.pbValue.copyWith(
        color: AppColors.label1, letterSpacing: -0.8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
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
                Row(
                  children: [
                    Text(
                      l10n.sectionPersonalBest,
                      style: AppTypography.sectionLabel.copyWith(
                        color: AppColors.label2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    PbBadge(label: pbLabel),
                  ],
                ),
                const SizedBox(height: 2),
                _buildValue(),
                const SizedBox(height: 2),
                Text(
                  dateText,
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.label2,
                  ),
                ),
              ],
            ),
            // Right — share button
            GestureDetector(
              onTap: onShare,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.share, size: 13, color: AppColors.label2),
                  const SizedBox(width: 4),
                  Text(
                    l10n.share,
                    style: const TextStyle(
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
    );
  }
}

// ── _OneRMCalculator ─────────────────────────────────────────────────────────

class _OneRMCalculator extends StatefulWidget {
  final double bestKg;
  final String weightUnit;
  final VoidCallback onViewTable;

  static const _quickPcts = [70, 75, 80, 85, 90, 95];

  const _OneRMCalculator({
    required this.bestKg,
    required this.weightUnit,
    required this.onViewTable,
  });

  @override
  State<_OneRMCalculator> createState() => _OneRMCalculatorState();
}

class _OneRMCalculatorState extends State<_OneRMCalculator> {
  final TextEditingController _pctCtrl = TextEditingController(text: '85');

  @override
  void dispose() {
    _pctCtrl.dispose();
    super.dispose();
  }

  double? get _parsedPct {
    final v = double.tryParse(_pctCtrl.text.trim());
    if (v == null || v <= 0 || v > 200) return null;
    return v;
  }

  int? get _activeChip {
    final pct = _parsedPct;
    if (pct == null) return null;
    for (final q in _OneRMCalculator._quickPcts) {
      if ((pct - q).abs() < 0.001) return q;
    }
    return null;
  }

  String _formatResult(double kg) {
    if (widget.weightUnit == 'lbs') return UnitConverter.formatWeight(kg, 'lbs');
    final rounded = (kg * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? '${rounded.toInt()} kg'
        : '${rounded.toStringAsFixed(1)} kg';
  }

  void _tapChip(int pct) {
    _pctCtrl.text = '$pct';
    _pctCtrl.selection = TextSelection.collapsed(offset: _pctCtrl.text.length);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pct = _parsedPct;
    final resultKg = pct != null ? widget.bestKg * pct / 100 : null;
    final resultDisplay = resultKg != null ? _formatResult(resultKg) : '—';
    final activeChip = _activeChip;

    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: AppSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.section1rmCalculator,
                style: AppTypography.sectionLabel
                    .copyWith(color: AppColors.label2),
              ),
              GestureDetector(
                onTap: widget.onViewTable,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.chart, size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      l10n.viewTable,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),

          // ── % chips ─────────────────────────────────────────────
          Row(
            children: _OneRMCalculator._quickPcts.map((pct) {
              final active = pct == activeChip;
              final isLast = pct == _OneRMCalculator._quickPcts.last;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 4),
                  child: GestureDetector(
                    onTap: () => _tapChip(pct),
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.chipSelected
                            : Colors.transparent,
                        border: Border.all(
                            color: AppColors.separator, width: 0.5),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(
                        child: Text(
                          '$pct%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? Colors.white
                                : AppColors.label2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.s12),

          // ── % input + result ─────────────────────────────────────
          // Aligned to chip grid (6 equal flex slots, 4px gaps).
          // Left spacer  = flex 1  → input left  == 75% chip left edge.
          // Content      = flex 4 + Padding(right:4) → result right == 90% chip right edge.
          // Right spacer = flex 1  → mirrors 95% chip slot.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mirrors 70% chip slot
              const Expanded(flex: 1, child: SizedBox()),
              // Content: chips[1]–[4] span, same 4px right gap as chip[4]
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // % input box — left edge == 75% chip left edge
                      Container(
                        width: 64,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _pctCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                textAlign: TextAlign.right,
                                cursorColor: AppColors.label1,
                                cursorWidth: 1.5,
                                cursorHeight: 14,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.label1,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  isDense: true,
                                  contentPadding: EdgeInsets.only(
                                      left: 6, top: 6, bottom: 6),
                                ),
                                onChanged: (_) => setState(() {}),
                                onTap: () => _pctCtrl.selection =
                                    TextSelection(
                                  baseOffset: 0,
                                  extentOffset: _pctCtrl.text.length,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 2, right: 7),
                              child: Text(
                                '%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.label2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Result — right edge == 90% chip right edge
                      Text(
                        resultDisplay,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.label1,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Mirrors 95% chip slot
              const Expanded(flex: 1, child: SizedBox()),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

// ── _AddRecordButton ─────────────────────────────────────────────────────────

class _AddRecordButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddRecordButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.actionDark,
          border: Border.all(color: AppColors.actionDarkBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16, vertical: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('+', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w300)),
            const SizedBox(width: AppSpacing.s8),
            Text(
              l10n.addRecordButton,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: -0.01 * 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _HistorySection ───────────────────────────────────────────────────────────

class _HistorySection extends StatelessWidget {
  final List<Record> records;
  final String? prRecordId;
  final Exercise exercise;
  final String weightUnit;
  final String Function(Record) formatValue;
  final void Function(Record) onTap;
  final void Function(Record) onShare;
  final void Function(Record) onDelete;

  const _HistorySection({
    required this.records,
    required this.prRecordId,
    required this.exercise,
    required this.weightUnit,
    required this.formatValue,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Text(
          l10n.sectionHistory,
          style: AppTypography.sectionLabel
              .copyWith(color: AppColors.label2),
        ),
        const SizedBox(height: AppSpacing.s8),

        // Card
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.separator, width: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
                  children: records.asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    final isPb = r.id == prRecordId;
                    final valueStr = formatValue(r);
                    final dateStr = DateFormatter.short(
                      DateTime.fromMillisecondsSinceEpoch(r.performedAt),
                    );
                    return Column(
                      children: [
                        SwipeableRow(
                          id: r.id,
                          onEdit: () => onTap(r),
                          onShare: () => onShare(r),
                          onDelete: () => _confirmDelete(context, r),
                          child: GestureDetector(
                            onTap: () => onTap(r),
                            behavior: HitTestBehavior.opaque,
                            child: _HistoryRowContent(
                            valueText: valueStr,
                            dateText: dateStr,
                            isPb: isPb,
                            pbLabel: exercise.bestTypeLabel,
                          ),
                          ),
                        ),
                        if (i < records.length - 1)
                          const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: AppColors.separatorAlt,
                            indent: AppSpacing.s20,
                            endIndent: AppSpacing.s20,
                          ),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, Record r) async {
    final l10n = AppLocalizations.of(context)!;
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
    if (confirmed == true) onDelete(r);
  }
}

// ── _HistoryRowContent ────────────────────────────────────────────────────────

class _HistoryRowContent extends StatelessWidget {
  final String valueText;
  final String dateText;
  final bool isPb;
  final String pbLabel;

  const _HistoryRowContent({
    required this.valueText,
    required this.dateText,
    required this.isPb,
    required this.pbLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s20, vertical: AppSpacing.s16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    valueText,
                    style: AppTypography.cardTitle.copyWith(
                      color: AppColors.textPrimaryAlt,
                    ),
                  ),
                  if (isPb) ...[
                    const SizedBox(width: AppSpacing.s8),
                    PbBadge(label: pbLabel),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                dateText,
                style: AppTypography.footnote.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          // Right — chevron
          Icon(AppIcons.forward,
              size: 16, color: AppColors.chevron),
        ],
      ),
    );
  }
}
