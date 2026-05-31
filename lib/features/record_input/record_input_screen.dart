import 'dart:math';
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
import 'time_input_field.dart';

class RecordInputScreen extends ConsumerStatefulWidget {
  final Exercise exercise;
  const RecordInputScreen({required this.exercise, super.key});

  @override
  ConsumerState<RecordInputScreen> createState() => _RecordInputScreenState();
}

class _RecordInputScreenState extends ConsumerState<RecordInputScreen> {
  final _valueController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _timeSeconds = 0;
  bool _saving = false;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(unitSettingsProvider).valueOrNull;
    final weightUnit = settings?.weightUnit ?? 'kg';
    final distanceUnit = settings?.distanceUnit ?? 'km';

    return Scaffold(
      appBar: AppBar(title: Text(widget.exercise.name)),
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
            if (widget.exercise.type == ExerciseType.time) ...[
              const Text('기록',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              TimeInputField(
                initialSeconds: _timeSeconds,
                onChanged: (s) => setState(() => _timeSeconds = s),
              ),
            ] else ...[
              TextField(
                controller: _valueController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                ],
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: '기록',
                  suffixText: widget.exercise.type == ExerciseType.weight
                      ? weightUnit
                      : distanceUnit,
                  suffixStyle: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 16),
                ),
              ),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: _saving ? null : () => _save(weightUnit, distanceUnit),
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

  Future<void> _save(String weightUnit, String distanceUnit) async {
    final exerciseId = widget.exercise.id!;
    double inputValueKg;

    if (widget.exercise.type == ExerciseType.time) {
      if (_timeSeconds == 0) return;
      inputValueKg = _timeSeconds.toDouble();
    } else {
      final raw = double.tryParse(_valueController.text.trim());
      if (raw == null || raw <= 0) return;
      if (widget.exercise.type == ExerciseType.weight) {
        inputValueKg = weightUnit == 'lbs'
            ? UnitConverter.lbsToKg(raw)
            : raw;
      } else {
        inputValueKg = distanceUnit == 'mi'
            ? UnitConverter.miToKm(raw)
            : raw;
      }
    }

    setState(() => _saving = true);

    final currentRecords =
        ref.read(recordsProvider(exerciseId)).valueOrNull ?? [];
    final previousBest = _getPreviousBest(currentRecords, widget.exercise.type);

    await ref
        .read(recordsProvider(exerciseId).notifier)
        .addRecord(inputValueKg, _selectedDate.millisecondsSinceEpoch ~/ 1000);

    if (!mounted) return;
    setState(() => _saving = false);

    final isPb = _isPb(inputValueKg, previousBest, widget.exercise.type);
    if (isPb) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PRCelebrationDialog(
          exercise: widget.exercise,
          newValue: inputValueKg,
          previousBest: previousBest,
          recordedDate: _selectedDate,
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  double? _getPreviousBest(List<Record> records, ExerciseType type) {
    if (records.isEmpty) return null;
    if (type == ExerciseType.time) {
      return records.map((r) => r.value).reduce(min);
    }
    return records.map((r) => r.value).reduce(max);
  }

  bool _isPb(double newValue, double? previousBest, ExerciseType type) {
    if (previousBest == null) return true;
    return type == ExerciseType.time
        ? newValue < previousBest
        : newValue > previousBest;
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  const _DatePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selected,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.accent,
                surface: AppTheme.card,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                color: AppTheme.accent, size: 18),
            const SizedBox(width: 12),
            Text(
              '${selected.year}.${selected.month.toString().padLeft(2, '0')}.${selected.day.toString().padLeft(2, '0')}',
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
