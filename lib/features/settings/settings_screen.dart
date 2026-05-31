import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/unit_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(unitSettingsProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          const _SectionHeader('단위 설정'),
          _SegmentRow(
            title: '무게',
            options: const ['kg', 'lbs'],
            selected: settings?.weightUnit ?? 'kg',
            onChanged: (v) {
              final cur = ref.read(unitSettingsProvider).valueOrNull;
              if (cur != null && cur.weightUnit != v) {
                ref.read(unitSettingsProvider.notifier).toggleWeightUnit();
              }
            },
          ),
          _Separator(),
          _SegmentRow(
            title: '거리',
            options: const ['km', 'mi'],
            selected: settings?.distanceUnit ?? 'km',
            onChanged: (v) {
              final cur = ref.read(unitSettingsProvider).valueOrNull;
              if (cur != null && cur.distanceUnit != v) {
                ref.read(unitSettingsProvider.notifier).toggleDistanceUnit();
              }
            },
          ),
          const SizedBox(height: 32),
          const _SectionHeader('앱 정보'),
          const _InfoRow(title: '버전', value: '1.0.0'),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SegmentRow({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 16)),
          ),
          CupertinoSlidingSegmentedControl<String>(
            groupValue: selected,
            thumbColor: AppTheme.card,
            backgroundColor: AppTheme.background,
            children: {
              for (final opt in options)
                opt: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(opt,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected == opt
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected == opt
                            ? AppTheme.accent
                            : AppTheme.textPrimary,
                      )),
                ),
            },
            onValueChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.card,
      child: const Divider(
          height: 0.5, thickness: 0.5, color: AppTheme.separator, indent: 16),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;
  const _InfoRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 16))),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }
}
