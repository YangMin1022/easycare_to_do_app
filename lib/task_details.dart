import 'package:flutter/material.dart';
import 'data/app_database.dart';
import 'task_item.dart';
import 'edit_task.dart';
import 'services/notification_service.dart';

/// Reusable Task details screen widget.
class TaskDetailsScreen extends StatelessWidget {
  final TaskItem task;
  // Callbacks to notify the parent screen of user actions
  final void Function(TaskItem)? onMarkDone;
  final void Function(TaskItem)? onEdit;
  final void Function(TaskItem)? onDelete;

  const TaskDetailsScreen({
    super.key,
    required this.task,
    this.onMarkDone,
    this.onEdit,
    this.onDelete,
  });

  static const Color _primary = Color(0xFF0A6CF0);

  // Converts a [Duration] object into a human-readable string for the UI.
  String formatDuration(Duration? duration) {
    if (duration == null) return 'No reminder';

      if (duration.inDays > 0) {
        return '${duration.inDays} day(s) before';
      } else if (duration.inHours > 0) {
        return '${duration.inHours} hour(s) before';
      } else if (duration.inMinutes > 0) {
        return '${duration.inMinutes} minute(s) before';
      } else {
        return 'Just before';
      }
    }

  // Helper function to format a DateTime into a long date string (e.g. "Friday, November 7, 2025").
  String _formatDateLong(DateTime dt) {
    // e.g. Friday, November 7, 2025
    const months = [
      'January','February','March','April','May','June','July','August','September','October','November','December'
    ];
    const weekdays = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
    final w = weekdays[dt.weekday % 7];
    final m = months[dt.month - 1];
    return '$w, $m ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }

  // Helper function to format a DateTime into a 12-hour time string (e.g. "2:30 PM").
  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$min $ampm';
  }

  // Helper widget to create a section label with an icon and text.
  Widget _sectionLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: _primary, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // Helper widget to create a styled info box for displaying task details like notes, due date, etc.
  Widget _infoBox(Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get the safe area insets for proper padding of the bottom buttons.
    final safe = MediaQuery.of(context).padding;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Task Details', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // SCROLLABLE CONTENT AREA
              // Using Expanded allows the content to scroll freely while pushing 
              // the action buttons to the absolute bottom of the screen.
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // Status badge - centered
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: _primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                task.status == TaskStatus.pending ? 'Pending' : (task.status == TaskStatus.completed ? 'Completed' : 'Snoozed'),
                                style: const TextStyle(color: _primary, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Task label & title
                      _sectionLabel(Icons.description, 'Task'),
                      const SizedBox(height: 8),
                      Text(task.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 18),

                      // Note
                      _sectionLabel(Icons.note_alt, 'Note'),
                      _infoBox(
                        Text(
                          task.note.isEmpty ? 'No additional notes.' : task.note,
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),

                      // Due Date
                      _sectionLabel(Icons.calendar_today, 'Due Date'),
                      _infoBox(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatDateLong(task.due), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(_formatTime(task.due), style: const TextStyle(fontSize: 14, color: Colors.black54)),
                          ],
                        ),
                      ),

                      // Reminder
                      _sectionLabel(Icons.notifications_active, 'Reminder'),
                      _infoBox(
                        Text(formatDuration(task.reminderBefore), style: const TextStyle(fontSize: 16)),
                      ),

                      // Created / updated metadata (Audit trail for when tasks were created/edited)
                      _infoBox(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Created: ${_formatDateLong(task.createdAt)} ${_formatTime(task.createdAt)}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            const SizedBox(height: 6),
                            Text('Last updated: ${_formatDateLong(task.updatedAt)} ${_formatTime(task.updatedAt)}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Bottom action buttons
              Padding(
                // Add extra bottom padding to account for devices with gesture navigation bars or notches.
                padding: EdgeInsets.fromLTRB(0, 8, 0, safe.bottom + 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hide Mark as Done and Edit if task is completed
                    if (!task.completed) ...[
                      // Primary: Mark as Done button
                      ElevatedButton.icon(
                        onPressed: () {
                          if (onMarkDone != null) onMarkDone!(task);
                          // default behaviour: show a confirmation
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as done')));
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text('Mark as Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Secondary: Edit button
                      OutlinedButton.icon(
                        onPressed: () {
                          if (onEdit != null) {
                            onEdit!(task);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit (not implemented)')));
                          }
                        },
                        icon: const Icon(Icons.edit, color: Colors.black87, size: 20),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text('Edit Task', style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w700)),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Danger: Delete button
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Capture Navigator and ScaffoldMessenger BEFORE the async gap.
                        // This prevents crashes if the context is disposed while the dialog is open
                        final NavigatorState navigator = Navigator.of(context);

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Task'),
                            content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          // Cancel any pending notifications for this task to prevent ghost notifications after deletion
                          if (task.notificationId != null) {
                            // Cancel the main due time notification
                            await NotificationService().cancelNotification(task.notificationId!);
                            // Cancel the reminder notification (base ID + 1)
                            await NotificationService().cancelNotification(task.notificationId! + 1);
                          }
                          // Notify parent to execute DB deletion and pop back to the previous screen
                          if (onDelete != null) onDelete!(task);
                          navigator.maybePop();
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Delete Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
