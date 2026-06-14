import 'package:uuid/uuid.dart';
import '../enums/sync_status.dart';

const _uuid = Uuid();

class Record {
  final String id;
  final String? ownerId;
  final String exerciseId;
  final int performedAt;
  final double? weight;
  final int? reps;
  final int? rounds;
  final int? durationSeconds;
  final int? durationMinutes;
  final double? distance;
  final String distanceUnit;
  final String? note;
  final String? metadataJson;
  final bool isDeleted;
  final int createdAt;
  final int updatedAt;
  final SyncStatus syncStatus;

  const Record({
    required this.id,
    this.ownerId,
    required this.exerciseId,
    required this.performedAt,
    this.weight,
    this.reps,
    this.rounds,
    this.durationSeconds,
    this.durationMinutes,
    this.distance,
    this.distanceUnit = 'km',
    this.note,
    this.metadataJson,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pending,
  });

  factory Record.create({
    required String exerciseId,
    required int performedAt,
    double? weight,
    int? reps,
    int? rounds,
    int? durationSeconds,
    int? durationMinutes,
    double? distance,
    String distanceUnit = 'km',
    String? note,
    String? metadataJson,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Record(
      id: _uuid.v4(),
      exerciseId: exerciseId,
      performedAt: performedAt,
      weight: weight,
      reps: reps,
      rounds: rounds,
      durationSeconds: durationSeconds,
      durationMinutes: durationMinutes,
      distance: distance,
      distanceUnit: distanceUnit,
      note: note,
      metadataJson: metadataJson,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'owner_id': ownerId,
    'exercise_id': exerciseId,
    'performed_at': performedAt,
    'weight': weight,
    'reps': reps,
    'rounds': rounds,
    'duration_seconds': durationSeconds,
    'duration_minutes': durationMinutes,
    'distance': distance,
    'distance_unit': distanceUnit,
    'note': note,
    'metadata_json': metadataJson,
    'is_deleted': isDeleted ? 1 : 0,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'sync_status': syncStatus.name,
  };

  factory Record.fromMap(Map<String, dynamic> map) => Record(
    id: map['id'] as String,
    ownerId: map['owner_id'] as String?,
    exerciseId: map['exercise_id'] as String,
    performedAt: (map['performed_at'] as num).toInt(),
    weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
    reps: map['reps'] != null ? (map['reps'] as num).toInt() : null,
    rounds: map['rounds'] != null ? (map['rounds'] as num).toInt() : null,
    durationSeconds: map['duration_seconds'] != null
        ? (map['duration_seconds'] as num).toInt() : null,
    durationMinutes: map['duration_minutes'] != null
        ? (map['duration_minutes'] as num).toInt() : null,
    distance: map['distance'] != null ? (map['distance'] as num).toDouble() : null,
    distanceUnit: map['distance_unit'] as String? ?? 'km',
    note: map['note'] as String?,
    metadataJson: map['metadata_json'] as String?,
    isDeleted: (map['is_deleted'] as num).toInt() == 1,
    createdAt: (map['created_at'] as num).toInt(),
    updatedAt: (map['updated_at'] as num).toInt(),
    syncStatus: SyncStatus.values.byName(map['sync_status'] as String),
  );

  Record copyWith({
    String? id,
    String? ownerId,
    String? exerciseId,
    int? performedAt,
    double? weight,
    int? reps,
    int? rounds,
    int? durationSeconds,
    int? durationMinutes,
    double? distance,
    String? distanceUnit,
    String? note,
    String? metadataJson,
    bool? isDeleted,
    int? createdAt,
    int? updatedAt,
    SyncStatus? syncStatus,
  }) => Record(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    exerciseId: exerciseId ?? this.exerciseId,
    performedAt: performedAt ?? this.performedAt,
    weight: weight ?? this.weight,
    reps: reps ?? this.reps,
    rounds: rounds ?? this.rounds,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    distance: distance ?? this.distance,
    distanceUnit: distanceUnit ?? this.distanceUnit,
    note: note ?? this.note,
    metadataJson: metadataJson ?? this.metadataJson,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
