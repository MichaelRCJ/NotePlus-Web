import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

enum NoteType {
  text,
  drawing,
  task,
  checklist,
}

class Note {
  final String id;
  final String userId;
  final String title;
  final String content;
  final NoteType type;
  final List<String> tags;
  final List<String> attachments;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final DateTime? reminderAt;
  final String? drawingData;
  final List<TaskItem>? taskItems;
  final String? category;
  final Color? backgroundColor;

  Note({
    required this.userId,
    required this.title,
    required this.content,
    this.type = NoteType.text,
    this.tags = const [],
    this.attachments = const [],
    this.isPinned = false,
    this.reminderAt,
    this.drawingData,
    this.taskItems,
    this.category,
    this.backgroundColor,
  })  : id = const Uuid().v4(),
        createdAt = DateTime.now(),
        modifiedAt = DateTime.now();

  Note.withId({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.type,
    required this.tags,
    required this.attachments,
    required this.isPinned,
    required this.createdAt,
    required this.modifiedAt,
    this.reminderAt,
    this.drawingData,
    this.taskItems,
    this.category,
    this.backgroundColor,
  });

  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note.withId(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      type: NoteType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => NoteType.text,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      attachments: List<String>.from(data['attachments'] ?? []),
      isPinned: data['isPinned'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      modifiedAt: (data['modifiedAt'] as Timestamp).toDate(),
      reminderAt: data['reminderAt'] != null
          ? (data['reminderAt'] as Timestamp).toDate()
          : null,
      drawingData: data['drawingData'],
      taskItems: data['taskItems'] != null
          ? (data['taskItems'] as List)
              .map((item) => TaskItem.fromMap(item))
              .toList()
          : null,
      category: data['category'],
      backgroundColor: data['backgroundColor'] != null
          ? Color(int.parse(data['backgroundColor']))
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'type': type.toString(),
      'tags': tags,
      'attachments': attachments,
      'isPinned': isPinned,
      'createdAt': Timestamp.fromDate(createdAt),
      'modifiedAt': Timestamp.fromDate(modifiedAt),
      'reminderAt': reminderAt != null
          ? Timestamp.fromDate(reminderAt!)
          : null,
      'drawingData': drawingData,
      'taskItems': taskItems?.map((item) => item.toMap()).toList(),
      'category': category,
      'backgroundColor': backgroundColor?.value.toString(),
    };
  }

  Note copyWith({
    String? title,
    String? content,
    NoteType? type,
    List<String>? tags,
    List<String>? attachments,
    bool? isPinned,
    DateTime? reminderAt,
    String? drawingData,
    List<TaskItem>? taskItems,
    String? category,
    Color? backgroundColor,
  }) {
    return Note.withId(
      id: id,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      attachments: attachments ?? this.attachments,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      modifiedAt: DateTime.now(),
      reminderAt: reminderAt ?? this.reminderAt,
      drawingData: drawingData ?? this.drawingData,
      taskItems: taskItems ?? this.taskItems,
      category: category ?? this.category,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}

class TaskItem {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  TaskItem({
    required this.title,
    this.isCompleted = false,
  }) : id = const Uuid().v4(),
       createdAt = DateTime.now();

  TaskItem.withId({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
  });

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem.withId(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TaskItem copyWith({
    String? title,
    bool? isCompleted,
  }) {
    return TaskItem.withId(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}
