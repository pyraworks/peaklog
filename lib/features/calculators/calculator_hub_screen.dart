import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../widgets/screen_header.dart';
import 'calculator_prefs.dart';

class CalculatorHubScreen extends StatelessWidget {
  const CalculatorHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const ScreenHeader(backLabel: 'Home', title: 'Calculators'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s24,
              ),
              children: [
                _CalculatorCard(
                  emoji: '🏋️',
                  title: '1RM Calculator',
                  description: 'Estimate your one-rep max and training percentages.',
                  onTap: () {
                    CalculatorPrefs.setLastScreen('1rm');
                    context.push('/calculators/1rm');
                  },
                ),
                const SizedBox(height: AppSpacing.s12),
                _CalculatorCard(
                  emoji: '🏃',
                  title: 'Pace Calculator',
                  description: 'Calculate pace, finish time, and race splits.',
                  onTap: () {
                    CalculatorPrefs.setLastScreen('pace');
                    context.push('/calculators/pace');
                  },
                ),
                const SizedBox(height: AppSpacing.s12),
                _CalculatorCard(
                  emoji: '⚫',
                  title: 'Plate Calculator',
                  description: 'Calculate barbell loading and total weight.',
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
  final String emoji;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _CalculatorCard({
    required this.emoji,
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
            Text(emoji, style: const TextStyle(fontSize: 28)),
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
