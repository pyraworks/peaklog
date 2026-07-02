import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Note {
  final String id;
  final int performedOn;
  final String title;
  final String body;
  final int sortOrder;
  final bool isDeleted;
  final int createdAt;
  final int updatedAt;

  const Note({
    required this.id,
    required this.performedOn,
    this.title = '',
    this.body = '',
    this.sortOrder = 0,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.create({
    required int performedOn,
    String title = '',
    String body = '',
    int sortOrder = 0,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Note(
      id: _uuid.v4(),
      performedOn: performedOn,
      title: title,
      body: body,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'performed_on': performedOn,
        'title': title,
        'body': body,
        'sort_order': sortOrder,
        'is_deleted': isDeleted ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
        id: map['id'] as String,
        performedOn: (map['performed_on'] as num).toInt(),
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        sortOrder: (map['sort_order'] as num).toInt(),
        isDeleted: (map['is_deleted'] as num).toInt() == 1,
        createdAt: (map['created_at'] as num).toInt(),
        updatedAt: (map['updated_at'] as num).toInt(),
      );

  Note copyWith({
    String? id,
    int? performedOn,
    String? title,
    String? body,
    int? sortOrder,
    bool? isDeleted,
    int? createdAt,
    int? updatedAt,
  }) =>
      Note(
        id: id ?? this.id,
        performedOn: performedOn ?? this.performedOn,
        title: title ?? this.title,
        body: body ?? this.body,
        sortOrder: sortOrder ?? this.sortOrder,
        isDeleted: isDeleted ?? this.isDeleted,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
