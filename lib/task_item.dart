// lib/task_item.dart
enum TaskStatus { pending, completed, snoozed }

class TaskItem {
  final String id;
  final String title;
  final String note;
  final DateTime due;
  //OLD
  final Duration? reminderBefore;
  // The exact date/time the alarm should ring (Source of Truth)
  final DateTime? reminderTime;   
  // The system ID so we can cancel this specific alarm later
  final int? notificationId;
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
    this.reminderTime,
    this.notificationId,
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
    DateTime? reminderTime,
    int? notificationId,
    bool? completed,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      due: due ?? this.due,
      reminderBefore: reminderBefore ?? this.reminderBefore,
      reminderTime: reminderTime ?? this.reminderTime,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completed: completed ?? this.completed,
    );
  }
}