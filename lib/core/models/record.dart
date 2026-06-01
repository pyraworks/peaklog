import 'package:uuid/uuid.dart';
import 'exercise.dart';

const _uuid = Uuid();

class Record {
  final String id;
  final String ownerId;
  final String exerciseId;
  final int performedAt;       // ms since epoch
  final double? weight;        // kg
  final int? reps;
  final int? durationSeconds;
  final double? distance;      // km
  final String? note;
  final String? mediaUrl;
  final bool isDeleted;
  final int createdAt;
  final int updatedAt;
  final SyncStatus syncStatus;

  const Record({
    required this.id,
    this.ownerId = 'local',
    required this.exerciseId,
    required this.performedAt,
    this.weight,
    this.reps,
    this.durationSeconds,
    this.distance,
    this.note,
    this.mediaUrl,
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
    int? durationSeconds,
    double? distance,
    String? note,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Record(
      id: _uuid.v4(),
      exerciseId: exerciseId,
      performedAt: performedAt,
      weight: weight,
      reps: reps,
      durationSeconds: durationSeconds,
      distance: distance,
      note: note,
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
    'duration_seconds': durationSeconds,
    'distance': distance,
    'note': note,
    'media_url': mediaUrl,
    'is_deleted': isDeleted ? 1 : 0,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'sync_status': syncStatus.name,
  };

  factory Record.fromMap(Map<String, dynamic> map) => Record(
    id: map['id'] as String,
    ownerId: map['owner_id'] as String,
    exerciseId: map['exercise_id'] as String,
    performedAt: (map['performed_at'] as num).toInt(),
    weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
    reps: map['reps'] != null ? (map['reps'] as num).toInt() : null,
    durationSeconds: map['duration_seconds'] != null
        ? (map['duration_seconds'] as num).toInt() : null,
    distance: map['distance'] != null ? (map['distance'] as num).toDouble() : null,
    note: map['note'] as String?,
    mediaUrl: map['media_url'] as String?,
    isDeleted: (map['is_deleted'] as num).toInt() == 1,
    createdAt: (map['created_at'] as num).toInt(),
    updatedAt: (map['updated_at'] as num).toInt(),
    syncStatus: SyncStatus.values.byName(map['sync_status'] as String),
  );

  Record copyWith({
    String? id, String? ownerId, String? exerciseId, int? performedAt,
    double? weight, int? reps, int? durationSeconds, double? distance,
    String? note, String? mediaUrl, bool? isDeleted,
    int? createdAt, int? updatedAt, SyncStatus? syncStatus,
  }) => Record(
    id: id ?? this.id, ownerId: ownerId ?? this.ownerId,
    exerciseId: exerciseId ?? this.exerciseId,
    performedAt: performedAt ?? this.performedAt,
    weight: weight ?? this.weight, reps: reps ?? this.reps,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    distance: distance ?? this.distance, note: note ?? this.note,
    mediaUrl: mediaUrl ?? this.mediaUrl,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
}
