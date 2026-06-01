import 'exercise.dart';

enum PersonalBestType { maxWeight, bestTime, longestDistance, estimated1RM }

class PersonalBest {
  final String id;
  final String ownerId;
  final String exerciseId;
  final String sourceRecordId;
  final PersonalBestType type;
  final double value;
  final int achievedAt;
  final int createdAt;
  final int updatedAt;
  final SyncStatus syncStatus;

  const PersonalBest({
    required this.id,
    this.ownerId = 'local',
    required this.exerciseId,
    required this.sourceRecordId,
    required this.type,
    required this.value,
    required this.achievedAt,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pending,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'owner_id': ownerId, 'exercise_id': exerciseId,
    'source_record_id': sourceRecordId, 'pb_type': type.name,
    'value': value, 'achieved_at': achievedAt,
    'created_at': createdAt, 'updated_at': updatedAt,
    'sync_status': syncStatus.name,
  };

  factory PersonalBest.fromMap(Map<String, dynamic> map) => PersonalBest(
    id: map['id'] as String, ownerId: map['owner_id'] as String,
    exerciseId: map['exercise_id'] as String,
    sourceRecordId: map['source_record_id'] as String,
    type: PersonalBestType.values.byName(map['pb_type'] as String),
    value: (map['value'] as num).toDouble(),
    achievedAt: (map['achieved_at'] as num).toInt(),
    createdAt: (map['created_at'] as num).toInt(),
    updatedAt: (map['updated_at'] as num).toInt(),
    syncStatus: SyncStatus.values.byName(map['sync_status'] as String),
  );
}
