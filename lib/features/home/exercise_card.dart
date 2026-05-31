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
import '../record_input/record_input_screen.dart';

class ExerciseCard extends ConsumerWidget {
  final Exercise exercise;
  const ExerciseCard({required this.exercise, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records =
        ref.watch(recordsProvider(exercise.id!)).valueOrNull ?? [];
    final settings = ref.watch(unitSettingsProvider).valueOrNull;

    final bestRecord = _getBestRecord(records, exercise.type);
    final displayValue = _formatBestValue(bestRecord, exercise, settings);
    final daysSince = _daysSince(records);

    return Slidable(
      key: ValueKey(exercise.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.42,
        children: [
          SlidableAction(
            onPressed: (_) => _showRenameDialog(context, ref),
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            icon: CupertinoIcons.pencil,
            label: '수정',
          ),
          SlidableAction(
            onPressed: (_) => _confirmDelete(context, ref),
            backgroundColor: const Color(0xFFFF3B30),
            foregroundColor: Colors.white,
            icon: CupertinoIcons.trash,
            label: '삭제',
          ),
        ],
      ),
      child: Material(
        color: AppTheme.card,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ExerciseDetailScreen(exercise: exercise),
            ),
          ),
          splashColor: Colors.transparent,
          highlightColor: Colors.black.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 왼쪽: 운동 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 운동명 + 타입 뱃지
                      Row(
                        children: [
                          Text(
                            exercise.name.toUpperCase(),
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
                              color: AppTheme.accent
                                  .withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(4),
                            ),
                            child: Text(
                              exercise.type.label,
                              style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // 최고 기록값
                      Text(
                        displayValue,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 4),
                      // 메타 정보
                      Row(
                        children: [
                          Text(
                            daysSince,
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12),
                          ),
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
                // 오른쪽: 기록 추가 버튼 + 화살표
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecordInputScreen(
                              exercise: exercise),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '기록 추가',
                          style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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

  Record? _getBestRecord(List<Record> records, ExerciseType type) {
    if (records.isEmpty) return null;
    if (type == ExerciseType.time) {
      return records.reduce((a, b) => a.value < b.value ? a : b);
    }
    return records.reduce((a, b) => a.value > b.value ? a : b);
  }

  String _formatBestValue(
      Record? best, Exercise exercise, UnitSettings? settings) {
    if (best == null) return '—';
    switch (exercise.type) {
      case ExerciseType.weight:
        return UnitConverter.formatWeight(
            best.value, settings?.weightUnit ?? 'kg');
      case ExerciseType.time:
        return UnitConverter.secondsToDisplay(best.value.toInt());
      case ExerciseType.distance:
        return UnitConverter.formatDistance(
            best.value, settings?.distanceUnit ?? 'km');
    }
  }

  String _daysSince(List<Record> records) {
    if (records.isEmpty) return '기록 없음';
    final last =
        DateTime.fromMillisecondsSinceEpoch(records.first.recordedAt * 1000);
    final diff = DateTime.now().difference(last).inDays;
    if (diff == 0) return '오늘';
    return '$diff일 전';
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: exercise.name);
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
                    .renameExercise(exercise.id!, name);
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
        content: Text('\'${exercise.name}\' 와(과) 모든 기록을 삭제할까요?'),
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
                  .deleteExercise(exercise.id!);
            },
            child: const Text('삭제',
                style: TextStyle(color: Color(0xFFFF3B30))),
          ),
        ],
      ),
    );
  }
}
