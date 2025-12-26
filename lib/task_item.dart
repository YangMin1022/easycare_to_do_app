// lib/task_item.dart
import 'package:flutter/material.dart';

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
}