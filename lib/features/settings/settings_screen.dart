import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_typography.dart';
import '../../providers/app_info_provider.dart';
import '../../providers/launch_screen_provider.dart';
import '../../providers/nickname_provider.dart';
import '../../providers/unit_settings_provider.dart';
import '../../widgets/screen_header.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final launchScreen =
        ref.watch(launchScreenProvider).valueOrNull ?? LaunchScreen.home;
    final launchScreenValue = switch (launchScreen) {
      LaunchScreen.home => l10n.homeLabel,
      LaunchScreen.calendar => l10n.calendarLabel,
      LaunchScreen.calculatorHub => l10n.calculatorsTitle,
    };

    final weightUnit =
        ref.watch(unitSettingsProvider).valueOrNull?.weightUnit ?? 'kg';
    final weightUnitValue = weightUnit == 'lbs' ? 'lb' : 'kg';

    void openFeedback() {
      launchUrl(
        Uri.parse(kFeedbackFormUrl),
        mode: LaunchMode.externalApplication,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ScreenHeader(backLabel: l10n.homeLabel, title: l10n.settingsLabel),
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                // ── Profile card ──────────────────────────────────────
                _ProfileSummaryCard(onTap: () => context.push('/profile')),
                const SizedBox(height: 24),

                // ── Grouped settings card ─────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.separator, width: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Column(
                    children: [
                      _MenuRow(
                        title: l10n.categorySettingsLabel,
                        leadingIcon: AppIcons.folder,
                        onTap: () => context.push('/categories'),
                      ),
                      const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.separatorAlt),
                      _MenuRow(
                        title: l10n.launchScreenSettingsLabel,
                        leadingIcon: AppIcons.settings,
                        trailingValue: launchScreenValue,
                        onTap: () => _showLaunchScreenPicker(context),
                      ),
                      const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.separatorAlt),
                      _MenuRow(
                        title: l10n.preferredWeightUnitLabel,
                        leadingIcon: AppIcons.dumbbell,
                        trailingValue: weightUnitValue,
                        onTap: () => _showPreferredWeightUnitPicker(context),
                      ),
                      const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.separatorAlt),
                      _MenuRow(
                        title: l10n.sendFeedback,
                        leadingIcon: AppIcons.feedback,
                        onTap: openFeedback,
                      ),
                      const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.separatorAlt),
                      const _VersionRow(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.betaNote,
                  textAlign: TextAlign.center,
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.label2,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showLaunchScreenPicker(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _LaunchScreenPickerSheet(),
  );
}

void _showPreferredWeightUnitPicker(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _PreferredWeightUnitPickerSheet(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tappable menu row with leading icon and trailing chevron
// ─────────────────────────────────────────────────────────────────────────────

class _MenuRow extends StatelessWidget {
  final String title;
  final IconData? leadingIcon;
  final String? trailingValue;
  final VoidCallback onTap;

  const _MenuRow({
    required this.title,
    this.leadingIcon,
    this.trailingValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 18, color: AppColors.label1),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.label1,
                ),
              ),
            ),
            if (trailingValue != null) ...[
              Text(
                trailingValue!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.label2,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(AppIcons.forward, size: 20, color: AppColors.chevron),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile summary card — tappable, navigates to /profile
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileSummaryCard extends ConsumerWidget {
  final VoidCallback onTap;
  const _ProfileSummaryCard({required this.onTap});

  static String _initials(String nickname) {
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
    final displayName = nickname.isEmpty ? l10n.peaklogUser : nickname;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.separator, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.label1,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _initials(nickname),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.label1,
                ),
              ),
            ),
            Icon(AppIcons.forward, size: 20, color: AppColors.chevron),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Launch Screen picker — bottom sheet opened from the Launch Screen Settings row
// ─────────────────────────────────────────────────────────────────────────────

class _LaunchScreenPickerSheet extends ConsumerWidget {
  const _LaunchScreenPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selected =
        ref.watch(launchScreenProvider).valueOrNull ?? LaunchScreen.home;

    void select(LaunchScreen value) {
      if (value != selected) HapticFeedback.selectionClick();
      ref.read(launchScreenProvider.notifier).setLaunchScreen(value);
      Navigator.pop(context);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.launchScreenLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.label1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.launchScreenDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.label2),
            ),
            const SizedBox(height: 16),
            _PickerOption(
              label: l10n.homeLabel,
              selected: selected == LaunchScreen.home,
              onTap: () => select(LaunchScreen.home),
            ),
            const SizedBox(height: 8),
            _PickerOption(
              label: l10n.calendarLabel,
              selected: selected == LaunchScreen.calendar,
              onTap: () => select(LaunchScreen.calendar),
            ),
            const SizedBox(height: 8),
            _PickerOption(
              label: l10n.calculatorsTitle,
              selected: selected == LaunchScreen.calculatorHub,
              onTap: () => select(LaunchScreen.calculatorHub),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preferred Weight Unit picker — bottom sheet opened from its Settings row
// ─────────────────────────────────────────────────────────────────────────────

class _PreferredWeightUnitPickerSheet extends ConsumerWidget {
  const _PreferredWeightUnitPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selected =
        ref.watch(unitSettingsProvider).valueOrNull?.weightUnit ?? 'kg';

    void select(String unit) {
      if (unit != selected) HapticFeedback.selectionClick();
      ref.read(unitSettingsProvider.notifier).setWeightUnit(unit);
      Navigator.pop(context);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.preferredWeightUnitLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.label1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.preferredWeightUnitDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.label2),
            ),
            const SizedBox(height: 16),
            _PickerOption(
              label: 'kg',
              selected: selected == 'kg',
              onTap: () => select('kg'),
            ),
            const SizedBox(height: 8),
            _PickerOption(
              label: 'lb',
              selected: selected == 'lbs',
              onTap: () => select('lbs'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared radio-style row used by the picker sheets above
// ─────────────────────────────────────────────────────────────────────────────

class _PickerOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PickerOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.separator, width: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? CupertinoIcons.largecircle_fill_circle
                  : CupertinoIcons.circle,
              size: 20,
              color: selected ? AppColors.label1 : AppColors.label3,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.label1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Version row — tappable, copies version string to clipboard
// ─────────────────────────────────────────────────────────────────────────────

class _VersionRow extends ConsumerWidget {
  const _VersionRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final version = ref.watch(appVersionProvider).valueOrNull;
    final versionText = version != null ? 'Beta $version' : '';

    void copyVersion() {
      if (versionText.isEmpty) return;
      Clipboard.setData(ClipboardData(text: versionText));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.versionCopied)),
      );
    }

    return Semantics(
      label: l10n.version,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: copyVersion,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(AppIcons.infoCircle, size: 18, color: AppColors.label1),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.version,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.label1,
                  ),
                ),
              ),
              Text(
                versionText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.label2,
                ),
              ),
              const SizedBox(width: 4),
              Icon(AppIcons.copy, size: 12, color: AppColors.label2),
            ],
          ),
        ),
      ),
    );
  }
}
