import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/unit_converter.dart';
import '../../providers/unit_settings_provider.dart';
import '../export/export_screen.dart';

class PRCelebrationDialog extends ConsumerWidget {
  final Exercise exercise;
  final double newValue;
  final double? previousBest;

  const PRCelebrationDialog({
    required this.exercise,
    required this.newValue,
    this.previousBest,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(unitSettingsProvider).valueOrNull;
    final weightUnit = settings?.weightUnit ?? 'kg';
    final distanceUnit = settings?.distanceUnit ?? 'km';

    final displayNew = _formatValue(newValue, exercise.type, weightUnit, distanceUnit);
    final displayDiff = _formatDiff(newValue, previousBest, exercise.type, weightUnit, distanceUnit);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events,
                  color: AppTheme.accent, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              previousBest == null ? '첫 기록!' : '새로운 PR!',
              style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Text(
              exercise.name,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    displayNew,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 36,
                        fontWeight: FontWeight.w900),
                  ),
                  if (displayDiff != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      displayDiff,
                      style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.card),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('닫기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExportScreen(
                            exercise: exercise,
                            newValue: newValue,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('공유'),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(double value, ExerciseType type, String weightUnit,
      String distanceUnit) {
    switch (type) {
      case ExerciseType.weight:
        return UnitConverter.formatWeight(value, weightUnit);
      case ExerciseType.time:
        return UnitConverter.secondsToDisplay(value.toInt());
      case ExerciseType.distance:
        return UnitConverter.formatDistance(value, distanceUnit);
    }
  }

  String? _formatDiff(double newVal, double? prev, ExerciseType type,
      String weightUnit, String distanceUnit) {
    if (prev == null) return null;
    switch (type) {
      case ExerciseType.weight:
        return UnitConverter.formatDiffWeight(newVal - prev, weightUnit);
      case ExerciseType.time:
        return UnitConverter.formatDiffTime((newVal - prev).toInt());
      case ExerciseType.distance:
        return UnitConverter.formatDiffDistance(newVal - prev, distanceUnit);
    }
  }
}
