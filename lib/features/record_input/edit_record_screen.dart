import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/database_helper.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../core/models/exercise.dart';
import '../../core/models/record.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/exercises_provider.dart';
import '../../providers/records_provider.dart';
import '../../widgets/screen_header.dart';
import 'time_input_field.dart';

class EditRecordScreen extends ConsumerStatefulWidget {
  final String exerciseId;
  final String recordId;
  const EditRecordScreen({
    required this.exerciseId,
    required this.recordId,
    super.key,
  });

  @override
  ConsumerState<EditRecordScreen> createState() => _EditRecordScreenState();
}

class _EditRecordScreenState extends ConsumerState<EditRecordScreen> {
  Record? _record;
  bool    _loading = true;
  bool    _saving  = false;

  // Shared
  DateTime _selectedDate = DateTime.now();

  // Weight
  final _weightCtrl = TextEditingController();
  final _repsCtrl   = TextEditingController(text: '1');
  String _weightUnit = 'kg';

  // For Time
  int _durationSec = 0;

  // AMRAP
  final _roundsCtrl    = TextEditingController();
  final _amrapRepsCtrl = TextEditingController();

  // ETC
  final _distCtrl    = TextEditingController();
  final _etcUnitCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await DatabaseHelper.instance.getRecordById(widget.recordId);
    if (!mounted) return;

    if (r != null) {
      final exercise = ref.read(exercisesProvider).valueOrNull
          ?.where((e) => e.id == widget.exerciseId)
          .firstOrNull;
      _initControllers(r, exercise);
    }

    setState(() {
      _record  = r;
      _loading = false;
    });
  }

  void _initControllers(Record rec, Exercise? exercise) {
    _selectedDate = DateTime.fromMillisecondsSinceEpoch(rec.performedAt);

    // Unit: read from the record snapshot only.
    // Record.fromMap normalizes null/empty to 'kg', so this is always valid.
    _weightUnit = rec.weightUnit;

    // Weight — convert stored kg to the original display unit.
    if (rec.weight != null) {
      final displayWeight = _weightUnit == 'lbs'
          ? UnitConverter.kgToLbs(rec.weight!)
          : rec.weight!;
      _weightCtrl.text = displayWeight
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'\.?0+$'), '');
    }
    if (rec.reps != null) _repsCtrl.text = rec.reps.toString();

    // For Time
    _durationSec = rec.durationSeconds ?? 0;

    // AMRAP
    if (rec.rounds != null) _roundsCtrl.text = rec.rounds.toString();
    if (rec.reps != null && exercise?.recordType == RecordType.amrap) {
      _amrapRepsCtrl.text = rec.reps.toString();
    }

    // ETC
    if (rec.distance != null) {
      _distCtrl.text = rec.distance!
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'\.?0+$'), '');
    }
    _etcUnitCtrl.text = rec.distanceUnit;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _roundsCtrl.dispose();
    _amrapRepsCtrl.dispose();
    _distCtrl.dispose();
    _etcUnitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = ref.watch(
      exercisesProvider.select(
        (s) => s.valueOrNull?.where((e) => e.id == widget.exerciseId).firstOrNull,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            const ScreenHeader(backLabel: 'Back', title: 'Edit Record'),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_record == null)
              const Expanded(child: Center(child: Text('Record not found')))
            else if (exercise == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (exercise.recordType == null)
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No record type is configured for this exercise.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.label2,
                      ),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DateButton(date: _selectedDate, onTap: _pickDate),
                      const SizedBox(height: AppSpacing.s12),
                      _buildInputs(exercise.recordType!),
                      const SizedBox(height: 24),
                      _SaveButton(
                        loading: _saving,
                        onPressed: _saving
                            ? null
                            : () {
                                FocusScope.of(context).unfocus();
                                _save(exercise);
                              },
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      _DeleteButton(onPressed: () => _confirmDelete(context)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Input panels per RecordType ───────────────────────────────────────────

  Widget _buildInputs(RecordType rt) {
    switch (rt) {
      case RecordType.weight:
        final unitLabel = _weightUnit == 'lbs' ? 'lb' : _weightUnit;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _InputCard(
                label: 'WEIGHT ($unitLabel)',
                child: _NumTextField(controller: _weightCtrl, decimal: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InputCard(
                label: 'REPS',
                child: _NumTextField(controller: _repsCtrl, decimal: false),
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
        final timeCap = _record?.timeCap;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (timeCap != null) ...[
              _ReadOnlyCard(
                label: 'TIME CAP',
                value: UnitConverter.formatTimeCap(timeCap),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InputCard(
                    label: 'ROUNDS',
                    child: _NumTextField(controller: _roundsCtrl, decimal: false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InputCard(
                    label: 'REPS',
                    child: _NumTextField(controller: _amrapRepsCtrl, decimal: false),
                  ),
                ),
              ],
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
                  hintStyle: TextStyle(fontSize: 16, color: AppColors.label2),
                ),
              ),
            ),
          ],
        );
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

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

  Future<void> _save(Exercise exercise) async {
    final record = _record;
    if (record == null) return;
    final rt = exercise.recordType;
    if (rt == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final performedAt = _selectedDate.millisecondsSinceEpoch;
    Record updated;

    switch (rt) {
      case RecordType.weight:
        final raw = double.tryParse(_weightCtrl.text.trim());
        if (raw == null || raw <= 0) {
          _showSnack('Enter a weight to save.');
          return;
        }
        final weightKg =
            _weightUnit == 'lbs' ? UnitConverter.lbsToKg(raw) : raw;
        final reps = max(1, int.tryParse(_repsCtrl.text.trim()) ?? 1);
        updated = record.copyWith(
          weight: weightKg,
          reps: reps,
          performedAt: performedAt,
          updatedAt: now,
        );

      case RecordType.forTime:
        if (_durationSec <= 0) {
          _showSnack('Enter a time to save.');
          return;
        }
        updated = record.copyWith(
          durationSeconds: _durationSec,
          performedAt: performedAt,
          updatedAt: now,
        );

      case RecordType.amrap:
        final rounds = int.tryParse(_roundsCtrl.text.trim());
        if (rounds == null || rounds <= 0) {
          _showSnack('Enter rounds completed.');
          return;
        }
        final extraReps = int.tryParse(_amrapRepsCtrl.text.trim());
        updated = record.copyWith(
          rounds: rounds,
          // null clears an existing reps value when the user empties the field
          reps: (extraReps != null && extraReps > 0) ? extraReps : null,
          performedAt: performedAt,
          updatedAt: now,
        );

      case RecordType.etc:
        final rawVal = double.tryParse(_distCtrl.text.trim());
        if (rawVal == null || rawVal <= 0) {
          _showSnack('Enter a value to save.');
          return;
        }
        updated = record.copyWith(
          distance: rawVal,
          distanceUnit: _etcUnitCtrl.text.trim(),
          performedAt: performedAt,
          updatedAt: now,
        );
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(recordsProvider(widget.exerciseId).notifier)
          .updateRecord(updated);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) _showSnack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
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

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }
}

// ── Shared UI primitives ──────────────────────────────────────────────────────

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
            padding:
                const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 3),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryAlt,
                letterSpacing: 0.44,
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(top: 2, left: 16, right: 16, bottom: 11),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Read-only card used for the AMRAP time cap snapshot.
class _ReadOnlyCard extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryAlt,
              letterSpacing: 0.44,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryAlt,
              letterSpacing: -0.44,
            ),
          ),
        ],
      ),
    );
  }
}

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
  final VoidCallback onTap;
  const _DateButton({required this.date, required this.onTap});

  String get _label {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

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
            const Text(
              'Date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondaryAlt,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _label,
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

class _SaveButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  const _SaveButton({required this.loading, required this.onPressed});

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(
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

class _DeleteButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _DeleteButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Delete Record',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.destructive,
            ),
          ),
        ),
      ),
    );
  }
}
