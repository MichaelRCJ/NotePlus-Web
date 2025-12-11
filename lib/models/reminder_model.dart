class Reminder {
  final String id;
  final String title;
  final String description;
  final DateTime reminderAt;
  final bool isCompleted;
  final bool isTriggered;
  final String noteId;
  final String userId;

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.reminderAt,
    this.isCompleted = false,
    this.isTriggered = false,
    required this.noteId,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reminderAt': reminderAt.toIso8601String(),
      'isCompleted': isCompleted,
      'isTriggered': isTriggered,
      'noteId': noteId,
      'userId': userId,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      reminderAt: DateTime.parse(json['reminderAt']),
      isCompleted: json['isCompleted'] ?? false,
      isTriggered: json['isTriggered'] ?? false,
      noteId: json['noteId'] ?? '',
      userId: json['userId'] ?? '',
    );
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? reminderAt,
    bool? isCompleted,
    bool? isTriggered,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderAt: reminderAt ?? this.reminderAt,
      isCompleted: isCompleted ?? this.isCompleted,
      isTriggered: isTriggered ?? this.isTriggered,
      noteId: noteId,
      userId: userId,
    );
  }
}

