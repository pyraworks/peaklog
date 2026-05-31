enum ExerciseType { weight, time, distance }

extension ExerciseTypeLabel on ExerciseType {
  String get label {
    switch (this) {
      case ExerciseType.weight:
        return '무게';
      case ExerciseType.time:
        return '시간';
      case ExerciseType.distance:
        return '거리';
    }
  }
}

class Exercise {
  final int? id;
  final String name;
  final ExerciseType type;
  final int orderIndex;
  final int createdAt;

  const Exercise({
    this.id,
    required this.name,
    required this.type,
    required this.orderIndex,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'type': type.name,
      'order_index': orderIndex,
      'created_at': createdAt,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'] != null ? (map['id'] as num).toInt() : null,
        name: map['name'] as String,
        type: ExerciseType.values.byName(map['type'] as String),
        orderIndex: (map['order_index'] as num).toInt(),
        createdAt: (map['created_at'] as num).toInt(),
      );

  Exercise copyWith({
    int? id,
    String? name,
    ExerciseType? type,
    int? orderIndex,
    int? createdAt,
  }) =>
      Exercise(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        orderIndex: orderIndex ?? this.orderIndex,
        createdAt: createdAt ?? this.createdAt,
      );
}
