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

    return Scaffold(
      drawer: const _AppDrawer(),
      appBar: AppBar(
        title: const Text('PBPR'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: UnitToggle(),
          ),
        ],
      ),
      body: exercisesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (exercises) => exercises.isEmpty
            ? _EmptyState(onAdd: () => _showAddSheet(context, ref))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: exercises.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ExerciseCard(exercise: exercises[i]),
                ),
              ),
      ),
      floatingActionButton: exercisesAsync.valueOrNull != null &&
              exercisesAsync.valueOrNull!.length < 6
          ? FloatingActionButton.extended(
              onPressed: () => _showAddSheet(context, ref),
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('운동 추가',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExerciseScreen()),
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
              padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Text(
                'PBPR',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
            const Divider(height: 0.5, thickness: 0.5, color: AppTheme.separator),
            _DrawerItem(
              icon: Icons.fitness_center,
              label: '운동 목록',
              onTap: () => Navigator.pop(context),
            ),
            const Divider(height: 0.5, thickness: 0.5, color: AppTheme.separator, indent: 56),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: '설정',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const Divider(height: 0.5, thickness: 0.5, color: AppTheme.separator),
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
      leading: Icon(icon, color: AppTheme.textPrimary, size: 22),
      title: Text(label,
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w400)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
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
          const Text('운동을 추가해보세요',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('운동 추가'),
          ),
        ],
      ),
    );
  }
}
