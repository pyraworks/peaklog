import 'package:flutter/material.dart';
import '../../core/models/exercise.dart';

class ExportScreen extends StatelessWidget {
  final Exercise exercise;
  final double newValue;
  const ExportScreen({required this.exercise, required this.newValue, super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('공유')),
      body: const Center(child: Text('내보내기 (곧 구현)')));
}
