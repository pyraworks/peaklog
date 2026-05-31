import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/unit_settings_provider.dart';

class UnitToggle extends ConsumerWidget {
  const UnitToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(unitSettingsProvider).valueOrNull;
    if (settings == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToggleChip(
          label: settings.weightUnit.toUpperCase(),
          onTap: () =>
              ref.read(unitSettingsProvider.notifier).toggleWeightUnit(),
        ),
        const SizedBox(width: 6),
        _ToggleChip(
          label: settings.distanceUnit.toUpperCase(),
          onTap: () =>
              ref.read(unitSettingsProvider.notifier).toggleDistanceUnit(),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ToggleChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
