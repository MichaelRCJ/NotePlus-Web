import 'package:flutter/material.dart';

enum TaskType {
  homework,
  exam,
  project,
  assignment,
  study,
  other,
}

extension TaskTypeExtension on TaskType {
  String get displayName {
    switch (this) {
      case TaskType.homework:
        return 'Tarea';
      case TaskType.exam:
        return 'Examen';
      case TaskType.project:
        return 'Proyecto';
      case TaskType.assignment:
        return 'Trabajo';
      case TaskType.study:
        return 'Estudio';
      case TaskType.other:
        return 'Otro';
    }
  }
}

class NoteModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final List<String> tags;
  final String category;
  final bool isPinned;
  final Color? backgroundColor;
  final DateTime? reminderAt;
  final List<TaskItem> tasks;
  final List<String> attachments; // Base64 encoded files or file paths
  final String? drawingData; // Base64 encoded drawing image

  NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.modifiedAt,
    this.tags = const [],
    this.category = '',
    this.isPinned = false,
    this.backgroundColor,
    this.reminderAt,
    this.tasks = const [],
    this.attachments = const [],
    this.drawingData,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'tags': tags,
      'category': category,
      'isPinned': isPinned,
      'backgroundColor': backgroundColor?.value,
      'reminderAt': reminderAt?.toIso8601String(),
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'attachments': attachments,
      'drawingData': drawingData,
    };
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      userId: json['userId'] ?? '',
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      modifiedAt: DateTime.parse(json['modifiedAt']),
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'] ?? '',
      isPinned: json['isPinned'] ?? false,
      backgroundColor: json['backgroundColor'] != null 
          ? Color(json['backgroundColor']) 
          : null,
      reminderAt: json['reminderAt'] != null 
          ? DateTime.parse(json['reminderAt']) 
          : null,
      tasks: (json['tasks'] as List?)?.map((task) => TaskItem.fromJson(task)).toList() ?? [],
      attachments: List<String>.from(json['attachments'] ?? []),
      drawingData: json['drawingData'],
    );
  }

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    String? category,
    bool? isPinned,
    Color? backgroundColor,
    DateTime? reminderAt,
    List<TaskItem>? tasks,
    List<String>? attachments,
    String? drawingData,
    DateTime? modifiedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      reminderAt: reminderAt ?? this.reminderAt,
      tasks: tasks ?? this.tasks,
      attachments: attachments ?? this.attachments,
      drawingData: drawingData ?? this.drawingData,
    );
  }
}

class TaskItem {
  final String id;
  final String title;
  final String description;
  final TaskType type;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? dueDate;
  final int priority; // 1-5, where 5 is highest
  final List<String> attachments; // Base64 encoded files

  TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    this.type = TaskType.other,
    this.isCompleted = false,
    required this.createdAt,
    this.startDate,
    this.dueDate,
    this.priority = 3,
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
      'attachments': attachments,
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    TaskType taskType = TaskType.other;
    try {
      if (json['type'] != null) {
        final typeString = json['type'].toString();
        // Handle both "TaskType.other" format and just "other" format
        final cleanType = typeString.contains('.') 
            ? typeString.split('.').last 
            : typeString;
        taskType = TaskType.values.firstWhere(
          (e) => e.toString().split('.').last == cleanType,
          orElse: () => TaskType.other,
        );
      }
    } catch (e) {
      taskType = TaskType.other;
    }

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(json['createdAt']);
    } catch (e) {
      createdAt = DateTime.now();
    }

    DateTime? startDate;
    try {
      if (json['startDate'] != null && json['startDate'].toString().isNotEmpty) {
        startDate = DateTime.parse(json['startDate']);
      }
    } catch (e) {
      startDate = null;
    }

    DateTime? dueDate;
    try {
      if (json['dueDate'] != null && json['dueDate'].toString().isNotEmpty) {
        dueDate = DateTime.parse(json['dueDate']);
      }
    } catch (e) {
      dueDate = null;
    }

    int priority = 3;
    try {
      if (json['priority'] != null) {
        priority = json['priority'] is int ? json['priority'] : int.tryParse(json['priority'].toString()) ?? 3;
        if (priority < 1 || priority > 5) priority = 3;
      }
    } catch (e) {
      priority = 3;
    }

    return TaskItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: taskType,
      isCompleted: json['isCompleted'] ?? false,
      createdAt: createdAt,
      startDate: startDate,
      dueDate: dueDate,
      priority: priority,
      attachments: List<String>.from(json['attachments'] ?? []),
    );
  }

  TaskItem copyWith({
    String? title,
    String? description,
    TaskType? type,
    bool? isCompleted,
    DateTime? startDate,
    DateTime? dueDate,
    int? priority,
    List<String>? attachments,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      attachments: attachments ?? this.attachments,
    );
  }

  Color get priorityColor {
    switch (priority) {
      case 5:
        return Colors.red;
      case 4:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 2:
        return Colors.blue;
      case 1:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// Categorías predefinidas para estudiantes
class StudentCategories {
  static const List<String> categories = [
    'Matemáticas',
    'Ciencias',
    'Historia',
    'Literatura',
    'Idiomas',
    'Arte',
    'Música',
    'Educación Física',
    'Informática',
    'Filosofía',
    'Geografía',
    'Química',
    'Física',
    'Biología',
    'Economía',
    'Psicología',
    'Sociología',
    'Proyectos',
    'Exámenes',
    'Tareas',
    'Estudio',
    'Personal',
  ];
}
