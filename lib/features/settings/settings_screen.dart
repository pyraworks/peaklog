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
import '../../providers/nickname_provider.dart';
import '../../widgets/screen_header.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                        title: l10n.categoriesTitle,
                        leadingIcon: AppIcons.folder,
                        onTap: () => context.push('/categories'),
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

// ─────────────────────────────────────────────────────────────────────────────
// Tappable menu row with leading icon and trailing chevron
// ─────────────────────────────────────────────────────────────────────────────

class _MenuRow extends StatelessWidget {
  final String title;
  final IconData? leadingIcon;
  final VoidCallback onTap;

  const _MenuRow({required this.title, this.leadingIcon, required this.onTap});

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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
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
