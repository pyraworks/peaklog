import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/exercises_provider.dart';
import 'exercise_card.dart';
import 'unit_toggle.dart';
import 'add_exercise_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddExerciseSheet(),
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
