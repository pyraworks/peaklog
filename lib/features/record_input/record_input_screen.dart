import 'package:flutter/material.dart';
import '../../core/models/exercise.dart';

class RecordInputScreen extends StatelessWidget {
  final Exercise exercise;
  const RecordInputScreen({required this.exercise, super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(exercise.name)),
    body: const Center(child: Text('기록 입력 (곧 구현)')),
  );
}
