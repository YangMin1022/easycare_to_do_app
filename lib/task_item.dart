// lib/task_item.dart
enum TaskStatus { pending, completed, snoozed }

class TaskItem {
  final String id;
  final String title;
  final String note;
  final DateTime due;
  final Duration? reminderBefore;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TaskStatus status;
  bool completed;

  TaskItem({
    required this.id,
    required this.title,
    required this.note,
    required this.due,
    this.reminderBefore,
    required this.createdAt,
    required this.updatedAt,
    this.completed = false,
    this.status = TaskStatus.pending,
  });

  TaskItem copyWith({
    String? id,
    String? title,
    String? note,
    DateTime? due,
    DateTime? createdAt,
    DateTime? updatedAt,
    Duration? reminderBefore,
    bool? completed,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      due: due ?? this.due,
      reminderBefore: reminderBefore ?? this.reminderBefore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completed: completed ?? this.completed,
    );
  }
}