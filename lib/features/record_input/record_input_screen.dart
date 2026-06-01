import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise.dart';
import '../../core/models/record.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/records_provider.dart';
import '../../providers/unit_settings_provider.dart';
import 'pr_celebration_dialog.dart';

class RecordInputScreen extends ConsumerStatefulWidget {
  final Exercise exercise;
  const RecordInputScreen({required this.exercise, super.key});

  @override
  ConsumerState<RecordInputScreen> createState() => _RecordInputScreenState();
}

class _RecordInputScreenState extends ConsumerState<RecordInputScreen> {
  final _primaryController = TextEditingController();
  final _repsController = TextEditingController(text: '1');
  final _timeController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;
  String? _localWeightUnit;
  String _distanceUnit = 'km';
  String _timeUnit = 'sec';

  @override
  void dispose() {
    _primaryController.dispose();
    _repsController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(unitSettingsProvider).valueOrNull;
    final globalWeightUnit = settings?.weightUnit ?? 'kg';
    _localWeightUnit ??= globalWeightUnit;
    _distanceUnit = settings?.distanceUnit ?? 'km';
    final weightUnit = _localWeightUnit!;

    return Scaffold(
      appBar: AppBar(title: Text(widget.exercise.displayName)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DatePicker(
              selected: _selectedDate,
              onChanged: (d) => setState(() => _selectedDate = d),
            ),
            const SizedBox(height: 24),
            _buildInputFields(weightUnit),
            const Spacer(),
            ElevatedButton(
              onPressed: _saving ? null : () => _save(weightUnit),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFields(String weightUnit) {
    switch (widget.exercise.category) {
      case ExerciseCategory.strength:
        return Column(
          children: [
            _UnitRow(
              label: '단위',
              child: CupertinoSlidingSegmentedControl<String>(
                groupValue: weightUnit,
                thumbColor: AppTheme.card,
                backgroundColor: AppTheme.background,
                children: {
                  'kg': _seg('kg', weightUnit == 'kg'),
                  'lbs': _seg('lbs', weightUnit == 'lbs'),
                },
                onValueChanged: (v) {
                  if (v != null) setState(() => _localWeightUnit = v);
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _NumField(
                    controller: _primaryController,
                    label: '무게',
                    suffix: weightUnit,
                    decimal: true,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 88,
                  child: _NumField(
                    controller: _repsController,
                    label: '렙수',
                    suffix: '회',
                    decimal: false,
                  ),
                ),
              ],
            ),
          ],
        );

      case ExerciseCategory.running:
        return Column(
          children: [
            _NumField(
              controller: _primaryController,
              label: '거리',
              suffix: _distanceUnit,
              decimal: true,
            ),
            const SizedBox(height: 16),
            _UnitRow(
              label: '시간 단위',
              child: CupertinoSlidingSegmentedControl<String>(
                groupValue: _timeUnit,
                thumbColor: AppTheme.card,
                backgroundColor: AppTheme.background,
                children: {
                  'sec': _seg('초', _timeUnit == 'sec'),
                  'min': _seg('분', _timeUnit == 'min'),
                  'hour': _seg('시간', _timeUnit == 'hour'),
                },
                onValueChanged: (v) {
                  if (v != null) setState(() => _timeUnit = v);
                },
              ),
            ),
            const SizedBox(height: 16),
            _NumField(
              controller: _timeController,
              label: '시간 (선택)',
              suffix: _timeUnit == 'sec'
                  ? '초'
                  : _timeUnit == 'min'
                      ? '분'
                      : '시간',
              decimal: true,
            ),
          ],
        );

      case ExerciseCategory.workout:
        return Column(
          children: [
            _UnitRow(
              label: '단위',
              child: CupertinoSlidingSegmentedControl<String>(
                groupValue: _timeUnit,
                thumbColor: AppTheme.card,
                backgroundColor: AppTheme.background,
                children: {
                  'sec': _seg('초', _timeUnit == 'sec'),
                  'min': _seg('분', _timeUnit == 'min'),
                  'hour': _seg('시간', _timeUnit == 'hour'),
                },
                onValueChanged: (v) {
                  if (v != null) setState(() => _timeUnit = v);
                },
              ),
            ),
            const SizedBox(height: 16),
            _NumField(
              controller: _primaryController,
              label: '기록',
              suffix: _timeUnit == 'sec'
                  ? '초'
                  : _timeUnit == 'min'
                      ? '분'
                      : '시간',
              decimal: true,
            ),
          ],
        );

      case ExerciseCategory.custom:
        return _NumField(
          controller: _primaryController,
          label: '기록',
          suffix: '',
          decimal: true,
        );
    }
  }

  Widget _seg(String text, bool selected) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppTheme.accent : AppTheme.textPrimary,
          ),
        ),
      );

  int _toSeconds(double val, String unit) {
    switch (unit) {
      case 'min':
        return (val * 60).round();
      case 'hour':
        return (val * 3600).round();
      default:
        return val.round();
    }
  }

  Future<void> _save(String weightUnit) async {
    final raw = double.tryParse(_primaryController.text.trim());
    if (raw == null || raw <= 0) return;

    double? weight;
    int? reps;
    int? durationSeconds;
    double? distance;

    switch (widget.exercise.category) {
      case ExerciseCategory.strength:
        weight = weightUnit == 'lbs' ? UnitConverter.lbsToKg(raw) : raw;
        reps = max(1, int.tryParse(_repsController.text.trim()) ?? 1);

      case ExerciseCategory.running:
        distance = _distanceUnit == 'mi' ? UnitConverter.miToKm(raw) : raw;
        final rawTime = double.tryParse(_timeController.text.trim());
        if (rawTime != null && rawTime > 0) {
          durationSeconds = _toSeconds(rawTime, _timeUnit);
        }

      case ExerciseCategory.workout:
        durationSeconds = _toSeconds(raw, _timeUnit);

      case ExerciseCategory.custom:
        weight = raw;
    }

    setState(() => _saving = true);

    final currentRecords =
        ref.read(recordsProvider(widget.exercise.id)).valueOrNull ?? [];
    final previousBest =
        _getPreviousBest(currentRecords, widget.exercise.category);

    await ref.read(recordsProvider(widget.exercise.id).notifier).addRecord(
          performedAt: _selectedDate.millisecondsSinceEpoch,
          weight: weight,
          reps: reps,
          durationSeconds: durationSeconds,
          distance: distance,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    final newBestValue =
        weight ?? durationSeconds?.toDouble() ?? distance;
    final isPb = _isPb(
        newBestValue, previousBest, widget.exercise.category, reps);
    if (isPb && newBestValue != null) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PRCelebrationDialog(
          exercise: widget.exercise,
          newValue: newBestValue,
          previousBest: previousBest,
          recordedDate: _selectedDate,
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  double? _getPreviousBest(
      List<Record> records, ExerciseCategory category) {
    if (records.isEmpty) return null;
    switch (category) {
      case ExerciseCategory.strength:
        final oneRep = records
            .where(
                (r) => r.weight != null && (r.reps == null || r.reps == 1))
            .toList();
        if (oneRep.isEmpty) return null;
        return oneRep.map((r) => r.weight!).reduce(max);
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        final withTime =
            records.where((r) => r.durationSeconds != null).toList();
        if (withTime.isEmpty) return null;
        return withTime
            .map((r) => r.durationSeconds!.toDouble())
            .reduce(min);
      case ExerciseCategory.custom:
        return null;
    }
  }

  bool _isPb(double? newValue, double? previousBest,
      ExerciseCategory category, int? reps) {
    if (newValue == null) return false;
    if (category == ExerciseCategory.strength && (reps ?? 1) != 1) {
      return false;
    }
    if (previousBest == null) return true;
    switch (category) {
      case ExerciseCategory.strength:
        return newValue > previousBest;
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        return newValue < previousBest;
      case ExerciseCategory.custom:
        return false;
    }
  }
}

class _UnitRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _UnitRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5)),
        const Spacer(),
        child,
      ],
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final bool decimal;
  const _NumField(
      {required this.controller,
      required this.label,
      required this.suffix,
      required this.decimal});

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
          color: AppTheme.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix.isEmpty ? null : suffix,
        suffixStyle:
            const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;
  const _DatePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final label =
        '${selected.year}.${selected.month.toString().padLeft(2, '0')}.${selected.day.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.calendar,
                color: AppTheme.accent, size: 18),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(CupertinoIcons.chevron_right,
                color: AppTheme.textSecondary, size: 14),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    DateTime temp = selected;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 320,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              color: AppTheme.background,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소',
                        style:
                            TextStyle(color: AppTheme.textSecondary)),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      onChanged(temp);
                      Navigator.pop(context);
                    },
                    child: const Text('완료',
                        style: TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const Divider(
                height: 0.5,
                thickness: 0.5,
                color: AppTheme.separator),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: selected,
                maximumDate: DateTime.now(),
                minimumDate: DateTime(2000),
                onDateTimeChanged: (dt) => temp = dt,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
