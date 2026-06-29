import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import '../../providers/nickname_provider.dart';
import '../../widgets/screen_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void openFeedback() {
      if (kFeedbackFormUrl == 'REPLACE_WITH_GOOGLE_FORM_URL') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback form is not available yet.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      launchUrl(
        Uri.parse(kFeedbackFormUrl),
        mode: LaunchMode.externalApplication,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const ScreenHeader(backLabel: 'Home', title: 'Settings'),
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                // ── Profile card ──────────────────────────────────────
                _ProfileSummaryCard(onTap: () => context.push('/profile')),
                const SizedBox(height: 24),

                // ── GENERAL ──────────────────────────────────────────
                const _SectionLabel('GENERAL'),
                _CardSection(
                  items: [
                    _CardItem(
                        title: 'Categories',
                        onTap: () => context.push('/categories')),
                  ],
                ),
                const SizedBox(height: 24),

                // ── FEEDBACK ─────────────────────────────────────────
                const _SectionLabel('FEEDBACK'),
                _CardSection(
                  items: [
                    _CardItem(
                      title: 'Send Feedback',
                      leadingIcon: AppIcons.feedback,
                      onTap: openFeedback,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── ABOUT ─────────────────────────────────────────────
                const _SectionLabel('ABOUT'),
                const _AboutCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.label2,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic card section with divider-separated rows
// ─────────────────────────────────────────────────────────────────────────────

class _CardItem {
  final String title;
  final IconData? leadingIcon;
  final VoidCallback onTap;
  const _CardItem({required this.title, this.leadingIcon, required this.onTap});
}

class _CardSection extends StatelessWidget {
  final List<_CardItem> items;

  const _CardSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        rows.add(const Divider(
            height: 1, thickness: 1, color: AppColors.separatorAlt));
      }
      rows.add(_MenuRow(title: items[i].title, leadingIcon: items[i].leadingIcon, onTap: items[i].onTap));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: rows),
    );
  }
}

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
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 18, color: AppColors.label2),
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
            Icon(
              AppIcons.forward,
              size: 20,
              color: AppColors.chevron,
            ),
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
    final nickname = ref.watch(nicknameProvider).valueOrNull ?? '';
    final displayName = nickname.isEmpty ? 'PeakLog User' : nickname;

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

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  static const _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Version',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.label1,
                ),
              ),
            ),
            Text(
              _version,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.label2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

