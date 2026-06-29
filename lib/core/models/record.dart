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
  final String weightUnit;
  final String? note;
  final String? metadataJson;
  final bool isDeleted;
  final int createdAt;
  final int updatedAt;
  final SyncStatus syncStatus;
  final int? timeCap;

  const Record({
    required this.id,
    this.ownerId,
    required this.exerciseId,
    required this.performedAt,
    this.weight,
    this.weightUnit = 'kg',
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
    this.timeCap,
  });

  factory Record.create({
    required String exerciseId,
    required int performedAt,
    double? weight,
    String weightUnit = 'kg',
    int? reps,
    int? rounds,
    int? durationSeconds,
    int? durationMinutes,
    double? distance,
    String distanceUnit = '',
    String? note,
    String? metadataJson,
    int? timeCap,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Record(
      id: _uuid.v4(),
      exerciseId: exerciseId,
      performedAt: performedAt,
      weight: weight,
      weightUnit: weightUnit,
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
      timeCap: timeCap,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'owner_id': ownerId,
    'exercise_id': exerciseId,
    'performed_at': performedAt,
    'weight': weight,
    'weight_unit': weightUnit,
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
    'time_cap': timeCap,
  };

  factory Record.fromMap(Map<String, dynamic> map) => Record(
    id: map['id'] as String,
    ownerId: map['owner_id'] as String?,
    exerciseId: map['exercise_id'] as String,
    performedAt: (map['performed_at'] as num).toInt(),
    weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
    weightUnit: (() {
      final u = map['weight_unit'] as String?;
      return (u == null || u.isEmpty) ? 'kg' : u;
    })(),
    reps: map['reps'] != null ? (map['reps'] as num).toInt() : null,
    rounds: map['rounds'] != null ? (map['rounds'] as num).toInt() : null,
    durationSeconds: map['duration_seconds'] != null
        ? (map['duration_seconds'] as num).toInt() : null,
    durationMinutes: map['duration_minutes'] != null
        ? (map['duration_minutes'] as num).toInt() : null,
    distance: map['distance'] != null ? (map['distance'] as num).toDouble() : null,
    distanceUnit: map['distance_unit'] as String? ?? '',
    note: map['note'] as String?,
    metadataJson: map['metadata_json'] as String?,
    isDeleted: (map['is_deleted'] as num).toInt() == 1,
    createdAt: (map['created_at'] as num).toInt(),
    updatedAt: (map['updated_at'] as num).toInt(),
    syncStatus: SyncStatus.values.byName(map['sync_status'] as String),
    timeCap: map['time_cap'] != null ? (map['time_cap'] as num).toInt() : null,
  );

  static const _unset = Object();

  Record copyWith({
    String? id,
    Object? ownerId = _unset,
    String? exerciseId,
    int? performedAt,
    Object? weight = _unset,
    String? weightUnit,
    Object? reps = _unset,
    Object? rounds = _unset,
    Object? durationSeconds = _unset,
    Object? durationMinutes = _unset,
    Object? distance = _unset,
    String? distanceUnit,
    Object? note = _unset,
    Object? metadataJson = _unset,
    bool? isDeleted,
    int? createdAt,
    int? updatedAt,
    SyncStatus? syncStatus,
    Object? timeCap = _unset,
  }) => Record(
    id: id ?? this.id,
    ownerId: identical(ownerId, _unset) ? this.ownerId : ownerId as String?,
    exerciseId: exerciseId ?? this.exerciseId,
    performedAt: performedAt ?? this.performedAt,
    weight: identical(weight, _unset) ? this.weight : weight as double?,
    weightUnit: weightUnit ?? this.weightUnit,
    reps: identical(reps, _unset) ? this.reps : reps as int?,
    rounds: identical(rounds, _unset) ? this.rounds : rounds as int?,
    durationSeconds: identical(durationSeconds, _unset)
        ? this.durationSeconds
        : durationSeconds as int?,
    durationMinutes: identical(durationMinutes, _unset)
        ? this.durationMinutes
        : durationMinutes as int?,
    distance: identical(distance, _unset) ? this.distance : distance as double?,
    distanceUnit: distanceUnit ?? this.distanceUnit,
    note: identical(note, _unset) ? this.note : note as String?,
    metadataJson: identical(metadataJson, _unset)
        ? this.metadataJson
        : metadataJson as String?,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    timeCap: identical(timeCap, _unset) ? this.timeCap : timeCap as int?,
  );
}
