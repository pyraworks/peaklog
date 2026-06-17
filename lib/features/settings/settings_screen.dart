import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/screen_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
  final VoidCallback onTap;
  const _CardItem({required this.title, required this.onTap});
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
      rows.add(_MenuRow(title: items[i].title, onTap: items[i].onTap));
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
  final VoidCallback onTap;

  const _MenuRow({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1F2328),
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

class _ProfileSummaryCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ProfileSummaryCard({required this.onTap});

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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.separatorAlt),
              ),
              child: Center(
                child: Icon(
                  AppIcons.person,
                  size: 22,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'PeakLog User',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2328),
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
                  color: Color(0xFF1F2328),
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

