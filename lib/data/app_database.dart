// lib/data/app_database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../task_item.dart'; // adapt path if your TaskItem is in a different location

part 'app_database.g.dart';

/// Drift table definition that matches the fields used by TaskItem.
///
/// Note: The DB uses an integer auto-increment `id`. When mapping to your
/// TaskItem (which expects a String id) we convert using `id.toString()`.
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 512)();
  // TaskItem.note is non-nullable String in your model, keep default empty string
  TextColumn get note => text().withDefault(const Constant(''))();
  // store DateTime as epoch millis
  IntColumn get due => integer()();
  // store reminder as minutes (nullable)
  IntColumn get reminderBefore => integer().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  // store the enum TaskStatus as int: 0=pending,1=completed,2=snoozed
  IntColumn get status => integer().withDefault(const Constant(0))();
}

/// The AppDatabase class wraps generated code and exposes convenient helpers.
@DriftDatabase(tables: [Tasks])
class AppDatabase extends _$AppDatabase {
  // Use a singleton pattern for convenience
  AppDatabase._internal() : super(_openConnection());
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;

  @override
  int get schemaVersion => 1;

  // -------------------------
  // CRUD helpers (TaskItem based)
  // -------------------------

  /// Insert a TaskItem into the DB.
  ///
  /// Returns the int id (auto-generated). The caller can use id.toString()
  /// to populate TaskItem.id if desired.
  Future<int> insertTaskItem(TaskItem item) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final companion = TasksCompanion.insert(
      title: item.title,
      note: Value(item.note),
      due: item.due.millisecondsSinceEpoch,
      reminderBefore: Value(item.reminderBefore?.inMinutes),
      completed: Value(item.completed),
      createdAt: item.createdAt.millisecondsSinceEpoch,
      updatedAt: item.updatedAt.millisecondsSinceEpoch,
      status: Value(_taskStatusToInt(item.status)),
    );
    return into(tasks).insert(companion);
  }

  /// Insert a new task by providing minimal fields; helper to create TaskItem
  /// from form inputs. Returns the created TaskItem (with id string).
  Future<TaskItem> createTaskFromFields({
    required String title,
    String note = '',
    required DateTime due,
    Duration? reminderBefore,
    TaskStatus status = TaskStatus.pending,
  }) async {
    final now = DateTime.now();
    final companion = TasksCompanion.insert(
      title: title,
      note: Value(note),
      due: due.millisecondsSinceEpoch,
      reminderBefore: Value(reminderBefore?.inMinutes),
      completed: Value(status == TaskStatus.completed),
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
      status: Value(_taskStatusToInt(status)),
    );
    final int id = await into(tasks).insert(companion);
    final row = await (select(tasks)..where((t) => t.id.equals(id))).getSingle();
    return _rowToTaskItem(row);
  }

  /// Watch all tasks as a stream of TaskItem lists, sorted by due ascending.
  Stream<List<TaskItem>> watchAllTaskItems({bool sortByDue = true}) {
    final query = select(tasks);
    if (sortByDue) {
      query.orderBy([(t) => OrderingTerm(expression: t.due, mode: OrderingMode.asc)]);
    } else {
      query.orderBy([(t) => OrderingTerm(expression: t.title, mode: OrderingMode.asc)]);
    }
    return query.watch().map((rows) => rows.map(_rowToTaskItem).toList());
  }

  /// Get single TaskItem by DB integer id.
  Future<TaskItem?> getTaskItemByIntId(int id) async {
    final row = await (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _rowToTaskItem(row);
  }

  /// Get single TaskItem by TaskItem.id string (converted to int if possible).
  Future<TaskItem?> getTaskItemByStringId(String idStr) async {
    final id = int.tryParse(idStr);
    if (id == null) return null;
    return getTaskItemByIntId(id);
  }

  /// Update a task given a TaskItem. This replaces the row with matching int id.
  Future<bool> updateTaskItem(TaskItem item) async {
    final id = int.tryParse(item.id);
    if (id == null) return false;
    final updated = Task(
      id: id,
      title: item.title,
      note: item.note,
      due: item.due.millisecondsSinceEpoch,
      reminderBefore: item.reminderBefore?.inMinutes,
      completed: item.completed,
      createdAt: item.createdAt.millisecondsSinceEpoch,
      updatedAt: item.updatedAt.millisecondsSinceEpoch,
      status: _taskStatusToInt(item.status),
    );
    return update(tasks).replace(updated);
  }

  /// Delete task by integer id
  Future<int> deleteTaskByIntId(int id) => (delete(tasks)..where((t) => t.id.equals(id))).go();

  /// Delete by string id
  Future<int> deleteTaskByStringId(String idStr) {
    final id = int.tryParse(idStr);
    if (id == null) return Future.value(0);
    return deleteTaskByIntId(id);
  }

  /// Mark a task done / undone
  Future<void> setTaskCompleted(String idStr, bool done) async {
    final id = int.tryParse(idStr);
    if (id == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
      completed: Value(done),
      updatedAt: Value(now),
      status: Value(done ? 1 : 0),
    ));
  }

  // -------------------------
  // Helpers: mapping between generated row (Task) and TaskItem
  // -------------------------
  TaskItem _rowToTaskItem(Task row) {
    return TaskItem(
      id: row.id.toString(),
      title: row.title,
      note: row.note,
      due: DateTime.fromMillisecondsSinceEpoch(row.due),
      reminderBefore: row.reminderBefore == null ? null : Duration(minutes: row.reminderBefore!),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
      completed: row.completed,
      status: _intToTaskStatus(row.status),
    );
  }

  // Enum mapping helpers
  static int _taskStatusToInt(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending:
        return 0;
      case TaskStatus.completed:
        return 1;
      case TaskStatus.snoozed:
        return 2;
    }
  }

  static TaskStatus _intToTaskStatus(int val) {
    switch (val) {
      case 1:
        return TaskStatus.completed;
      case 2:
        return TaskStatus.snoozed;
      case 0:
      default:
        return TaskStatus.pending;
    }
  }
}

/// Opens the sqlite DB file in the application documents directory.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final docs = await getApplicationDocumentsDirectory();
    final file = File(p.join(docs.path, 'easycare.sqlite'));
    return NativeDatabase(file);
  });
}
