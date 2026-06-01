import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise.dart';
import '../../core/models/record.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/records_provider.dart';
import '../../providers/unit_settings_provider.dart';

class HistoryScreen extends ConsumerWidget {
  final Exercise exercise;
  const HistoryScreen({required this.exercise, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsProvider(exercise.id));
    final settings = ref.watch(unitSettingsProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(exercise.displayName)),
      body: recordsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.accent)),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Text('기록이 없습니다',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 16)),
            );
          }
          final bestValue = _getBestValue(records, exercise.category);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (_, i) => _RecordTile(
              record: records[i],
              exercise: exercise,
              isBest: _isBest(records[i], bestValue, exercise.category),
              settings: settings,
              onDelete: () => ref
                  .read(recordsProvider(exercise.id).notifier)
                  .deleteRecord(records[i].id),
            ),
          );
        },
      ),
    );
  }

  double? _getBestValue(List<Record> records, ExerciseCategory category) {
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

  bool _isBest(
      Record r, double? bestValue, ExerciseCategory category) {
    if (bestValue == null) return false;
    switch (category) {
      case ExerciseCategory.strength:
        return r.weight == bestValue &&
            (r.reps == null || r.reps == 1);
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        return r.durationSeconds?.toDouble() == bestValue;
      case ExerciseCategory.custom:
        return false;
    }
  }
}

class _RecordTile extends StatelessWidget {
  final Record record;
  final Exercise exercise;
  final bool isBest;
  final UnitSettings? settings;
  final VoidCallback onDelete;

  const _RecordTile({
    required this.record,
    required this.exercise,
    required this.isBest,
    required this.settings,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date =
        DateTime.fromMillisecondsSinceEpoch(record.performedAt);
    final dateStr =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    final displayValue = _formatValue();

    return Dismissible(
      key: Key('record_${record.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('기록 삭제'),
            content: const Text('이 기록을 삭제할까요?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('취소',
                      style:
                          TextStyle(color: AppTheme.textSecondary))),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('삭제',
                      style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: isBest
              ? Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr,
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(displayValue,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            if (isBest)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('PB',
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900)),
              ),
          ],
        ),
      ),
    );
  }

  String _formatValue() {
    switch (exercise.category) {
      case ExerciseCategory.strength:
        final w = UnitConverter.formatWeight(
            record.weight ?? 0, settings?.weightUnit ?? 'kg');
        return (record.reps != null && record.reps! > 1)
            ? '$w × ${record.reps}회'
            : w;
      case ExerciseCategory.running:
        final parts = <String>[];
        if (record.distance != null) {
          parts.add(UnitConverter.formatDistance(
              record.distance!, settings?.distanceUnit ?? 'km'));
        }
        if (record.durationSeconds != null) {
          parts.add(
              UnitConverter.secondsToDisplay(record.durationSeconds!));
        }
        return parts.join('  ');
      case ExerciseCategory.workout:
        return UnitConverter.secondsToDisplay(
            record.durationSeconds ?? 0);
      case ExerciseCategory.custom:
        if (record.weight != null) {
          return UnitConverter.formatWeight(
              record.weight!, settings?.weightUnit ?? 'kg');
        }
        if (record.durationSeconds != null) {
          return UnitConverter.secondsToDisplay(
              record.durationSeconds!);
        }
        return '—';
    }
  }
}
