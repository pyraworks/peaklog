class PublicRecord {
  final String exerciseId;
  final int displayOrder;
  final int createdAt;
  final int updatedAt;

  const PublicRecord({
    required this.exerciseId,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'exercise_id': exerciseId,
    'display_order': displayOrder,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory PublicRecord.fromMap(Map<String, dynamic> map) => PublicRecord(
    exerciseId: map['exercise_id'] as String,
    displayOrder: (map['display_order'] as num).toInt(),
    createdAt: (map['created_at'] as num).toInt(),
    updatedAt: (map['updated_at'] as num).toInt(),
  );
}
