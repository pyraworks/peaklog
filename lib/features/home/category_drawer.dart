import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/models/exercise.dart';
import '../../core/theme/app_theme.dart';
import 'add_exercise_sheet.dart';

class CategoryDrawer extends StatelessWidget {
  final ExerciseCategory? selected;
  final List<Exercise> exercises;
  final ValueChanged<ExerciseCategory?> onCategorySelected;

  const CategoryDrawer({
    required this.selected,
    required this.exercises,
    required this.onCategorySelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text('PBPR',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5)),
            ),
            const Divider(
                height: 0.5, thickness: 0.5, color: AppTheme.separator),
            _DrawerTile(
              label: '전체',
              icon: CupertinoIcons.square_grid_2x2,
              count: exercises.length,
              selected: selected == null,
              onTap: () {
                onCategorySelected(null);
                Navigator.pop(context);
              },
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '카테고리',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8),
              ),
            ),
            ...ExerciseCategory.values.map((cat) {
              final count =
                  exercises.where((e) => e.category == cat).length;
              return _DrawerTile(
                label: cat.label,
                icon: _iconFor(cat),
                count: count,
                selected: selected == cat,
                onTap: () {
                  onCategorySelected(cat);
                  Navigator.pop(context);
                },
              );
            }),
            const Spacer(),
            const Divider(
                height: 0.5, thickness: 0.5, color: AppTheme.separator),
            _DrawerTile(
              label: '운동 추가',
              icon: CupertinoIcons.plus_circle,
              count: null,
              selected: false,
              accent: true,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddExerciseScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(ExerciseCategory cat) {
    switch (cat) {
      case ExerciseCategory.strength:
        return CupertinoIcons.bolt_fill;
      case ExerciseCategory.running:
        return CupertinoIcons.arrow_right_circle_fill;
      case ExerciseCategory.workout:
        return CupertinoIcons.timer_fill;
      case ExerciseCategory.custom:
        return CupertinoIcons.star_fill;
    }
  }
}

class _DrawerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final int? count;
  final bool selected;
  final bool accent;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        (accent || selected) ? AppTheme.accent : AppTheme.textPrimary;
    return Material(
      color: selected
          ? AppTheme.accent.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: AppTheme.accent.withValues(alpha: 0.05),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400),
                ),
              ),
              if (count != null)
                Text(
                  '$count',
                  style: TextStyle(
                      color: selected
                          ? AppTheme.accent
                          : AppTheme.textSecondary,
                      fontSize: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
