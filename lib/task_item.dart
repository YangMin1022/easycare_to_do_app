// lib/task_item.dart
import 'package:flutter/material.dart';

class TaskItem {
  final String id;
  final String title;
  final String note;
  final DateTime due;
  final Duration? reminderBefore;
  bool completed;

  TaskItem({
    required this.id,
    required this.title,
    required this.note,
    required this.due,
    this.reminderBefore,
    this.completed = false,
  });
}