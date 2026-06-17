import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/screen_header.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/record.dart';
import '../../providers/records_provider.dart';

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
  bool _loading = true;
  bool _saving = false;

  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    final r = await DatabaseHelper.instance.getRecordById(widget.recordId);
    if (!mounted) return;
    if (r != null) {
      _weightCtrl.text = r.weight?.toString() ?? '';
      _repsCtrl.text = (r.reps ?? 1).toString();
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(r.performedAt);
    }
    setState(() {
      _record = r;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const ScreenHeader(backLabel: 'Back', title: 'Edit Record'),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_record == null)
            const Expanded(
                child: Center(child: Text('Record not found')))
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DateCard(
                      selected: _selectedDate,
                      onChanged: (d) => setState(() => _selectedDate = d),
                    ),
                    const SizedBox(height: 12),
                    _WeightRepsCard(
                      weightCtrl: _weightCtrl,
                      repsCtrl: _repsCtrl,
                    ),
                    const SizedBox(height: 24),
                    _SaveButton(
                      loading: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                    const SizedBox(height: 12),
                    _DeleteButton(onPressed: () => _confirmDelete(context)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
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

  Future<void> _save() async {
    final record = _record;
    if (record == null) return;
    final weight = double.tryParse(_weightCtrl.text.trim());
    final reps = max(1, int.tryParse(_repsCtrl.text.trim()) ?? 1);
    if (weight == null || weight <= 0) return;

    setState(() => _saving = true);
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = record.copyWith(
      weight: weight,
      reps: reps,
      performedAt: _selectedDate.millisecondsSinceEpoch,
      updatedAt: now,
    );
    await ref
        .read(recordsProvider(widget.exerciseId).notifier)
        .updateRecord(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    context.pop();
  }

}

// ── _DateCard ─────────────────────────────────────────────────────────────────

class _DateCard extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;
  const _DateCard({required this.selected, required this.onChanged});

  String get _label =>
      '${selected.year}.${selected.month.toString().padLeft(2, '0')}.${selected.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.separatorAlt),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(AppIcons.calendar,
                size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimaryAlt,
                ),
              ),
            ),
            Icon(AppIcons.caretDown,
                size: 12, color: AppColors.textSecondaryAlt),
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
              color: AppColors.background,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.textTertiary)),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      onChanged(temp);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

// ── _WeightRepsCard ────────────────────────────────────────────────────────────

class _WeightRepsCard extends StatelessWidget {
  final TextEditingController weightCtrl;
  final TextEditingController repsCtrl;
  const _WeightRepsCard(
      {required this.weightCtrl, required this.repsCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.separatorAlt),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _InputField(
              controller: weightCtrl,
              label: 'WEIGHT',
              suffix: 'kg',
              decimal: true,
            ),
          ),
          Container(
              width: 1,
              height: 80,
              color: AppColors.separatorAlt),
          Expanded(
            child: _InputField(
              controller: repsCtrl,
              label: 'REPS',
              suffix: '회',
              decimal: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final bool decimal;
  const _InputField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.decimal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryAlt,
              letterSpacing: 0.64,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.numberWithOptions(
                    decimal: decimal),
                inputFormatters: [
                  if (decimal)
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'))
                  else
                    FilteringTextInputFormatter.digitsOnly,
                ],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryAlt,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      EdgeInsets.fromLTRB(16, 2, 8, 12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                suffix,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondaryAlt),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── _SaveButton ───────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  const _SaveButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.actionDark,
          border: Border.all(color: AppColors.actionDarkBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
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
                    letterSpacing: -0.15,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── _DeleteButton ─────────────────────────────────────────────────────────────

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
            '🗑 Delete Record',
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

