import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise.dart';
import '../../core/models/record.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/records_provider.dart';
import '../../providers/unit_settings_provider.dart';
import '../home/one_rm_panel.dart';
import '../record_input/record_input_screen.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final Exercise exercise;
  const ExerciseDetailScreen({required this.exercise, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records =
        ref.watch(recordsProvider(exercise.id)).valueOrNull ?? [];
    final settings = ref.watch(unitSettingsProvider).valueOrNull;
    final bestValue = _getBestValue(records, exercise.category);

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.displayName),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      RecordInputScreen(exercise: exercise)),
            ),
            child: const Text(
              '기록 추가',
              style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(
              height: 0.5, thickness: 0.5, color: AppTheme.separator),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _StatsCard(
                    exercise: exercise,
                    records: records,
                    settings: settings,
                    bestValue: bestValue,
                  ),
                ),
                if (exercise.category == ExerciseCategory.strength) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                  SliverToBoxAdapter(
                      child: OneRmPanel(exercise: exercise)),
                ],
                const SliverToBoxAdapter(
                    child: _SectionLabel('기록 히스토리')),
                if (records.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      child: Center(
                        child: Text('아직 기록이 없어요',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 15)),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final r = records[i];
                          return _HistoryTile(
                            record: r,
                            exercise: exercise,
                            isBest: _isBestRecord(
                                r, records, exercise.category),
                            settings: settings,
                            isLast: i == records.length - 1,
                            onDelete: () => ref
                                .read(recordsProvider(exercise.id)
                                    .notifier)
                                .deleteRecord(r.id),
                          );
                        },
                        childCount: records.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double? _getBestValue(
      List<Record> records, ExerciseCategory category) {
    if (records.isEmpty) return null;
    switch (category) {
      case ExerciseCategory.strength:
        final oneRep = records
            .where((r) =>
                r.weight != null && (r.reps == null || r.reps == 1))
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

  bool _isBestRecord(
      Record r, List<Record> all, ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.strength:
        if (r.weight == null) return false;
        final oneRep = all
            .where((x) =>
                x.weight != null && (x.reps == null || x.reps == 1))
            .toList();
        if (oneRep.isEmpty) return false;
        final best = oneRep.map((x) => x.weight!).reduce(max);
        return r.weight == best && (r.reps == null || r.reps == 1);
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        if (r.durationSeconds == null) return false;
        final withTime =
            all.where((x) => x.durationSeconds != null).toList();
        if (withTime.isEmpty) return false;
        final best =
            withTime.map((x) => x.durationSeconds!).reduce(min);
        return r.durationSeconds == best;
      case ExerciseCategory.custom:
        return false;
    }
  }
}

class _StatsCard extends StatelessWidget {
  final Exercise exercise;
  final List<Record> records;
  final UnitSettings? settings;
  final double? bestValue;

  const _StatsCard({
    required this.exercise,
    required this.records,
    required this.settings,
    required this.bestValue,
  });

  @override
  Widget build(BuildContext context) {
    final displayBest = _formatValue(bestValue);
    final daysSince = _daysSince();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                exercise.category.label.toUpperCase(),
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('최고 기록',
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            displayBest,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(daysSince,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatValue(double? v) {
    if (v == null) return '—';
    switch (exercise.category) {
      case ExerciseCategory.strength:
        return UnitConverter.formatWeight(
            v, settings?.weightUnit ?? 'kg');
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        return UnitConverter.secondsToDisplay(v.toInt());
      case ExerciseCategory.custom:
        return v.toStringAsFixed(1);
    }
  }

  String _daysSince() {
    if (records.isEmpty) return '기록 없음';
    if (exercise.category == ExerciseCategory.strength) {
      final oneRep = records
          .where((r) =>
              r.weight != null && (r.reps == null || r.reps == 1))
          .toList();
      if (oneRep.isEmpty) return '기록 없음';
      final best = oneRep.reduce(
          (a, b) => (a.weight ?? 0) >= (b.weight ?? 0) ? a : b);
      final diff = DateTime.now()
          .difference(
              DateTime.fromMillisecondsSinceEpoch(best.performedAt))
          .inDays;
      if (diff == 0) return 'PR 오늘 갱신됨';
      return 'PR $diff일 전 갱신';
    }
    final last = DateTime.fromMillisecondsSinceEpoch(
        records.first.performedAt);
    final diff = DateTime.now().difference(last).inDays;
    if (diff == 0) return '오늘 업데이트됨';
    return '$diff일 전';
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Record record;
  final Exercise exercise;
  final bool isBest;
  final UnitSettings? settings;
  final bool isLast;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.record,
    required this.exercise,
    required this.isBest,
    required this.settings,
    required this.isLast,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date =
        DateTime.fromMillisecondsSinceEpoch(record.performedAt);
    final dateStr =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(isBest ? 10 : 0),
        bottom: Radius.circular(isLast ? 10 : 0),
      ),
      child: Dismissible(
        key: Key('record_${record.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color:
              const Color(0xFFFF3B30).withValues(alpha: 0.12),
          child: const Icon(CupertinoIcons.trash,
              color: Color(0xFFFF3B30), size: 18),
        ),
        confirmDismiss: (_) async => showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('기록 삭제'),
            content: const Text('이 기록을 삭제할까요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소',
                    style:
                        TextStyle(color: AppTheme.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('삭제',
                    style: TextStyle(color: Color(0xFFFF3B30))),
              ),
            ],
          ),
        ),
        onDismissed: (_) => onDelete(),
        child: Container(
          color: isBest
              ? AppTheme.accent.withValues(alpha: 0.04)
              : AppTheme.card,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(dateStr,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            _formatValue(),
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    if (isBest)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accent
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text('PB',
                            style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: AppTheme.separator,
                    indent: 16),
            ],
          ),
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
