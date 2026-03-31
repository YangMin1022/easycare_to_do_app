// lib/edit_task.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'data/app_database.dart';
import 'task_item.dart';
import 'services/notification_service.dart';
import 'dart:math';

/// EditTaskScreen
class EditTaskScreen extends StatefulWidget {
  final TaskItem task;
  final Future<void> Function(TaskItem)? onSave;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;

  const EditTaskScreen({
    super.key,
    required this.task,
    this.onSave,
    this.onCancel,
    this.onDelete,
  });

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  // UI tokens
  static const Color primary = Color(0xFF0A6CF0);
  static const double horizontalPadding = 16.0;

  late TextEditingController _titleCtrl;
  late TextEditingController _noteCtrl;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  Duration? _selectedReminder;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    // Pre-fill controllers and state with the existing task data
    _titleCtrl = TextEditingController(text: t.title);
    _noteCtrl = TextEditingController(text: t.note.trim().isEmpty ? '' : t.note);
    _selectedDate = DateTime(t.due.year, t.due.month, t.due.day);
    _selectedTime = TimeOfDay(hour: t.due.hour, minute: t.due.minute);
    _selectedReminder = t.reminderBefore;
    // Attach listeners so the UI rebuilds (evaluating _hasChanges) as the user types
    // enable the Save button only when there are changes
    _titleCtrl.addListener(_onFieldChanged);
    _noteCtrl.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // Helper to check if any field has changed compared to the original task data. 
  // This is used to enable/disable the Save button and avoid unnecessary saves.
  bool get _hasChanges {
    final orig = widget.task;
    if (_titleCtrl.text.trim() != orig.title) return true;
    if ((_noteCtrl.text.trim()) != (orig.note.trim().isEmpty ? '' : orig.note)) return true;
    if (!_sameDate(_selectedDate, orig.due)) return true;
    if (!_sameTime(_selectedTime, orig.due)) return true;
    // Compare durations safely by checking total seconds
    if ((_selectedReminder?.inSeconds ?? -1) != (orig.reminderBefore?.inSeconds ?? -1)) return true;
    return false;
  }
  // This method is called whenever any of the input fields change, to trigger a UI update for the Save button state.
  void _onFieldChanged() {
    // setState only if UI needs updating (save button enabled)
    setState(() {});
  }
  // Helper to check if two DateTime objects represent the exact same calendar day/same date.
  static bool _sameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  // Helper to check if TimeOfDay matches DateTime time (ignores date & seconds)
  static bool _sameTime(TimeOfDay t, DateTime b) => t.hour == b.hour && t.minute == b.minute;

  // UI Pickers and logic for Date, Time, and Reminder selection
  // Date Picker
  Future<void> _pickDate() async {
    final initial = _selectedDate;
    final first = DateTime.now().subtract(const Duration(days: 365 * 10));
    final last = DateTime.now().add(const Duration(days: 365 * 10));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Pick a date',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  // Time Picker
  // Opens a Cupertino-style bottom sheet for selecting a TimeOfDay.
  Future<void> _pickTime() async {
    final now = DateTime.now();
    // Convert current selection to DateTime for the spinner
    final initialDateTime = DateTime(now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute);
    
    DateTime tempPickedDate = initialDateTime;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext builder) {
        return SizedBox(
          height: 280,
          child: Column(
            children: [
              // Toolbar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedTime = TimeOfDay.fromDateTime(tempPickedDate);
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Done',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: primary),
                      ),
                    ),
                  ],
                ),
              ),
              // Spinner
              Expanded(
                child: Transform.scale(
                  scale: 1.3, // Enlarge the picker for better touch targets
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: initialDateTime,
                    use24hFormat: false,
                    onDateTimeChanged: (DateTime newDate) {
                      tempPickedDate = newDate;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  // Helper methods for quick date selection (Today/Tomorrow) and reminder presets
  void _setDateToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  void _setDateTomorrow() {
    final t = DateTime.now().add(const Duration(days: 1));
    setState(() {
      _selectedDate = DateTime(t.year, t.month, t.day);
    });
  }

  void _setReminder(Duration d) {
    setState(() {
      _selectedReminder = d;
    });
  }

  //CUSTOM REMINDER LOGIC
  // When user taps "Custom" reminder chip, show a dialog to input hours and minutes for the reminder duration.
  Future<void> _pickCustomReminder() async {
    final hoursCtrl = TextEditingController();
    final minsCtrl = TextEditingController();

    if (_selectedReminder != null) {
      hoursCtrl.text = _selectedReminder!.inHours.toString();
      minsCtrl.text = (_selectedReminder!.inMinutes % 60).toString();
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Reminder Before'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How long before the due date?'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: TextField(controller: hoursCtrl, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(labelText: 'Hours', border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: minsCtrl, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(labelText: 'Minutes', border: OutlineInputBorder()))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final h = int.tryParse(hoursCtrl.text) ?? 0;
              final m = int.tryParse(minsCtrl.text) ?? 0;
              if (h == 0 && m == 0) {
                 setState(() => _selectedReminder = null);
              } else {
                 setState(() => _selectedReminder = Duration(hours: h, minutes: m));
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: primary),
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  // Formatting helpers for displaying selected date and time in the buttons
  String _formatDateLabel(DateTime d) {
    final months = [
      'January','February','March','April','May','June','July','August','September','October','November','December'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }
  // Formats TimeOfDay to a string like "2:30 PM"
  String _formatTimeLabel(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min = t.minute.toString().padLeft(2, '0');
    final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $ampm';
  }

  // Save Logic
  // When the user presses "Save", we need to:
  // 1. Validate input (e.g., title is not empty)
  Future<void> _onSavePressed() async {
    if (!_hasChanges || _isSaving) return;
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newDue = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // 2. CLEANUP PREVIOUS NOTIFICATIONS IF EXISTS
      // Crucial step: Because the due date or reminder might have changed, we must cancel 
      // the existing alarms to prevent the user from receiving "ghost" notifications.
      if (widget.task.notificationId != null) {
        await NotificationService().cancelNotification(widget.task.notificationId!);
        // Also cancel the reminder notification (base ID + 1) if it exists
        await NotificationService().cancelNotification(widget.task.notificationId! + 1);
      }

      // 3. SCHEDULE NEW NOTIFICATIONS
      // Retain the original ID to keep things clean, or generate a new one if it didn't exist
      int baseNotificationId = widget.task.notificationId ?? Random().nextInt(50000000);
      
      // Schedule the primary Due Time notification
      await NotificationService().scheduleReminder(
        id: baseNotificationId,
        title: "Task Due: ${_titleCtrl.text.trim()}",
        body: "It is time for your task!",
        scheduledTime: newDue,
        payload: baseNotificationId.toString(),
      );

      // Check if a reminder was selected and schedule the SECOND notification
      DateTime? newReminderTime;
      if (_selectedReminder != null) {
        newReminderTime = newDue.subtract(_selectedReminder!);
        int reminderNotificationId = baseNotificationId + 1;

        await NotificationService().scheduleReminder(
          id: reminderNotificationId,
          title: "Reminder: ${_titleCtrl.text.trim()}",
          body: "Due at ${_formatTimeLabel(_selectedTime)}",
          scheduledTime: newReminderTime,
          payload: reminderNotificationId.toString(),
        );
      }
      // 4. CREATE EDITED TASK
      final edited = widget.task.copyWith(
        title: _titleCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        due: newDue,
        reminderBefore: _selectedReminder,
        reminderTime: newReminderTime,
        notificationId: baseNotificationId,
      );

      // 5. CALLBACK TO SAVE CHANGES IN DB
      if (widget.onSave != null) {
        await widget.onSave!(edited);
      }
      // close screen and return edited task to caller
      if (mounted) Navigator.of(context).pop(edited);

    } catch (e) {
      if (!mounted) return;
      // show error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onCancelPressed() {
    if (widget.onCancel != null) widget.onCancel!();
    Navigator.of(context).pop();
  }
  // Prompts for confirmation, cleans up notifications, and deletes the task.
  Future<void> _onDeletePressed() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task'),
        content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (!mounted) return;
    if (confirm == true) {
      // 1. Cancel the notification before deleting
      if (widget.task.notificationId != null) {
        // Cancel the main due time notification
        await NotificationService().cancelNotification(widget.task.notificationId!);
        // Cancel the reminder notification (base ID + 1)
        await NotificationService().cancelNotification(widget.task.notificationId! + 1);
      }

      if (!mounted) return;
      
      if (widget.onDelete != null) widget.onDelete!();
      Navigator.of(context).pop(); // close screen after delete
    }
  }
  // Helper to build the segmented buttons for quick date selection (Today/Tomorrow). Highlights the active selection.
  Widget _segmentedButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48), // 48dp minimum
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black54),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }

  // Builds a chip for the predefined reminder durations (1 hour, 1 day, etc). Highlights if selected.
  Widget _reminderChip(String label, Duration dur) {
    final active = _selectedReminder == dur;
    return GestureDetector(
      onTap: () => _setReminder(dur),
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 64), // 48dp minimum
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? primary : Colors.transparent,
          border: Border.all(color: Colors.black54),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _customReminderChip() {
    final isStandard = [
      const Duration(hours: 1),
      const Duration(days: 1),
      const Duration(days: 3),
      const Duration(days: 7)
    ].contains(_selectedReminder);

    final isCustomSelected = _selectedReminder != null && !isStandard;

    String label = 'Custom';
    if (isCustomSelected) {
      final h = _selectedReminder!.inHours;
      final m = _selectedReminder!.inMinutes % 60;
      if (h > 0 && m > 0) {
        label = '${h}h ${m}m';
      } else if (h > 0) {
        label = '${h}h';
      } else {
        label = '${m}m';
      }
    }

    return GestureDetector(
      onTap: _pickCustomReminder,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48), // 48dp minimum
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isCustomSelected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black54),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(
                  color: isCustomSelected ? Colors.white : Colors.black87, 
                  fontWeight: FontWeight.w700,
                  fontSize: 15
                )),
                if (isCustomSelected) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, size: 14, color: Colors.white),
                ]
              ],
            ),
          ]
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    // The Save button should only be enabled if there are changes and we're not currently saving to prevent duplicate actions.
    final saveEnabled = _hasChanges && !_isSaving;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _onCancelPressed,
        ),
        title: const Text('Edit Task', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _onDeletePressed,
            tooltip: 'Delete task',
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      // Title label + input (rounded box) section
                      const Text('Task Title', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _titleCtrl,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          hintText: 'Enter task title',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(width: 1)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Note section
                      const Text('Note (Optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteCtrl,
                        minLines: 3,
                        maxLines: 6,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Add additional details...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(width: 1)),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Date section
                      const Text('Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _segmentedButton('Today', _sameDate(_selectedDate, DateTime.now()), _setDateToday)),
                          const SizedBox(width: 12),
                          Expanded(child: _segmentedButton('Tomorrow', _sameDate(_selectedDate, DateTime.now().add(const Duration(days: 1))), _setDateTomorrow)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _pickDate,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52), // Enforce 48dp+
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: Colors.grey),
                          ),
                          child: Text('Pick Date...  (${_formatDateLabel(_selectedDate)})', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Time section
                      const Text('Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _pickTime,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52), // Enforce 48dp+
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: Colors.grey),
                          ),
                          child: Text('Pick Time...  (${_formatTimeLabel(_selectedTime)})', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Reminder section
                      const Text('Reminder/Alert Me', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _reminderChip('1 Hour', const Duration(hours: 1)),
                          _reminderChip('1 Day', const Duration(days: 1)),
                          _reminderChip('3 Days', const Duration(days: 3)),
                          _reminderChip('7 Days', const Duration(days: 7)),
                          //custom input option
                          _customReminderChip(),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom action buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 18, left: horizontalPadding, right: horizontalPadding),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: saveEnabled ? _onSavePressed : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          disabledBackgroundColor: Colors.grey.shade200,
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: saveEnabled ? Colors.white : Colors.grey.shade600)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: _isSaving ? null : _onCancelPressed,
                        child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontSize: 16)),
                      )
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}