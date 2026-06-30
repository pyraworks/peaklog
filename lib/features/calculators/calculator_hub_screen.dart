import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_assets.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/screen_header.dart';
import 'calculator_prefs.dart';

class CalculatorHubScreen extends StatelessWidget {
  const CalculatorHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ScreenHeader(backLabel: l10n.homeLabel, title: l10n.calculatorsTitle),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s24,
              ),
              children: [
                _CalculatorCard(
                  iconWidget: Icon(AppIcons.dumbbell, size: 28, color: AppColors.label1),
                  title: '1RM Calculator',
                  description: l10n.oneRmCalculatorDescription,
                  onTap: () {
                    CalculatorPrefs.setLastScreen('1rm');
                    context.push('/calculators/1rm');
                  },
                ),
                const SizedBox(height: AppSpacing.s12),
                _CalculatorCard(
                  iconWidget: Icon(AppIcons.run, size: 28, color: AppColors.label1),
                  title: l10n.paceCalculatorTitle,
                  description: l10n.paceCalculatorDescription,
                  onTap: () {
                    CalculatorPrefs.setLastScreen('pace');
                    context.push('/calculators/pace');
                  },
                ),
                const SizedBox(height: AppSpacing.s12),
                _CalculatorCard(
                  iconWidget: Image.asset(
                    AppAssets.plateCalculator,
                    width: 28,
                    height: 28,
                  ),
                  title: l10n.plateCalculatorTitle,
                  description: l10n.plateCalculatorDescription,
                  onTap: () {
                    CalculatorPrefs.setLastScreen('plate');
                    context.push('/calculators/plate');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculatorCard extends StatelessWidget {
  final Widget iconWidget;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _CalculatorCard({
    required this.iconWidget,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.separator, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s16,
        ),
        child: Row(
          children: [
            SizedBox(width: 28, height: 28, child: iconWidget),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.cardTitle.copyWith(
                      color: AppColors.label1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.label2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.forward, size: 18, color: AppColors.chevron),
          ],
        ),
      ),
    );
  }
}
