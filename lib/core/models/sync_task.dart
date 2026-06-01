import 'package:uuid/uuid.dart';
import 'exercise.dart';

const _uuid = Uuid();

class SyncTask {
  final String id;
  final String entityType;
  final String entityId;
  final String operation; // create / update / delete
  final int retryCount;
  final int createdAt;
  final SyncStatus syncStatus;

  const SyncTask({
    required this.id, required this.entityType, required this.entityId,
    required this.operation, this.retryCount = 0,
    required this.createdAt, this.syncStatus = SyncStatus.pending,
  });

  factory SyncTask.create({
    required String entityType, required String entityId, required String operation,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return SyncTask(
      id: _uuid.v4(), entityType: entityType, entityId: entityId,
      operation: operation, createdAt: now,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'entity_type': entityType, 'entity_id': entityId,
    'operation': operation, 'retry_count': retryCount,
    'created_at': createdAt, 'sync_status': syncStatus.name,
  };

  factory SyncTask.fromMap(Map<String, dynamic> map) => SyncTask(
    id: map['id'] as String, entityType: map['entity_type'] as String,
    entityId: map['entity_id'] as String, operation: map['operation'] as String,
    retryCount: (map['retry_count'] as num).toInt(),
    createdAt: (map['created_at'] as num).toInt(),
    syncStatus: SyncStatus.values.byName(map['sync_status'] as String),
  );
}
