import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise.dart';
import '../../core/models/record.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/records_provider.dart';
import '../../providers/unit_settings_provider.dart';

class CompareScreen extends ConsumerWidget {
  final Exercise exercise;
  const CompareScreen({required this.exercise, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records =
        ref.watch(recordsProvider(exercise.id)).valueOrNull ?? [];
    final settings = ref.watch(unitSettingsProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text('${exercise.displayName} — 비교')),
      body: Column(
        children: [
          const Divider(
              height: 0.5, thickness: 0.5, color: AppTheme.separator),
          if (records.isEmpty)
            const Expanded(
              child: Center(
                child: Text('기록이 없습니다',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 15)),
              ),
            )
          else
            Expanded(
              child: _CompareBody(
                exercise: exercise,
                records: records,
                settings: settings,
              ),
            ),
        ],
      ),
    );
  }
}

class _CompareBody extends StatelessWidget {
  final Exercise exercise;
  final List<Record> records;
  final UnitSettings? settings;

  const _CompareBody({
    required this.exercise,
    required this.records,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final latest = records.first;
    final latestVal = _getValue(latest);
    final latestDate = _dateStr(latest.performedAt);

    final rest = records.skip(1).toList();
    final prevBestRecord = _getBest(rest);
    final prevVal =
        prevBestRecord != null ? _getValue(prevBestRecord) : null;
    final prevDate = prevBestRecord != null
        ? _dateStr(prevBestRecord.performedAt)
        : null;

    String? diffStr;
    Color diffColor = AppTheme.textSecondary;
    if (latestVal != null && prevVal != null) {
      final diff = latestVal - prevVal;
      final improved = exercise.category == ExerciseCategory.strength
          ? diff > 0
          : diff < 0;
      diffColor = improved
          ? const Color(0xFF34C759)
          : diff == 0
              ? AppTheme.textSecondary
              : const Color(0xFFFF3B30);
      diffStr = _formatDiff(diff);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('최근 기록',
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        child: Text('이전 PB',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        child: Text('차이',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
                const Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: AppTheme.separator),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              latestVal != null
                                  ? _format(latestVal)
                                  : '—',
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3),
                            ),
                            const SizedBox(height: 4),
                            Text(latestDate,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              prevVal != null ? _format(prevVal) : '—',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3),
                            ),
                            const SizedBox(height: 4),
                            Text(prevDate ?? '—',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          diffStr ?? '—',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: diffColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (records.length < 2) ...[
            const SizedBox(height: 24),
            const Text(
              '이전 기록이 없습니다.\n기록을 2개 이상 추가하면 비교할 수 있어요.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  double? _getValue(Record r) {
    switch (exercise.category) {
      case ExerciseCategory.strength:
        if (r.weight != null && (r.reps == null || r.reps == 1)) {
          return r.weight;
        }
        return null;
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        return r.durationSeconds?.toDouble();
      case ExerciseCategory.custom:
        return r.weight;
    }
  }

  Record? _getBest(List<Record> records) {
    final valid = records.where((r) => _getValue(r) != null).toList();
    if (valid.isEmpty) return null;
    switch (exercise.category) {
      case ExerciseCategory.strength:
      case ExerciseCategory.custom:
        return valid.reduce((a, b) =>
            (_getValue(a) ?? 0) >= (_getValue(b) ?? 0) ? a : b);
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        return valid.reduce((a, b) =>
            (_getValue(a) ?? double.maxFinite) <=
                    (_getValue(b) ?? double.maxFinite)
                ? a
                : b);
    }
  }

  String _format(double value) {
    switch (exercise.category) {
      case ExerciseCategory.strength:
        return UnitConverter.formatWeight(
            value, settings?.weightUnit ?? 'kg');
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        return UnitConverter.secondsToDisplay(value.toInt());
      case ExerciseCategory.custom:
        return value.toStringAsFixed(1);
    }
  }

  String _formatDiff(double diff) {
    switch (exercise.category) {
      case ExerciseCategory.strength:
        return UnitConverter.formatDiffWeight(
            diff, settings?.weightUnit ?? 'kg');
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        return UnitConverter.formatDiffTime(diff.toInt());
      case ExerciseCategory.custom:
        final sign = diff >= 0 ? '+' : '';
        return '$sign${diff.toStringAsFixed(1)}';
    }
  }

  String _dateStr(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }
}
