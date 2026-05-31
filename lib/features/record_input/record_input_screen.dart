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
  final _valueController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  // weight: kg / lbs (로컬 선택, null이면 글로벌 따라감)
  String? _localWeightUnit;

  // time: 'sec' / 'min' / 'hour'
  String _timeUnit = 'sec';

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(unitSettingsProvider).valueOrNull;
    final globalWeightUnit = settings?.weightUnit ?? 'kg';
    final distanceUnit = settings?.distanceUnit ?? 'km';

    // 로컬 단위가 설정되지 않았으면 글로벌 값으로 초기화
    _localWeightUnit ??= globalWeightUnit;
    final weightUnit = _localWeightUnit!;

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
            if (widget.exercise.type == ExerciseType.weight) ...[
              _UnitLabel(
                label: '단위',
                trailing: CupertinoSlidingSegmentedControl<String>(
                  groupValue: weightUnit,
                  thumbColor: AppTheme.card,
                  backgroundColor: AppTheme.background,
                  children: {
                    'kg': _segItem('kg', weightUnit == 'kg'),
                    'lbs': _segItem('lbs', weightUnit == 'lbs'),
                  },
                  onValueChanged: (v) {
                    if (v != null) setState(() => _localWeightUnit = v);
                  },
                ),
              ),
              const SizedBox(height: 16),
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
                  suffixText: weightUnit,
                  suffixStyle: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 16),
                ),
              ),
            ] else if (widget.exercise.type == ExerciseType.time) ...[
              _UnitLabel(
                label: '단위',
                trailing: CupertinoSlidingSegmentedControl<String>(
                  groupValue: _timeUnit,
                  thumbColor: AppTheme.card,
                  backgroundColor: AppTheme.background,
                  children: {
                    'sec': _segItem('초', _timeUnit == 'sec'),
                    'min': _segItem('분', _timeUnit == 'min'),
                    'hour': _segItem('시간', _timeUnit == 'hour'),
                  },
                  onValueChanged: (v) {
                    if (v != null) setState(() => _timeUnit = v);
                  },
                ),
              ),
              const SizedBox(height: 16),
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
                  suffixText: _timeUnit == 'sec'
                      ? '초'
                      : _timeUnit == 'min'
                          ? '분'
                          : '시간',
                  suffixStyle: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 16),
                ),
              ),
            ] else ...[
              // distance
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
                  suffixText: distanceUnit,
                  suffixStyle: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 16),
                ),
              ),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: _saving
                  ? null
                  : () => _save(weightUnit, distanceUnit),
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

  Widget _segItem(String text, bool selected) => Padding(
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

  Future<void> _save(String weightUnit, String distanceUnit) async {
    final exerciseId = widget.exercise.id!;
    double inputValueKg;

    final raw = double.tryParse(_valueController.text.trim());

    if (widget.exercise.type == ExerciseType.time) {
      if (raw == null || raw <= 0) return;
      switch (_timeUnit) {
        case 'min':
          inputValueKg = raw * 60;
        case 'hour':
          inputValueKg = raw * 3600;
        default:
          inputValueKg = raw;
      }
    } else {
      if (raw == null || raw <= 0) return;
      if (widget.exercise.type == ExerciseType.weight) {
        inputValueKg =
            weightUnit == 'lbs' ? UnitConverter.lbsToKg(raw) : raw;
      } else {
        inputValueKg =
            distanceUnit == 'mi' ? UnitConverter.miToKm(raw) : raw;
      }
    }

    setState(() => _saving = true);

    final currentRecords =
        ref.read(recordsProvider(exerciseId)).valueOrNull ?? [];
    final previousBest =
        _getPreviousBest(currentRecords, widget.exercise.type);

    await ref
        .read(recordsProvider(exerciseId).notifier)
        .addRecord(inputValueKg,
            _selectedDate.millisecondsSinceEpoch ~/ 1000);

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

// ── 단위 레이블 행 ─────────────────────────────────────────────

class _UnitLabel extends StatelessWidget {
  final String label;
  final Widget trailing;
  const _UnitLabel({required this.label, required this.trailing});

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
        trailing,
      ],
    );
  }
}

// ── 날짜 선택기 ────────────────────────────────────────────────

class _DatePicker extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  const _DatePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final label =
        '${selected.year}.${selected.month.toString().padLeft(2, '0')}.${selected.day.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => _showCupertinoPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.calendar,
                color: AppTheme.accent, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(CupertinoIcons.chevron_right,
                color: AppTheme.textSecondary, size: 14),
          ],
        ),
      ),
    );
  }

  void _showCupertinoPicker(BuildContext context) {
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
