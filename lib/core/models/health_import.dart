class HealthImport {
  final String id;       // dedup hash: "${distM}_${durationSec}_${startSec}"
  final String? recordId;
  final int importedAt;  // ms since epoch

  const HealthImport({
    required this.id,
    this.recordId,
    required this.importedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'record_id': recordId,
    'imported_at': importedAt,
  };

  factory HealthImport.fromMap(Map<String, dynamic> map) => HealthImport(
    id: map['id'] as String,
    recordId: map['record_id'] as String?,
    importedAt: (map['imported_at'] as num).toInt(),
  );
}
