import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/screen_header.dart';

class QuickSharePlaceholderScreen extends StatelessWidget {
  final bool embedded;
  final String backLabel;
  const QuickSharePlaceholderScreen({super.key, this.embedded = false, this.backLabel = 'Back'});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (embedded) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  l10n.quickShareTitle,
                  style: AppTypography.appTitle.copyWith(
                    color: AppColors.label1,
                  ),
                ),
              ),
              const Expanded(child: _PlaceholderContent()),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ScreenHeader(backLabel: backLabel, title: l10n.quickShareTitle),
          const Expanded(child: _PlaceholderContent()),
        ],
      ),
    );
  }
}

class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.share,
              size: 64,
              color: AppColors.label2,
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              l10n.quickShareTagline,
              style: AppTypography.body.copyWith(
                color: AppColors.label2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              l10n.quickShareBeta,
              style: AppTypography.footnote.copyWith(
                color: AppColors.label3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
