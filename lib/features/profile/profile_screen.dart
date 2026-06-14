import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import '../../core/utils/unit_converter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/screen_header.dart';
import '../../core/enums/record_type.dart';
import 'public_records_manage_sheet.dart';
import '../../domain/models/personal_best.dart';
import '../../providers/exercises_provider.dart';
import '../../providers/personal_best_provider.dart';
import '../../providers/public_records_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publicRecords = ref.watch(publicRecordsProvider).valueOrNull ?? [];
    final exercises = ref.watch(exercisesProvider).valueOrNull ?? [];
    final limited = publicRecords.take(8).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const ScreenHeader(backLabel: 'Home', title: 'Profile'),
          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                // ── Profile Card ────────────────────────────────────────
                const _ProfileCard(),
                const SizedBox(height: 24),

                // ── Public Records ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
                  child: Row(
                    children: [
                      const Text(
                        'PUBLIC RECORDS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.label2,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const PublicRecordsManageSheet(),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Manage',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.label2,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              AppIcons.forward,
                              size: 13,
                              color: AppColors.label2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (limited.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        '선택된 공개 운동이 없습니다.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  )
                else
                  _PublicRecordsGrid(
                    publicRecords: limited,
                    exercises: exercises,
                    ref: ref,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Header
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Profile Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext _) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: const _IdentityRow(),
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.separatorAlt),
            ),
            child: Center(
              child: Icon(
                AppIcons.person,
                size: 22,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'PeakLog User',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2328),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public Records Grid
// ─────────────────────────────────────────────────────────────────────────────

class _PublicRecordsGrid extends StatelessWidget {
  final List<dynamic> publicRecords;
  final List<dynamic> exercises;
  final WidgetRef ref;

  const _PublicRecordsGrid({
    required this.publicRecords,
    required this.exercises,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.8,
      children: publicRecords.map((pr) {
        final exercise =
            exercises.where((e) => e.id == pr.exerciseId).firstOrNull;
        final pb = ref.watch(personalBestProvider(pr.exerciseId));
        final valueText = pb != null
            ? _pbValueString(pb, exercise?.baseUnit ?? 'kg')
            : '—';
        final dateText = pb != null
            ? _formatDate(
                DateTime.fromMillisecondsSinceEpoch(pb.achievedAt))
            : '';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.separator, width: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                exercise?.displayName ?? '—',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                valueText,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2328),
                  letterSpacing: -0.02 * 20,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (dateText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondaryAlt,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  String _pbValueString(PersonalBest pb, String weightUnit) {
    switch (pb.recordType) {
      case RecordType.weight:
        final w = pb.weight;
        if (w == null) return '—';
        final repsStr = pb.reps != null ? ' × ${pb.reps}' : '';
        return '${UnitConverter.formatWeight(w, weightUnit)}$repsStr';
      case RecordType.etc:
        final v = pb.etcValue;
        if (v == null) return '—';
        return v == v.truncateToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);
      case RecordType.forTime:
        final s = pb.durationSeconds;
        if (s == null) return '—';
        final m = s ~/ 60;
        final sec = s % 60;
        return '$m:${sec.toString().padLeft(2, '0')}';
      case RecordType.amrap:
        final r = pb.rounds;
        if (r == null) return '—';
        final extra = pb.reps != null ? '+${pb.reps}' : '';
        return '$r라운드$extra';
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }
}

