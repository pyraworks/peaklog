import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/exercises_provider.dart';

class AddExerciseScreen extends ConsumerStatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  ConsumerState<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends ConsumerState<AddExerciseScreen> {
  final _controller = TextEditingController();
  ExerciseCategory _selectedCategory = ExerciseCategory.strength;
  bool _saving = false;

  static const _categories = [
    (ExerciseCategory.strength, '무게', '스쿼트, 데드리프트 등'),
    (ExerciseCategory.running,  '러닝', '5km, 10km 달리기 등'),
    (ExerciseCategory.workout,  '와드', 'Fran, Murph 등'),
    (ExerciseCategory.custom,   '커스텀', '기타 운동'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('운동 추가')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: '운동 이름',
                hintText: '예: Back Squat, 5km Run',
              ),
            ),
            const SizedBox(height: 24),
            const Text('운동 카테고리',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
            ..._categories.map((t) => _CategoryTile(
                  category: t.$1,
                  label: t.$2,
                  description: t.$3,
                  selected: _selectedCategory == t.$1,
                  onTap: () => setState(() => _selectedCategory = t.$1),
                )),
            const Spacer(),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('추가'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    await ref
        .read(exercisesProvider.notifier)
        .addExercise(name, _selectedCategory);
    if (mounted) Navigator.pop(context);
  }
}

class _CategoryTile extends StatelessWidget {
  final ExerciseCategory category;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent.withValues(alpha: 0.1)
              : AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.separator,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: selected
                              ? AppTheme.accent
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w700)),
                  Text(description,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.accent, size: 20),
          ],
        ),
      ),
    );
  }
}
