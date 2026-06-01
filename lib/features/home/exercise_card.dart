import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../core/models/exercise.dart';
import '../../core/models/record.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/records_provider.dart';
import '../../providers/unit_settings_provider.dart';
import '../../providers/exercises_provider.dart';
import '../exercise_detail/exercise_detail_screen.dart';

class ExerciseCard extends ConsumerWidget {
  final Exercise exercise;
  final bool editMode;
  const ExerciseCard(
      {required this.exercise, this.editMode = false, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records =
        ref.watch(recordsProvider(exercise.id)).valueOrNull ?? [];
    final settings = ref.watch(unitSettingsProvider).valueOrNull;

    final bestRecord = _getBestRecord(records, exercise.category);
    final displayValue = _formatBestValue(bestRecord, exercise, settings);
    final daysSince = _daysSince(records, exercise.category);

    return Slidable(
      key: ValueKey(exercise.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.42,
        children: [
          CustomSlidableAction(
            onPressed: (_) => _showRenameDialog(context, ref),
            backgroundColor: AppTheme.background,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                      color: Color(0xFF007AFF), shape: BoxShape.circle),
                  child: const Icon(CupertinoIcons.pencil,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(height: 5),
                const Text('수정',
                    style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          CustomSlidableAction(
            onPressed: (_) => _confirmDelete(context, ref),
            backgroundColor: AppTheme.background,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFF3B30), shape: BoxShape.circle),
                  child: const Icon(CupertinoIcons.trash,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(height: 5),
                const Text('삭제',
                    style: TextStyle(
                        color: Color(0xFFFF3B30),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
      child: Material(
        color: AppTheme.card,
        child: InkWell(
          onTap: editMode
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ExerciseDetailScreen(exercise: exercise),
                    ),
                  ),
          splashColor: Colors.transparent,
          highlightColor: Colors.black.withValues(alpha: 0.04),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (editMode)
                  GestureDetector(
                    onTap: () => _confirmDelete(context, ref),
                    child: Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: const BoxDecoration(
                          color: Color(0xFFFF3B30), shape: BoxShape.circle),
                      child: const Icon(Icons.remove,
                          color: Colors.white, size: 14),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            exercise.displayName.toUpperCase(),
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              exercise.category.label,
                              style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayValue,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(daysSince,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12)),
                          if (bestRecord != null) ...[
                            const SizedBox(width: 6),
                            const Icon(CupertinoIcons.star_fill,
                                color: AppTheme.accent, size: 11),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${records.length}개',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    const Icon(CupertinoIcons.chevron_right,
                        color: AppTheme.separator, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Record? _getBestRecord(List<Record> records, ExerciseCategory category) {
    if (records.isEmpty) return null;
    switch (category) {
      case ExerciseCategory.strength:
        final oneRep = records
            .where(
                (r) => r.weight != null && (r.reps == null || r.reps == 1))
            .toList();
        if (oneRep.isEmpty) return null;
        return oneRep.reduce(
            (a, b) => (a.weight ?? 0) >= (b.weight ?? 0) ? a : b);
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        final withTime =
            records.where((r) => r.durationSeconds != null).toList();
        if (withTime.isEmpty) return null;
        return withTime.reduce((a, b) =>
            (a.durationSeconds ?? 0) <= (b.durationSeconds ?? 0) ? a : b);
      case ExerciseCategory.custom:
        return records.first;
    }
  }

  String _formatBestValue(
      Record? best, Exercise exercise, UnitSettings? settings) {
    if (best == null) return '—';
    switch (exercise.category) {
      case ExerciseCategory.strength:
        return UnitConverter.formatWeight(
            best.weight ?? 0, settings?.weightUnit ?? 'kg');
      case ExerciseCategory.running:
      case ExerciseCategory.workout:
        return UnitConverter.secondsToDisplay(best.durationSeconds ?? 0);
      case ExerciseCategory.custom:
        if (best.weight != null) {
          return UnitConverter.formatWeight(
              best.weight!, settings?.weightUnit ?? 'kg');
        }
        if (best.durationSeconds != null) {
          return UnitConverter.secondsToDisplay(best.durationSeconds!);
        }
        return '—';
    }
  }

  String _daysSince(List<Record> records, ExerciseCategory category) {
    if (records.isEmpty) return '기록 없음';
    if (category == ExerciseCategory.strength) {
      final oneRep = records
          .where(
              (r) => r.weight != null && (r.reps == null || r.reps == 1))
          .toList();
      if (oneRep.isEmpty) return '기록 없음';
      final best = oneRep.reduce(
          (a, b) => (a.weight ?? 0) >= (b.weight ?? 0) ? a : b);
      final diff = DateTime.now()
          .difference(
              DateTime.fromMillisecondsSinceEpoch(best.performedAt))
          .inDays;
      if (diff == 0) return '오늘 PR';
      return 'PR $diff일 전';
    }
    final last =
        DateTime.fromMillisecondsSinceEpoch(records.first.performedAt);
    final diff = DateTime.now().difference(last).inDays;
    if (diff == 0) return '오늘';
    return '$diff일 전';
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller =
        TextEditingController(text: exercise.displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('운동 이름 수정'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '운동 이름'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref
                    .read(exercisesProvider.notifier)
                    .renameExercise(exercise.id, name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('저장',
                style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('운동 삭제'),
        content: Text("'${exercise.displayName}' 와(과) 모든 기록을 삭제할까요?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(exercisesProvider.notifier)
                  .deleteExercise(exercise.id);
            },
            child: const Text('삭제',
                style: TextStyle(color: Color(0xFFFF3B30))),
          ),
        ],
      ),
    );
  }
}
