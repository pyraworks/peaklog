import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/records_provider.dart';
import '../../providers/unit_settings_provider.dart';

class OneRmPanel extends ConsumerStatefulWidget {
  final Exercise exercise;
  const OneRmPanel({required this.exercise, super.key});

  @override
  ConsumerState<OneRmPanel> createState() => _OneRmPanelState();
}

class _OneRmPanelState extends ConsumerState<OneRmPanel> {
  double _percent = 80;

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(recordsProvider(widget.exercise.id!)).valueOrNull ?? [];
    final unit = ref.watch(unitSettingsProvider).valueOrNull?.weightUnit ?? 'kg';

    double? bestKg;
    if (records.isNotEmpty) {
      bestKg = records.map((r) => r.value).reduce((a, b) => a > b ? a : b);
    }

    final calculated = bestKg != null ? bestKg * (_percent / 100) : null;
    final displayCalc = calculated != null
        ? UnitConverter.formatWeight(calculated, unit)
        : '—';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF222222),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1RM %',
            style: TextStyle(
                color: AppTheme.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _percent,
                    min: 0,
                    max: 120,
                    divisions: 120,
                    onChanged: (v) => setState(() => _percent = v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 48,
                child: Text(
                  '${_percent.toInt()}%',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                displayCalc,
                style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 22,
                    fontWeight: FontWeight.w900),
              ),
            ),
          ),
          if (bestKg == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('기록을 먼저 추가해주세요',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
