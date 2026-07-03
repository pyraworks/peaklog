enum ExerciseType {
  record,
  complete;

  static ExerciseType fromJson(String? v) => ExerciseType.values.firstWhere(
        (e) => e.name == v,
        orElse: () => ExerciseType.record,
      );
}
