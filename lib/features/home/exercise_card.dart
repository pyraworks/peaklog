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
import '../history/history_screen.dart';
import '../record_input/record_input_screen.dart';
import 'one_rm_panel.dart';

class ExerciseCard extends ConsumerStatefulWidget {
  final Exercise exercise;
  const ExerciseCard({required this.exercise, super.key});

  @override
  ConsumerState<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<ExerciseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final records =
        ref.watch(recordsProvider(widget.exercise.id!)).valueOrNull ?? [];
    final settings = ref.watch(unitSettingsProvider).valueOrNull;

    final bestRecord = _getBestRecord(records, widget.exercise.type);
    final displayValue =
        _formatBestValue(bestRecord, widget.exercise, settings);
    final daysSince = _daysSince(records);

    return Slidable(
      key: ValueKey(widget.exercise.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.44,
        children: [
          SlidableAction(
            onPressed: (_) => _showRenameDialog(context),
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            icon: CupertinoIcons.pencil,
            label: '수정',
          ),
          SlidableAction(
            onPressed: (_) => _confirmDelete(context),
            backgroundColor: const Color(0xFFFF3B30),
            foregroundColor: Colors.white,
            icon: CupertinoIcons.trash,
            label: '삭제',
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: widget.exercise.type == ExerciseType.weight
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: Radius.circular(_expanded ? 0 : 16),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.exercise.name.toUpperCase(),
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      widget.exercise.type.label,
                                      style: const TextStyle(
                                          color: AppTheme.accent,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                displayValue,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1),
                              ),
                            ],
                          ),
                        ),
                        if (widget.exercise.type == ExerciseType.weight)
                          Icon(
                            _expanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: AppTheme.textSecondary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          daysSince,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        if (bestRecord != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.star,
                              color: AppTheme.accent, size: 14),
                          const SizedBox(width: 2),
                          const Text(
                            '최고 기록',
                            style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                        const Spacer(),
                        TextButton(
                          onPressed: () => _openRecordInput(context),
                          style: TextButton.styleFrom(
                              foregroundColor: AppTheme.accent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4)),
                          child: const Text('기록 추가',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                        TextButton(
                          onPressed: () => _openHistory(context),
                          style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4)),
                          child: const Text('히스토리',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded && widget.exercise.type == ExerciseType.weight)
            OneRmPanel(exercise: widget.exercise),
        ],
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
    return '+$diff일';
  }

  void _openRecordInput(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordInputScreen(exercise: widget.exercise),
      ),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryScreen(exercise: widget.exercise),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller =
        TextEditingController(text: widget.exercise.name);
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
                    .renameExercise(widget.exercise.id!, name);
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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('운동 삭제'),
        content: Text(
            '\'${widget.exercise.name}\' 와(과) 모든 기록을 삭제할까요?'),
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
                  .deleteExercise(widget.exercise.id!);
            },
            child: const Text('삭제',
                style: TextStyle(color: Color(0xFFFF3B30))),
          ),
        ],
      ),
    );
  }
}
