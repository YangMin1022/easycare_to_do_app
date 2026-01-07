// lib/edit_task.dart
import 'package:flutter/material.dart';
import 'task_item.dart';

/// EditTaskScreen
/// - Accepts an existing TaskItem
/// - onSave: returns edited TaskItem
/// - onCancel: optional
/// - onDelete: optional
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
    _titleCtrl = TextEditingController(text: t.title);
    _noteCtrl = TextEditingController(text: t.note.trim().isEmpty ? '' : t.note);
    _selectedDate = DateTime(t.due.year, t.due.month, t.due.day);
    _selectedTime = TimeOfDay(hour: t.due.hour, minute: t.due.minute);
    _selectedReminder = t.reminderBefore;
    _titleCtrl.addListener(_onFieldChanged);
    _noteCtrl.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // Track whether any field changed compared with original
  bool get _hasChanges {
    final orig = widget.task;
    if (_titleCtrl.text.trim() != orig.title) return true;
    if ((_noteCtrl.text.trim()) != (orig.note.trim().isEmpty ? '' : orig.note)) return true;
    if (!_sameDate(_selectedDate, orig.due)) return true;
    if (!_sameTime(_selectedTime, orig.due)) return true;
    if ((_selectedReminder?.inSeconds ?? -1) != (orig.reminderBefore?.inSeconds ?? -1)) return true;
    return false;
  }

  void _onFieldChanged() {
    // setState only if UI needs updating (save button enabled)
    setState(() {});
  }

  static bool _sameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  static bool _sameTime(TimeOfDay t, DateTime b) => t.hour == b.hour && t.minute == b.minute;

  Future<void> _pickDate() async {
    // Replace this method to call custom date picker if available
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

  Future<void> _pickTime() async {
    // Replace this method to call custom time picker if available
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

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

  String _formatDateLabel(DateTime d) {
    final months = [
      'January','February','March','April','May','June','July','August','September','October','November','December'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  // String _formatTimeLabel(TimeOfDay t) {
  //   final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  //   final min = t.minute.toString().padLeft(2, '0');
  //   final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
  //   return '$hour:$min $ampm';
  // }

  Future<void> _onSavePressed() async {
    if (!_hasChanges || _isSaving) return;
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title.')));
      return;
    }

    setState(() => _isSaving = true);

    final newDue = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final edited = widget.task.copyWith(
      title: _titleCtrl.text.trim(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      due: newDue,
      reminderBefore: _selectedReminder,
    );

    try {
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
      if (widget.onDelete != null) widget.onDelete!();
      Navigator.of(context).pop(); // close screen after delete
    }
  }

  Widget _segmentedButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: active ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black54),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _reminderChip(String label, Duration dur) {
    final active = _selectedReminder == dur;
    return GestureDetector(
      onTap: () => _setReminder(dur),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? primary : Colors.transparent,
          border: Border.all(color: Colors.black54),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.w700)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // Title label + input (rounded box)
                      const Text('Task Title', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleCtrl,
                        decoration: InputDecoration(
                          hintText: 'Enter task title',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(width: 2)),
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),

                      const SizedBox(height: 14),

                      // Note
                      const Text('Note (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteCtrl,
                        minLines: 3,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: 'Add additional details...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(width: 2)),
                        ),
                        style: const TextStyle(fontSize: 15),
                      ),

                      const SizedBox(height: 18),

                      // When?
                      const Text('When?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _segmentedButton('Today', _sameDate(_selectedDate, DateTime.now()), _setDateToday),
                          const SizedBox(width: 8),
                          _segmentedButton('Tomorrow', _sameDate(_selectedDate, DateTime.now().add(const Duration(days: 1))), _setDateTomorrow),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _pickDate,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Pick Date...  (${_formatDateLabel(_selectedDate)})', style: const TextStyle(fontSize: 16)),
                          IconButton(
                            onPressed: _pickTime,
                            icon: const Icon(Icons.access_time),
                            tooltip: 'Pick time',
                          )
                        ]),
                      ),

                      const SizedBox(height: 18),
                      const Text('Alert Me', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _reminderChip('1 Hour', const Duration(hours: 1)),
                          _reminderChip('1 Day', const Duration(days: 1)),
                          _reminderChip('3 Days', const Duration(days: 3)),
                          _reminderChip('7 Days', const Duration(days: 7)),
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
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _isSaving ? null : _onCancelPressed,
                      child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
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