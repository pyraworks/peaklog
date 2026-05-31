import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/exercises_provider.dart';
import '../settings/settings_screen.dart';
import 'exercise_card.dart';
import 'unit_toggle.dart';
import 'add_exercise_sheet.dart' show AddExerciseScreen;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final canAdd = (exercisesAsync.valueOrNull?.length ?? 0) < 6;

    return Scaffold(
      drawer: const _AppDrawer(),
      appBar: AppBar(
        title: const Text('PBPR'),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: UnitToggle(),
          ),
          if (canAdd)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddExerciseScreen()),
              ),
              child: const Icon(CupertinoIcons.add,
                  color: AppTheme.accent, size: 22),
            ),
        ],
      ),
      body: Column(
        children: [
          const Divider(
              height: 0.5, thickness: 0.5, color: AppTheme.separator),
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(
                child:
                    CircularProgressIndicator(color: AppTheme.accent),
              ),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (exercises) {
                if (exercises.isEmpty) {
                  return _EmptyState(
                    onAdd: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddExerciseScreen()),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  itemCount: exercises.length,
                  itemBuilder: (_, i) {
                    final isFirst = i == 0;
                    final isLast = i == exercises.length - 1;
                    return ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: isFirst
                            ? const Radius.circular(10)
                            : Radius.zero,
                        bottom: isLast
                            ? const Radius.circular(10)
                            : Radius.zero,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ExerciseCard(exercise: exercises[i]),
                          if (!isLast)
                            const Divider(
                              height: 0.5,
                              thickness: 0.5,
                              color: AppTheme.separator,
                              indent: 16,
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text(
                'PBPR',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
            const Divider(
                height: 0.5,
                thickness: 0.5,
                color: AppTheme.separator),
            _DrawerItem(
              icon: CupertinoIcons.list_bullet,
              label: '운동 목록',
              onTap: () => Navigator.pop(context),
            ),
            const Divider(
                height: 0.5,
                thickness: 0.5,
                color: AppTheme.separator,
                indent: 52),
            _DrawerItem(
              icon: CupertinoIcons.settings,
              label: '설정',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const Divider(
                height: 0.5,
                thickness: 0.5,
                color: AppTheme.separator),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textPrimary, size: 20),
      title: Text(label,
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w400)),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.heart,
              color: AppTheme.textSecondary, size: 40),
          const SizedBox(height: 12),
          const Text('운동을 추가해보세요',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: onAdd, child: const Text('운동 추가')),
        ],
      ),
    );
  }
}
