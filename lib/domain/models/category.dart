import '../../core/enums/sync_status.dart';
import 'package:flutter/material.dart';

/// Fixed 8-color palette. Colors are stored as named keys (e.g. 'amber').
class CategoryColor {
  CategoryColor._();

  static const palette = [
    'crimson', 'rust', 'gold', 'teal', 'ocean', 'olive', 'forest',
  ];

  static Color toColor(String? key) => switch (key) {
    // Current palette
    'crimson' => const Color(0xFF9B2226),
    'rust'    => const Color(0xFFD55A21),
    'gold'    => const Color(0xFFF1B42F),
    'teal'    => const Color(0xFF0A9396),
    'ocean'   => const Color(0xFF005F73),
    'olive'   => const Color(0xFF556E40),
    'forest'  => const Color(0xFF213521),
    // Reserved for Uncategorized
    'gray'    => const Color(0xFF8E8E93),
    _         => const Color(0xFF8E8E93),
  };
}

class Category {
  // ── Fallback category — cannot be deleted ────────────────────────
  static const uncategorizedId = 'uncategorized';

  // ── Legacy preset IDs — kept for backward compat only ───────────
  // Existing users may still have exercises referencing these IDs.
  static const weightliftingId = 'preset-category-weightlifting';
  static const powerliftingId  = 'preset-category-powerlifting';
  static const runningId       = 'preset-category-running';
  static const crossfitId      = 'preset-category-crossfit';
  static const gymnasticsId    = 'preset-category-gymnastics';
  static const otherId         = 'preset-category-other';
  static const runId           = 'preset-category-run';
  static const wodId           = 'preset-category-wod';
  static const customId        = 'preset-category-custom';

  final String id;
  final String name;
  final String color; // a key from CategoryColor.palette
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  final SyncStatus syncStatus;

  const Category({
    required this.id,
    required this.name,
    this.color = 'gray',
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pending,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'color': color,
    'sort_order': sortOrder,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'sync_status': syncStatus.name,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as String,
    name: map['name'] as String,
    color: (map['color'] as String?) ?? 'gray',
    sortOrder: (map['sort_order'] as num).toInt(),
    createdAt: (map['created_at'] as num).toInt(),
    updatedAt: (map['updated_at'] as num).toInt(),
    syncStatus: SyncStatus.values.byName(map['sync_status'] as String),
  );

  Category copyWith({
    String? id,
    String? name,
    String? color,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
    SyncStatus? syncStatus,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );

  static String nameForId(String? id, {String uncategorizedLabel = 'Uncategorized'}) {
    if (id == uncategorizedId) return uncategorizedLabel;
    // Legacy preset names — backward compat for existing data
    if (id == weightliftingId) return 'Weightlifting';
    if (id == powerliftingId)  return 'Powerlifting';
    if (id == runningId)       return 'Running';
    if (id == crossfitId)      return 'CrossFit';
    if (id == gymnasticsId)    return 'Gymnastics';
    if (id == otherId)         return 'Other';
    if (id == runId)           return 'Run';
    if (id == wodId)           return 'WOD';
    if (id == customId)        return 'Custom';
    return uncategorizedLabel;
  }

  /// Seeded on new installs only — Uncategorized is the sole default.
  static List<Category> get presets {
    final now = DateTime(2026, 1, 1).millisecondsSinceEpoch;
    return [
      Category(id: uncategorizedId, name: 'Uncategorized', color: 'gray', sortOrder: 0, createdAt: now, updatedAt: now),
    ];
  }
}
