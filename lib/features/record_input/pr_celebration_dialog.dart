import 'package:flutter/material.dart';
import '../../core/models/exercise.dart';

class PRCelebrationDialog extends StatelessWidget {
  final Exercise exercise;
  final double newValue;
  final double? previousBest;
  const PRCelebrationDialog({
    required this.exercise,
    required this.newValue,
    this.previousBest,
    super.key,
  });
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('PR 달성!'),
    content: Text('${exercise.name} 신기록!'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('확인'),
      ),
    ],
  );
}
