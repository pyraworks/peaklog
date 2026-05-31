class Record {
  final int? id;
  final int exerciseId;
  final double value;
  final int recordedAt;
  final String? note;

  const Record({
    this.id,
    required this.exerciseId,
    required this.value,
    required this.recordedAt,
    this.note,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'exercise_id': exerciseId,
      'value': value,
      'recorded_at': recordedAt,
      'note': note,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Record.fromMap(Map<String, dynamic> map) => Record(
        id: map['id'] != null ? (map['id'] as num).toInt() : null,
        exerciseId: (map['exercise_id'] as num).toInt(),
        value: (map['value'] as num).toDouble(),
        recordedAt: (map['recorded_at'] as num).toInt(),
        note: map['note'] as String?,
      );

  Record copyWith({
    int? id,
    int? exerciseId,
    double? value,
    int? recordedAt,
    String? note,
  }) =>
      Record(
        id: id ?? this.id,
        exerciseId: exerciseId ?? this.exerciseId,
        value: value ?? this.value,
        recordedAt: recordedAt ?? this.recordedAt,
        note: note ?? this.note,
      );
}
