import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import '../../core/models/exercise.dart';
import '../../core/utils/unit_converter.dart';
import '../../domain/models/personal_best.dart';
import '../../domain/models/public_record.dart';
import '../../providers/exercises_provider.dart';
import '../../providers/nickname_provider.dart';
import '../../providers/personal_best_provider.dart';
import '../../providers/public_records_provider.dart';
import '../../providers/records_provider.dart';
import '../../widgets/screen_header.dart';
import 'public_records_manage_sheet.dart';
import '../../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // "Daniel" → "D", "Alex Kim" → "AK", "" → "P"
  static String initials(String nickname) {
    if (nickname.isEmpty) return 'P';
    final parts = nickname.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'P';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nickname = ref.watch(nicknameProvider).valueOrNull ?? '';
    final exercises = ref.watch(exercisesProvider).valueOrNull ?? [];
    final publicRecords = ref.watch(publicRecordsProvider).valueOrNull ?? [];

    final displayName = nickname.isEmpty ? l10n.peaklogUser : nickname;
    final limited = publicRecords.take(8).toList();

    void openNicknameSheet() {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _NicknameSheet(initialNickname: nickname),
      );
    }

    void openManageSheet() {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const PublicRecordsManageSheet(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ScreenHeader(backLabel: l10n.settingsLabel, title: l10n.profileTitle),
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                // ── Hero ────────────────────────────────────────────────
                _HeroSection(
                  initials: initials(nickname),
                  displayName: displayName,
                  onEdit: openNicknameSheet,
                ),
                const SizedBox(height: 28),

                // ── Public Exercises ─────────────────────────────────────
                _SectionHeader(
                  label: l10n.sectionPublicExercises,
                  actionLabel: l10n.manage,
                  onAction: openManageSheet,
                ),
                if (limited.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        l10n.noPublicExercises,
                        style: const TextStyle(
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
// Hero
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final String initials;
  final String displayName;
  final VoidCallback onEdit;

  const _HeroSection({
    required this.initials,
    required this.displayName,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),

        // Avatar — primary-tinted circle, dark initials
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.label1,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Display name
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.label1,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 10),

        // Edit Profile — always visible, clear pill button
        GestureDetector(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.separator, width: 1),
            ),
            child: Text(
              AppLocalizations.of(context)!.editProfile,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.label2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header with optional manage action
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.label,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.label2,
              letterSpacing: 1.2,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const Spacer(),
            GestureDetector(
              onTap: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.label2,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(AppIcons.forward,
                      size: 13, color: AppColors.label2),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public records grid
// ─────────────────────────────────────────────────────────────────────────────

class _PublicRecordsGrid extends ConsumerWidget {
  final List<PublicRecord> publicRecords;
  final List<Exercise> exercises;

  const _PublicRecordsGrid({
    required this.publicRecords,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.8,
      children: publicRecords.map((pr) {
        final exercise =
            exercises.where((e) => e.id == pr.exerciseId).firstOrNull;
        final pb = ref.watch(personalBestProvider(pr.exerciseId));
        final records =
            ref.watch(recordsProvider(pr.exerciseId)).valueOrNull ?? [];
        final etcUnit = (pb != null && pb.recordType == RecordType.etc)
            ? (records
                    .where((r) => r.id == pb.sourceRecordId)
                    .firstOrNull
                    ?.distanceUnit ??
                '')
            : '';
        final valueText = pb != null
            ? _pbValueString(pb, exercise?.baseUnit ?? 'kg',
                etcUnit: etcUnit)
            : '—';
        final dateText = pb != null
            ? _formatDate(
                DateTime.fromMillisecondsSinceEpoch(pb.achievedAt))
            : '';

        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  color: AppColors.label1,
                  letterSpacing: -0.4,
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

  String _pbValueString(PersonalBest pb, String weightUnit,
      {String etcUnit = ''}) {
    switch (pb.recordType) {
      case RecordType.weight:
        final w = pb.weight;
        if (w == null) return '—';
        final repsStr = pb.reps != null ? ' × ${pb.reps}' : '';
        return '${UnitConverter.formatWeight(w, weightUnit)}$repsStr';
      case RecordType.etc:
        final v = pb.etcValue;
        if (v == null) return '—';
        return UnitConverter.formatEtc(v, etcUnit);
      case RecordType.forTime:
        final s = pb.durationSeconds;
        if (s == null) return '—';
        return UnitConverter.secondsToDisplay(s);
      case RecordType.amrap:
        final r = pb.rounds;
        if (r == null) return '—';
        return UnitConverter.formatAmrap(r, pb.reps);
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Nickname editor sheet
// ─────────────────────────────────────────────────────────────────────────────

class _NicknameSheet extends ConsumerStatefulWidget {
  final String initialNickname;
  const _NicknameSheet({required this.initialNickname});

  @override
  ConsumerState<_NicknameSheet> createState() => _NicknameSheetState();
}

class _NicknameSheetState extends ConsumerState<_NicknameSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialNickname);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.setNickname,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryAlt,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            maxLength: 30,
            style: const TextStyle(
                fontSize: 15, color: AppColors.textPrimaryAlt),
            decoration: InputDecoration(
              hintText: l10n.nicknameHint,
              hintStyle:
                  const TextStyle(color: AppColors.textSecondaryAlt),
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.separatorAlt),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.separatorAlt),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.separatorAlt),
                    ),
                    child: Center(
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimaryAlt,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await ref
                        .read(nicknameProvider.notifier)
                        .setNickname(_ctrl.text);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.actionDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        l10n.save,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
