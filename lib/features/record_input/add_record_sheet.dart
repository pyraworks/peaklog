import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../widgets/screen_header.dart';
import '../../core/models/exercise.dart';
import '../../core/models/record.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/exercises_provider.dart';
import '../../providers/records_provider.dart';
import 'time_input_field.dart';
import '../../l10n/app_localizations.dart';

/// Opens the Add Record full-screen page for [exercise].
/// Pass [initialRecord] to pre-populate fields for editing an existing record.
Future<void> showAddRecordSheet(
    BuildContext context, WidgetRef ref, Exercise exercise,
    {Record? initialRecord}) {
  return Navigator.push<void>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) =>
          AddRecordSheet(exercise: exercise, initialRecord: initialRecord),
    ),
  );
}

class AddRecordSheet extends ConsumerStatefulWidget {
  final Exercise exercise;
  final Record? initialRecord;
  const AddRecordSheet({required this.exercise, this.initialRecord, super.key});

  @override
  ConsumerState<AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends ConsumerState<AddRecordSheet> {
  final _weightCtrl    = TextEditingController();
  final _repsCtrl      = TextEditingController(text: '1');
  final _distCtrl      = TextEditingController();
  final _roundsCtrl    = TextEditingController();
  final _amrapRepsCtrl = TextEditingController();
  final _etcUnitCtrl     = TextEditingController();
  final _durationMinCtrl = TextEditingController();
  int  _durationSec = 0;
  bool _saving      = false;
  bool _isPr        = false;
  bool _pbHigherIsBetter = true;
  DateTime _selectedDate = DateTime.now();
  RecordType? _localRecordType;
  String? _localWeightUnit;
  RecordType? get _effectiveType =>
      widget.exercise.recordType ?? _localRecordType;

  @override
  void initState() {
    super.initState();
    _pbHigherIsBetter = widget.exercise.pbHigherIsBetter;
    final r = widget.initialRecord;

    // Determine unit first — weight display conversion depends on it.
    // Always use the exercise's current default; never read the stale unit
    // cached on a previous record.
    if (widget.exercise.recordType == RecordType.weight) {
      _localWeightUnit = widget.exercise.baseUnit;
    }

    if (r != null) {
      if (r.weight != null) {
        final displayWeight = _localWeightUnit == 'lbs'
            ? UnitConverter.kgToLbs(r.weight!)
            : r.weight!;
        _weightCtrl.text = displayWeight
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'\.?0+$'), '');
      }
      if (r.reps != null) {
        _repsCtrl.text      = r.reps.toString();
        _amrapRepsCtrl.text = r.reps.toString();
      }
      if (r.rounds != null) _roundsCtrl.text = r.rounds.toString();
      if (r.distance != null) {
        _distCtrl.text = r.distance!
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'\.?0+$'), '');
      }
      _etcUnitCtrl.text = r.distanceUnit;
      _durationMinCtrl.text = r.durationMinutes?.toString()
          ?? widget.exercise.timeCap?.toString()
          ?? '';
      if (r.durationSeconds != null) _durationSec = r.durationSeconds!;
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(r.performedAt);
    }
    if (r == null && widget.exercise.recordType == RecordType.etc) {
      final unit = widget.exercise.baseUnit;
      if (unit != 'kg' && unit != 'lbs') _etcUnitCtrl.text = unit;
    }
    if (r == null && widget.exercise.recordType == RecordType.amrap &&
        widget.exercise.timeCap != null) {
      _durationMinCtrl.text = widget.exercise.timeCap.toString();
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _distCtrl.dispose();
    _roundsCtrl.dispose();
    _amrapRepsCtrl.dispose();
    _etcUnitCtrl.dispose();
    _durationMinCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _pickDate() async {
    final l10n = AppLocalizations.of(context)!;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: AppColors.card,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.done,
                      style: const TextStyle(color: AppColors.textPrimaryAlt)),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (d) => setState(() => _selectedDate = d),
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weightUnit = _localWeightUnit ?? widget.exercise.baseUnit;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            ScreenHeader(
              backLabel: l10n.back,
              title: widget.initialRecord != null ? l10n.editRecordTitle : l10n.addRecordTitle,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.exercise.recordType == null) ...[
                      _RecordTypePicker(
                        selected: _localRecordType,
                        onSelect: (rt) => setState(() {
                          _localRecordType = rt;
                          if (rt == RecordType.weight) {
                            _localWeightUnit ??= widget.exercise.baseUnit;
                          }
                        }),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                    ],

                    if (widget.exercise.recordType == null &&
                        widget.initialRecord == null &&
                        _localRecordType == RecordType.weight) ...[
                      _UnitPicker(
                        value: _localWeightUnit ?? widget.exercise.baseUnit,
                        options: const [('kg', 'kg'), ('lbs', 'lb')],
                        onChanged: (v) => setState(() => _localWeightUnit = v),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                    ],


                    if (_effectiveType != null) ...[
                      _DateButton(
                        date: _selectedDate,
                        formatDate: _formatDate,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      _buildInputs(weightUnit, l10n),
                      const SizedBox(height: AppSpacing.s16),
                      if (widget.initialRecord == null &&
                          !widget.exercise.hasPrBaseline) ...[
                        _PrCheckboxRow(
                          value: _isPr,
                          onChanged: (v) => setState(() => _isPr = v),
                          label: widget.exercise.bestTypeLabel,
                        ),
                        const SizedBox(height: AppSpacing.s16),
                      ],
                      _SaveButton(
                        label: l10n.saveRecord,
                        loading: _saving,
                        onPressed: _saving
                            ? null
                            : () {
                                FocusScope.of(context).unfocus();
                                _save(weightUnit);
                              },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputs(String weightUnit, AppLocalizations l10n) {
    switch (_effectiveType!) {
      case RecordType.weight:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InputCard(
                label: l10n.weightLabel,
                child: _NumTextField(
                  controller: _weightCtrl,
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InputCard(
                label: l10n.repsLabel,
                child: _NumTextField(
                  controller: _repsCtrl,
                  decimal: false,
                ),
              ),
            ),
          ],
        );

      case RecordType.etc:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InputCard(
              label: l10n.valueLabel,
              child: _NumTextField(controller: _distCtrl, decimal: true),
            ),
            const SizedBox(height: 10),
            _InputCard(
              label: l10n.unitOptionalLabel,
              child: TextField(
                controller: _etcUnitCtrl,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryAlt,
                  letterSpacing: -0.44,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  hintText: l10n.unitHint,
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    color: AppColors.label2,
                  ),
                ),
              ),
            ),
          ],
        );

      case RecordType.forTime:
        return _InputCard(
          label: l10n.timeLabel,
          child: TimeInputField(
            onChanged: (s) => _durationSec = s,
            initialSeconds: _durationSec,
          ),
        );

      case RecordType.amrap:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InputCard(
              label: l10n.timeCapLabel,
              child: _NumTextField(controller: _durationMinCtrl, decimal: false),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InputCard(
                    label: l10n.roundsLabel,
                    child: _NumTextField(
                      controller: _roundsCtrl,
                      decimal: false,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InputCard(
                    label: l10n.repsLabel,
                    child: _NumTextField(
                      controller: _amrapRepsCtrl,
                      decimal: false,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Future<bool?> _showPbDirectionSheet() {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PbDirectionSheet(initial: _pbHigherIsBetter),
    );
  }

  Future<void> _save(String weightUnit) async {
    final l10n = AppLocalizations.of(context)!;
    if (_effectiveType == RecordType.weight && _localWeightUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.validationSelectUnit)),
      );
      return;
    }

    double? weight;
    int?    reps;
    int?    rounds;
    int?    durationSeconds;
    int?    durationMinutes;
    double? distance;

    switch (_effectiveType!) {
      case RecordType.weight:
        final raw = double.tryParse(_weightCtrl.text.trim());
        if (raw == null || raw <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.validationEnterWeight)),
          );
          return;
        }
        weight = weightUnit == 'lbs' ? UnitConverter.lbsToKg(raw) : raw;
        reps   = max(1, int.tryParse(_repsCtrl.text.trim()) ?? 1);

      case RecordType.etc:
        final rawEtc = double.tryParse(_distCtrl.text.trim());
        if (rawEtc == null || rawEtc <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.validationEnterValue)),
          );
          return;
        }
        distance = rawEtc;

      case RecordType.forTime:
        if (_durationSec <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.validationEnterTime)),
          );
          return;
        }
        durationSeconds = _durationSec;

      case RecordType.amrap:
        final r = int.tryParse(_roundsCtrl.text.trim());
        if (r == null || r <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.validationEnterRounds)),
          );
          return;
        }
        rounds = r;
        final rawReps = int.tryParse(_amrapRepsCtrl.text.trim());
        if (rawReps != null && rawReps > 0) reps = rawReps;
        final cap = int.tryParse(_durationMinCtrl.text.trim());
        if (cap != null && cap > 0) durationMinutes = cap;
    }

    // Show PB direction picker once, before the first ETC record is saved.
    // After save, exercise.recordType == etc, so this condition is never true again.
    final isFirstEtcRecord = _effectiveType == RecordType.etc &&
        widget.initialRecord == null &&
        widget.exercise.recordType != RecordType.etc;

    if (isFirstEtcRecord) {
      final direction = await _showPbDirectionSheet();
      if (!mounted) return;
      if (direction == null) return; // dismissed without confirming — abort save
      _pbHigherIsBetter = direction;
    }

    setState(() => _saving = true);

    try {
      if (widget.exercise.recordType == null && _localRecordType != null) {
        await ref
            .read(exercisesProvider.notifier)
            .setRecordType(widget.exercise.id, _localRecordType!);
      }

      if (isFirstEtcRecord) {
        await ref
            .read(exercisesProvider.notifier)
            .updateExerciseSettings(widget.exercise.id,
                pbHigherIsBetter: _pbHigherIsBetter);
      }

      if (_localWeightUnit != null &&
          _localWeightUnit != widget.exercise.baseUnit) {
        await ref
            .read(exercisesProvider.notifier)
            .updateExerciseSettings(widget.exercise.id, baseUnit: _localWeightUnit!);
      }

      if (_effectiveType == RecordType.etc) {
        final etcUnit = _etcUnitCtrl.text.trim();
        if (etcUnit.isNotEmpty) {
          await ref
              .read(exercisesProvider.notifier)
              .updateExerciseSettings(widget.exercise.id, baseUnit: etcUnit);
        }
      }

      if (_effectiveType == RecordType.amrap && durationMinutes != null &&
          durationMinutes != widget.exercise.timeCap) {
        await ref
            .read(exercisesProvider.notifier)
            .updateExerciseSettings(widget.exercise.id, timeCap: durationMinutes);
      }

      final notifier =
          ref.read(recordsProvider(widget.exercise.id).notifier);

      if (widget.initialRecord != null) {
        await notifier.deleteRecord(widget.initialRecord!.id);
      }

      final performedAt = widget.initialRecord?.performedAt
          ?? _selectedDate.millisecondsSinceEpoch;

      final metadataJson = widget.initialRecord?.metadataJson;

      await notifier.addRecord(
        performedAt: performedAt,
        weight: weight,
        weightUnit: _effectiveType == RecordType.weight ? weightUnit : 'kg',
        reps: reps,
        rounds: rounds,
        durationSeconds: durationSeconds,
        distance: distance,
        distanceUnit: _effectiveType == RecordType.etc ? _etcUnitCtrl.text.trim() : '',
        durationMinutes: durationMinutes,
        metadataJson: metadataJson,
        timeCap: _effectiveType == RecordType.amrap
            ? (widget.initialRecord != null
                ? widget.initialRecord!.timeCap
                : durationMinutes)
            : null,
      );

      if (_isPr && !widget.exercise.hasPrBaseline) {
        await ref
            .read(exercisesProvider.notifier)
            .setPrBaseline(widget.exercise.id);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.saveFailed(e)),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── PB direction picker (first ETC record only) ───────────────────────────────

class _PbDirectionSheet extends StatefulWidget {
  final bool initial;
  const _PbDirectionSheet({required this.initial});

  @override
  State<_PbDirectionSheet> createState() => _PbDirectionSheetState();
}

class _PbDirectionSheetState extends State<_PbDirectionSheet> {
  late bool _higher;

  @override
  void initState() {
    super.initState();
    _higher = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.pbDirectionLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.label1,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 16),
            _PbOption(
              label: l10n.pbDirectionHigher,
              selected: _higher,
              onTap: () => setState(() => _higher = true),
            ),
            const SizedBox(height: 8),
            _PbOption(
              label: l10n.pbDirectionLower,
              selected: !_higher,
              onTap: () => setState(() => _higher = false),
            ),
            const SizedBox(height: 20),
            _SaveButton(
              label: l10n.done,
              onPressed: () => Navigator.pop(context, _higher),
            ),
          ],
        ),
      ),
    );
  }
}

class _PbOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PbOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(
            color: selected ? AppColors.label1 : AppColors.separator,
            width: selected ? 1.5 : 0.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? CupertinoIcons.largecircle_fill_circle
                  : CupertinoIcons.circle,
              size: 20,
              color: selected ? AppColors.label1 : AppColors.label3,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: AppColors.label1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Record type picker ────────────────────────────────────────────────────────

class _RecordTypePicker extends StatelessWidget {
  final RecordType? selected;
  final ValueChanged<RecordType> onSelect;
  const _RecordTypePicker({required this.selected, required this.onSelect});

  // Ordered by expected usage frequency
  static const _types = [
    (RecordType.weight,  Icons.fitness_center),
    (RecordType.amrap,   Icons.loop),
    (RecordType.forTime, Icons.timer),
    (RecordType.etc,     Icons.tag),
  ];

  String _typeLabel(RecordType rt, AppLocalizations l10n) => switch (rt) {
    RecordType.weight  => l10n.recordTypeWeight,
    RecordType.amrap   => l10n.recordTypeAmrap,
    RecordType.forTime => l10n.recordTypeForTime,
    RecordType.etc     => l10n.recordTypeEtc,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.howToTrackQuestion,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryAlt,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _types.map((t) {
            final sel = selected == t.$1;
            final isLast = t.$1 == RecordType.etc;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(t.$1),
                child: Container(
                  margin: EdgeInsets.only(right: isLast ? 0 : 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.actionDark
                        : AppColors.card,
                    border: Border.all(
                      color: sel
                          ? AppColors.actionDarkBorder
                          : AppColors.separator,
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.$2, size: 20, color: sel ? Colors.white : AppColors.label1),
                      const SizedBox(height: 4),
                      Text(
                        _typeLabel(t.$1, l10n),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: sel
                              ? Colors.white
                              : AppColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Shared UI primitives ──────────────────────────────────────────────────────

/// White bordered card with a label row + arbitrary child.
class _InputCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _InputCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
                top: 10, left: 16, right: 16, bottom: 3),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryAlt,
                letterSpacing: 0.44,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                top: 2, left: 16, right: 16, bottom: 11),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Plain numeric TextField styled 22px/w600 #24292E.
class _NumTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool decimal;
  const _NumTextField({required this.controller, required this.decimal});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        if (decimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryAlt,
        letterSpacing: -0.44,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );
  }
}


class _DateButton extends StatelessWidget {
  final DateTime date;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;
  const _DateButton(
      {required this.date, required this.formatDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.separator, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(l10n.dateLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondaryAlt,
                )),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                formatDate(date),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimaryAlt,
                ),
              ),
            ),
            Icon(AppIcons.caretDown,
                size: 16, color: AppColors.textSecondaryAlt),
          ],
        ),
      ),
    );
  }
}

// ── First-PR checkbox ─────────────────────────────────────────────────────────

class _PrCheckboxRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  const _PrCheckboxRow({required this.value, required this.onChanged, required this.label});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        onChanged(!value);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              value
                  ? CupertinoIcons.checkmark_square_fill
                  : CupertinoIcons.square,
              size: 20,
              color: AppColors.textPrimaryAlt,
            ),
            const SizedBox(width: 10),
            Text(
              l10n.thisIsMyLabel(label),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimaryAlt,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Save button ───────────────────────────────────────────────────────────────

class _UnitPicker extends StatelessWidget {
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;
  const _UnitPicker({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.unitSelectorLabel,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryAlt,
            letterSpacing: 0.64,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.separator, width: 0.5),
          ),
          child: Row(
            children: [
              for (int i = 0; i < options.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(options[i].$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.fromLTRB(
                        i == 0 ? 2 : 1, 2, i == options.length - 1 ? 2 : 1, 2,
                      ),
                      decoration: BoxDecoration(
                        color: value == options[i].$1
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: value == options[i].$1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          options[i].$2,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: value == options[i].$1
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: value == options[i].$1
                                ? AppColors.label1
                                : AppColors.textSecondaryAlt,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const _SaveButton({required this.label, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.actionDark,
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppColors.actionDarkBorder),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding:
              const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: -0.14,
                ),
              ),
      ),
    );
  }
}
