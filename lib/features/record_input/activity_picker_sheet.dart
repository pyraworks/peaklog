import 'package:flutter/material.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/models/health_workout.dart';
import '../../core/services/health_sync_service.dart';
import '../../core/utils/unit_converter.dart';
import '../../l10n/app_localizations.dart';

Future<HealthWorkout?> showActivityPickerSheet(BuildContext context) =>
    showModalBottomSheet<HealthWorkout>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ActivityPickerSheet(),
    );

class ActivityPickerSheet extends StatefulWidget {
  const ActivityPickerSheet({super.key});

  @override
  State<ActivityPickerSheet> createState() => _ActivityPickerSheetState();
}

class _ActivityPickerSheetState extends State<ActivityPickerSheet> {
  late final Future<List<HealthWorkout>> _future;

  @override
  void initState() {
    super.initState();
    _future = healthSyncService.fetchRecentActivities();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s20,
        AppSpacing.s20,
        AppSpacing.s32 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.importActivityTitle,
                  style: AppTypography.headline.copyWith(color: AppColors.label1),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(AppIcons.close, color: AppColors.label2),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            l10n.importActivitySubtitle,
            style: AppTypography.caption.copyWith(color: AppColors.label2),
          ),
          const SizedBox(height: AppSpacing.s16),
          Flexible(
            child: FutureBuilder<List<HealthWorkout>>(
              future: _future,
              builder: (context, snap) {
                final innerL10n = AppLocalizations.of(context)!;
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.s32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snap.hasError) {
                  return _EmptyState(
                    emoji: '⚠️',
                    message: innerL10n.importActivityError,
                  );
                }
                final workouts = snap.data!;
                if (workouts.isEmpty) {
                  return _EmptyState(
                    emoji: '⌚',
                    message: innerL10n.importActivityEmpty,
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: workouts.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.separator),
                  itemBuilder: (context, i) =>
                      _ActivityRow(workout: workouts[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final HealthWorkout workout;
  const _ActivityRow({required this.workout});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = workout.startTime;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final actDate = DateTime(date.year, date.month, date.day);

    final String dateLabel;
    if (actDate == today) {
      dateLabel = l10n.today;
    } else if (actDate == yesterday) {
      dateLabel = l10n.yesterday;
    } else {
      dateLabel =
          '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    }

    final durationStr = UnitConverter.secondsToDisplay(workout.durationSeconds);
    final hasDistance = workout.distanceKm > 0;
    final distStr = hasDistance
        ? '${workout.distanceKm.toStringAsFixed(2)} km'
        : null;

    final subtitle = [
      if (distStr != null) distStr,
      durationStr,
    ].join(' · ');

    return InkWell(
      onTap: () => Navigator.pop(context, workout),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.s12,
          horizontal: AppSpacing.s4,
        ),
        child: Row(
          children: [
            _ActivityIcon(type: workout.activityType),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _activityLabel(workout.activityType, l10n),
                    style: AppTypography.body.copyWith(color: AppColors.label1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$subtitle · $dateLabel',
                    style: AppTypography.caption.copyWith(color: AppColors.label2),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.forward, color: AppColors.label3, size: 20),
          ],
        ),
      ),
    );
  }

  String _activityLabel(HealthActivityType type, AppLocalizations l10n) {
    switch (type) {
      case HealthActivityType.running:
        return l10n.activityRunning;
      case HealthActivityType.cycling:
        return l10n.activityCycling;
      case HealthActivityType.swimming:
        return l10n.activitySwimming;
      case HealthActivityType.other:
        return l10n.activityOther;
    }
  }
}

class _ActivityIcon extends StatelessWidget {
  final HealthActivityType type;
  const _ActivityIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    switch (type) {
      case HealthActivityType.running:
        icon = AppIcons.run;
      case HealthActivityType.cycling:
        icon = AppIcons.bike;
      case HealthActivityType.swimming:
        icon = AppIcons.swim;
      case HealthActivityType.other:
        icon = AppIcons.dumbbell;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(icon, size: 20, color: AppColors.label2),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String message;
  const _EmptyState({required this.emoji, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: AppSpacing.s12),
          Text(
            message,
            style: AppTypography.body.copyWith(color: AppColors.label2),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
