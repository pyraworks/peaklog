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
  DateTime _selectedDate = DateTime.now();
  RecordType? _localRecordType;
  String? _localWeightUnit;
  RecordType? get _effectiveType =>
      widget.exercise.recordType ?? _localRecordType;

  @override
  void initState() {
    super.initState();
    final r = widget.initialRecord;
    if (r != null) {
      if (r.weight != null) {
        _weightCtrl.text = r.weight!
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
      _durationMinCtrl.text = r.durationMinutes?.toString() ?? '';
      if (r.durationSeconds != null) _durationSec = r.durationSeconds!;
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(r.performedAt);
    }
    if (r == null && widget.exercise.recordType == RecordType.etc) {
      _etcUnitCtrl.text = widget.exercise.baseUnit;
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
                  child: const Text('Done',
                      style: TextStyle(color: AppColors.textPrimaryAlt)),
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
    final weightUnit = _localWeightUnit ?? widget.exercise.baseUnit;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            ScreenHeader(
              backLabel: 'Back',
              title: widget.initialRecord != null ? 'Edit Record' : 'Add Record',
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
                        onSelect: (rt) => setState(() => _localRecordType = rt),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                    ],

                    if (widget.exercise.recordType == null &&
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
                      _buildInputs(weightUnit),
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
                        label: 'Save Record',
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

  Widget _buildInputs(String weightUnit) {
    switch (_effectiveType!) {
      case RecordType.weight:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _InputCard(
                label: 'WEIGHT',
                child: _NumTextField(
                  controller: _weightCtrl,
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InputCard(
                label: 'REPS',
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
              label: 'VALUE',
              child: _NumTextField(controller: _distCtrl, decimal: true),
            ),
            const SizedBox(height: 10),
            _InputCard(
              label: 'UNIT (optional)',
              child: TextField(
                controller: _etcUnitCtrl,
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
                  hintText: 'e.g. reps, kg, km',
                  hintStyle: TextStyle(
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
          label: 'TIME',
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
              label: 'TIME CAP (min)',
              child: _NumTextField(controller: _durationMinCtrl, decimal: false),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InputCard(
                    label: 'ROUNDS',
                    child: _NumTextField(
                      controller: _roundsCtrl,
                      decimal: false,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InputCard(
                    label: 'REPS',
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

  Future<void> _save(String weightUnit) async {
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
            const SnackBar(content: Text('Enter a weight to save.')),
          );
          return;
        }
        weight = weightUnit == 'lbs' ? UnitConverter.lbsToKg(raw) : raw;
        reps   = max(1, int.tryParse(_repsCtrl.text.trim()) ?? 1);

      case RecordType.etc:
        final rawEtc = double.tryParse(_distCtrl.text.trim());
        if (rawEtc == null || rawEtc <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a value to save.')),
          );
          return;
        }
        distance = rawEtc;

      case RecordType.forTime:
        if (_durationSec <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a time to save.')),
          );
          return;
        }
        durationSeconds = _durationSec;

      case RecordType.amrap:
        final r = int.tryParse(_roundsCtrl.text.trim());
        if (r == null || r <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter rounds completed.')),
          );
          return;
        }
        rounds = r;
        final rawReps = int.tryParse(_amrapRepsCtrl.text.trim());
        if (rawReps != null && rawReps > 0) reps = rawReps;
        final cap = int.tryParse(_durationMinCtrl.text.trim());
        if (cap != null && cap > 0) durationMinutes = cap;
    }

    setState(() => _saving = true);

    try {
      if (widget.exercise.recordType == null && _localRecordType != null) {
        await ref
            .read(exercisesProvider.notifier)
            .setRecordType(widget.exercise.id, _localRecordType!);
      }

      if (widget.exercise.recordType == null && _localWeightUnit != null) {
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
        reps: reps,
        rounds: rounds,
        durationSeconds: durationSeconds,
        distance: distance,
        distanceUnit: _effectiveType == RecordType.etc ? _etcUnitCtrl.text.trim() : '',
        durationMinutes: durationMinutes,
        metadataJson: metadataJson,
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
            content: Text('Save failed: $e'),
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

// ── Record type picker ────────────────────────────────────────────────────────

class _RecordTypePicker extends StatelessWidget {
  final RecordType? selected;
  final ValueChanged<RecordType> onSelect;
  const _RecordTypePicker({required this.selected, required this.onSelect});

  // Ordered by expected usage frequency
  static const _types = [
    (RecordType.weight,   '🏋️', 'Weight'),
    (RecordType.amrap,    '🔁', 'AMRAP'),
    (RecordType.forTime,  '⏱',  'For Time'),
    (RecordType.etc, '🔢', 'ETC'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How do you track this exercise?',
          style: TextStyle(
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
                      Text(t.$2, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(
                        t.$3,
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
            const Text('Date',
                style: TextStyle(
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
              'This is my $label!',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'UNIT',
          style: TextStyle(
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
