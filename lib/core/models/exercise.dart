import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum ExerciseCategory { strength, running, workout, custom }

extension ExerciseCategoryX on ExerciseCategory {
  String get label {
    switch (this) {
      case ExerciseCategory.strength: return '무게';
      case ExerciseCategory.running:  return '러닝';
      case ExerciseCategory.workout:  return '와드';
      case ExerciseCategory.custom:   return '커스텀';
    }
  }

  String get description {
    switch (this) {
      case ExerciseCategory.strength: return '스쿼트, 데드리프트 등';
      case ExerciseCategory.running:  return '5km, 10km 달리기 등';
      case ExerciseCategory.workout:  return 'Fran, Murph 등';
      case ExerciseCategory.custom:   return '기타 운동';
    }
  }
}

enum Visibility { private, public }

enum SyncStatus { pending, synced, failed }

class Exercise {
  final String id;
  final String ownerId;
  final String displayName;
  final String normalizedName;
  final ExerciseCategory category;
  final Visibility visibility;
  final bool isArchived;
  final int orderIndex;
  final int createdAt;
  final int updatedAt;
  final SyncStatus syncStatus;

  const Exercise({
    required this.id,
    this.ownerId = 'local',
    required this.displayName,
    required this.normalizedName,
    required this.category,
    this.visibility = Visibility.private,
    this.isArchived = false,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pending,
  });

  factory Exercise.create({
    required String displayName,
    required ExerciseCategory category,
    required int orderIndex,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Exercise(
      id: _uuid.v4(),
      displayName: displayName,
      normalizedName: normalizeExerciseName(displayName),
      category: category,
      orderIndex: orderIndex,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'owner_id': ownerId,
    'display_name': displayName,
    'normalized_name': normalizedName,
    'category': category.name,
    'visibility': visibility.name,
    'is_archived': isArchived ? 1 : 0,
    'order_index': orderIndex,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'sync_status': syncStatus.name,
  };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
    id: map['id'] as String,
    ownerId: map['owner_id'] as String,
    displayName: map['display_name'] as String,
    normalizedName: map['normalized_name'] as String,
    category: ExerciseCategory.values.byName(map['category'] as String),
    visibility: Visibility.values.byName(map['visibility'] as String),
    isArchived: (map['is_archived'] as num).toInt() == 1,
    orderIndex: (map['order_index'] as num).toInt(),
    createdAt: (map['created_at'] as num).toInt(),
    updatedAt: (map['updated_at'] as num).toInt(),
    syncStatus: SyncStatus.values.byName(map['sync_status'] as String),
  );

  Exercise copyWith({
    String? id, String? ownerId, String? displayName, String? normalizedName,
    ExerciseCategory? category, Visibility? visibility, bool? isArchived,
    int? orderIndex, int? createdAt, int? updatedAt, SyncStatus? syncStatus,
  }) => Exercise(
    id: id ?? this.id, ownerId: ownerId ?? this.ownerId,
    displayName: displayName ?? this.displayName,
    normalizedName: normalizedName ?? this.normalizedName,
    category: category ?? this.category, visibility: visibility ?? this.visibility,
    isArchived: isArchived ?? this.isArchived, orderIndex: orderIndex ?? this.orderIndex,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}

String normalizeExerciseName(String input) => input
    .trim().toLowerCase()
    .replaceAll(RegExp(r'\s+'), '_')
    .replaceAll(RegExp(r'[^a-z0-9_]'), '');
