import 'package:uuid/uuid.dart';
import '../enums/best_type.dart';
import '../enums/record_type.dart';
import '../enums/sync_status.dart';
import '../utils/normalize.dart';
import '../../domain/models/category.dart';

export '../enums/best_type.dart';
export '../enums/record_type.dart';
export '../enums/sync_status.dart';

const _uuid = Uuid();

class Exercise {
  final String id;
  final String displayName;
  final String normalizedName;
  final String? categoryId;
  final RecordType? recordType;
  final BestType? bestType;
  final bool isSystemPreset;
  final bool isArchived;
  final int orderIndex;
  final int createdAt;
  final int updatedAt;
  final SyncStatus syncStatus;
  final String? ownerId;
  final String baseUnit; // Internal values: 'kg' or 'lbs'. UI label: 'kg' / 'lb'.
  final bool hasPrBaseline; // true once user explicitly marks a first PR

  /// null → PR fallback (기존 데이터 호환)
  String get bestTypeLabel => (bestType ?? BestType.pr).label;

  const Exercise({
    required this.id,
    required this.displayName,
    required this.normalizedName,
    this.categoryId,
    this.recordType,
    this.bestType,
    this.isSystemPreset = false,
    this.isArchived = false,
    this.orderIndex = 0,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pending,
    this.ownerId,
    this.baseUnit = 'kg',
    this.hasPrBaseline = false,
  });

  factory Exercise.create({
    required String displayName,
    RecordType? recordType,
    BestType? bestType,
    String? categoryId,
    bool isSystemPreset = false,
    int orderIndex = 0,
    String baseUnit = 'kg',
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Exercise(
      id: _uuid.v4(),
      displayName: displayName,
      normalizedName: normalize(displayName),
      categoryId: categoryId,
      recordType: recordType,
      bestType: bestType,
      isSystemPreset: isSystemPreset,
      orderIndex: orderIndex,
      baseUnit: baseUnit,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'owner_id': ownerId,
    'display_name': displayName,
    'normalized_name': normalizedName,
    'category': _legacyCategoryName,
    'category_id': categoryId,
    'record_type': recordType?.name,
    'best_type': bestType?.name,
    'is_system_preset': isSystemPreset ? 1 : 0,
    'visibility': 'private',
    'is_archived': isArchived ? 1 : 0,
    'order_index': orderIndex,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'sync_status': syncStatus.name,
    'base_unit': baseUnit,
    'has_pr_baseline': hasPrBaseline ? 1 : 0,
  };

  factory Exercise.fromMap(Map<String, dynamic> map) {
    final recordTypeRaw = map['record_type'] as String?;
    final RecordType? rt = recordTypeRaw != null
        ? RecordType.values.byName(recordTypeRaw)
        : null;

    final bestTypeRaw = map['best_type'] as String?;
    final BestType? bt = bestTypeRaw != null
        ? BestType.values.byName(bestTypeRaw)
        : null;

    return Exercise(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String?,
      displayName: map['display_name'] as String,
      normalizedName: map['normalized_name'] as String,
      categoryId: map['category_id'] as String?,
      recordType: rt,
      bestType: bt,
      isSystemPreset: ((map['is_system_preset'] as num?)?.toInt() ?? 0) == 1,
      isArchived: (map['is_archived'] as num).toInt() == 1,
      orderIndex: (map['order_index'] as num).toInt(),
      createdAt: (map['created_at'] as num).toInt(),
      updatedAt: (map['updated_at'] as num).toInt(),
      syncStatus: SyncStatus.values.byName(map['sync_status'] as String),
      baseUnit: (map['base_unit'] as String?) ?? 'kg',
      hasPrBaseline: ((map['has_pr_baseline'] as num?)?.toInt() ?? 0) == 1,
    );
  }

  Exercise copyWith({
    String? id,
    String? ownerId,
    String? displayName,
    String? normalizedName,
    String? categoryId,
    RecordType? recordType,
    BestType? bestType,
    bool? isSystemPreset,
    bool? isArchived,
    int? orderIndex,
    int? createdAt,
    int? updatedAt,
    SyncStatus? syncStatus,
    String? baseUnit,
    bool? hasPrBaseline,
  }) => Exercise(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    displayName: displayName ?? this.displayName,
    normalizedName: normalizedName ?? this.normalizedName,
    categoryId: categoryId ?? this.categoryId,
    recordType: recordType ?? this.recordType,
    bestType: bestType ?? this.bestType,
    isSystemPreset: isSystemPreset ?? this.isSystemPreset,
    isArchived: isArchived ?? this.isArchived,
    orderIndex: orderIndex ?? this.orderIndex,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    baseUnit: baseUnit ?? this.baseUnit,
    hasPrBaseline: hasPrBaseline ?? this.hasPrBaseline,
  );

  // Legacy category name for the DB column
  String get _legacyCategoryName {
    if (categoryId == Category.weightliftingId) return 'strength';
    if (categoryId == Category.runId) return 'running';
    if (categoryId == Category.wodId) return 'workout';
    if (categoryId == Category.customId) return 'custom';
    switch (recordType) {
      case RecordType.weight: return 'strength';
      case RecordType.etc: return 'custom';
      case RecordType.forTime:
      case RecordType.amrap: return 'workout';
      case null: return 'custom';
    }
  }
}
