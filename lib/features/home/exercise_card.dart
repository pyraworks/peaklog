import 'package:flutter/material.dart';
import '../../core/models/exercise.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  const ExerciseCard({required this.exercise, super.key});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(exercise.name, style: const TextStyle(fontSize: 18)),
    ),
  );
}
