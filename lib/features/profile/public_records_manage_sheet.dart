import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_typography.dart';
import '../../domain/models/category.dart';
import '../../domain/models/public_record.dart';
import '../../providers/exercises_provider.dart';
import '../../providers/public_records_provider.dart';

class PublicRecordsManageSheet extends ConsumerWidget {
  const PublicRecordsManageSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exercisesProvider).valueOrNull ?? [];
    final publicRecords = ref.watch(publicRecordsProvider).valueOrNull ?? [];
    final publicIds = {for (final pr in publicRecords) pr.exerciseId};
    final selectedCount = publicRecords.length;
    final isMax = selectedCount >= 8;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 핸들
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.separator,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // 제목 행
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '공개 운동 관리',
                        style: AppTypography.headline
                            .copyWith(color: AppColors.label1),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close,
                          size: 20, color: AppColors.label2),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // 안내 문구
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                child: Text(
                  '프로필에 표시할 운동을 최대 8개까지 선택할 수 있습니다.',
                  style: AppTypography.footnote
                      .copyWith(color: AppColors.label2),
                ),
              ),
              // 선택 개수
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$selectedCount / 8',
                        style: AppTypography.footnote.copyWith(
                          color: AppColors.label1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: ' 선택됨',
                        style: AppTypography.footnote
                            .copyWith(color: AppColors.label2),
                      ),
                    ],
                  ),
                ),
              ),
              // 운동 목록
              Expanded(
                child: exercises.isEmpty
                    ? const Center(
                        child: Text(
                          '생성된 운동 종목이 없습니다.',
                          style: TextStyle(
                              fontSize: 15, color: AppColors.label2),
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.separator,
                                  width: 0.5),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: Column(
                              children: [
                                for (int i = 0;
                                    i < exercises.length;
                                    i++) ...[
                                  if (i > 0)
                                    const Divider(
                                        height: 0.5,
                                        thickness: 0.5,
                                        color: AppColors.separator),
                                  _ExerciseRow(
                                    name: exercises[i].displayName,
                                    categoryName: Category.nameForId(
                                        exercises[i].categoryId),
                                    isOn: publicIds
                                        .contains(exercises[i].id),
                                    isDisabled: isMax &&
                                        !publicIds
                                            .contains(exercises[i].id),
                                    onToggle: (value) => _onToggle(
                                        ref, exercises[i].id, value),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              // 최대 개수 초과 안내
              if (isMax)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text(
                    '공개 운동은 최대 8개까지 선택할 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: AppTypography.footnote
                        .copyWith(color: AppColors.label2),
                  ),
                ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onToggle(
      WidgetRef ref, String exerciseId, bool value) async {
    if (value) {
      final current =
          ref.read(publicRecordsProvider).valueOrNull ?? [];
      final now = DateTime.now().millisecondsSinceEpoch;
      await ref.read(publicRecordsProvider.notifier).add(PublicRecord(
            exerciseId: exerciseId,
            displayOrder: current.length,
            createdAt: now,
            updatedAt: now,
          ));
    } else {
      await ref.read(publicRecordsProvider.notifier).remove(exerciseId);
    }
  }
}

// ── 운동 행 ──────────────────────────────────────────────────────────────────

class _ExerciseRow extends StatelessWidget {
  final String name;
  final String categoryName;
  final bool isOn;
  final bool isDisabled;
  final ValueChanged<bool> onToggle;

  const _ExerciseRow({
    required this.name,
    required this.categoryName,
    required this.isOn,
    required this.isDisabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: isDisabled,
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.label1,
                      ),
                    ),
                    if (categoryName.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.label2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CupertinoSwitch(
                value: isOn,
                activeTrackColor: AppColors.label1,
                onChanged: onToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
