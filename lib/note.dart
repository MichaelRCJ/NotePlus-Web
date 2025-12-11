import 'package:uuid/uuid.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final List<String> tags;

  Note({
    required this.title,
    required this.content,
    this.tags = const [],
  })  : id = const Uuid().v4(),
        createdAt = DateTime.now(),
        modifiedAt = DateTime.now();

  Note.withId({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.modifiedAt,
    this.tags = const [],
  });

  Note copyWith({
    String? title,
    String? content,
    List<String>? tags,
  }) {
    return Note.withId(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      modifiedAt: DateTime.now(),
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'tags': tags,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note.withId(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      modifiedAt: DateTime.parse(json['modifiedAt']),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}
