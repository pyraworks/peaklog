import 'package:flutter/material.dart';
import '../../core/models/exercise.dart';

class HistoryScreen extends StatelessWidget {
  final Exercise exercise;
  const HistoryScreen({required this.exercise, super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(exercise.name)),
    body: const Center(child: Text('히스토리 (곧 구현)')),
  );
}
