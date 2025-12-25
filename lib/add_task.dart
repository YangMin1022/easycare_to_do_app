// lib/add_task_page.dart
import 'package:flutter/material.dart';
import 'task_item.dart';
/// Replace or expand with domain model / DB ID later.
// class TaskItem {
//   final String title;
//   final String? note;
//   final DateTime dueDateTime;
//   final Duration? reminderBefore; // e.g., Duration(hours:1) or Duration(days:1)

//   TaskItem({
//     required this.title,
//     this.note,
//     required this.dueDateTime,
//     this.reminderBefore,
//   });
// }

/// AddTaskPage - supports Voice and Type modes.
/// Usage:
/// Navigator.push`TaskItem`(context, MaterialPageRoute(builder: (_) => AddTaskPage()))
/// The pushed Future completes with TaskItem when Save pressed, or null if Cancelled.
class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

enum AddMode { voice, type }

class _AddTaskPageState extends State<AddTaskPage> {

  bool _isSaving = false;
  bool _isCancelling = false;

  AddMode _mode = AddMode.voice;

  // Voice mode
  String _transcript = '';
  bool _isListening = false;

  // Type mode fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Duration? _selectedReminder; // e.g., Duration(hours:1)

  // UI design constants
  static const Color _primary = Color(0xFF0A6CF0);
  static const Color _surface = Color(0xFFF4F6F8);
  static const Color _badgeBg = Color(0xFFFFF1D9);

  @override
  void initState() {
    super.initState();
    // default due date = today at 09:00
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedTime = const TimeOfDay(hour: 9, minute: 0);
    _selectedReminder = const Duration(hours: 1);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Placeholder: integrate with speech_to_text or platform dictation here.
  Future<void> _startOrStopDictation() async {
    setState(() {
      _isListening = !_isListening;
    });

    if (_isListening) {
      // Start speech capture. Replace with actual speech plugin start.
      // Example with speech_to_text:
      // await _speech.listen(onResult: (r) => setState(()=>_transcript=r.recognizedWords));
      // For now we simulate:
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _transcript = 'Take medication at 8 AM';
      });
    } else {
      // Stop speech capture. Replace with plugin stop.
      // await _speech.stop();
    }
  }

  /// Save action - validate and return TaskItem
  void _onSave() async {
    if (_isSaving) return; // prevent double save
    setState(() => _isSaving = true);

    try {
      if (_mode == AddMode.voice) {
        if (_transcript.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a transcript or use Type mode.')));
          return;
        }
        final due = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
        final newId = DateTime.now().millisecondsSinceEpoch.toString();
        final task = TaskItem(id: newId,title: _transcript.trim(), note: _noteController.text.trim(), due: due, reminderBefore: _selectedReminder);
        if (!mounted) return;
        Navigator.of(context).pop(task);
      } else {
        final title = _titleController.text.trim();
        if (title.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a task title.')));
          return;
        }
        final due = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
        final newId = DateTime.now().millisecondsSinceEpoch.toString();
        final task = TaskItem(
          id: newId,
          title: title,
          note: _noteController.text.trim().isEmpty ? '' : _noteController.text.trim(),
          due: due,
          reminderBefore: _selectedReminder,
        );
        if (!mounted) return;
        Navigator.of(context).pop(task);
      }
    } finally {
      // We leave the page after pop; but reset flag if user didn't pop
      if (mounted) {
        setState(() => _isSaving = false);
      } else {
        _isSaving = false;
      }
    }
  }

  void _onCancel() {
    if (_isCancelling) return;
    _isCancelling = true;
    // safe pop
    if (mounted) {
      Navigator.of(context).pop(null);
      // reset flag if still mounted (not strictly necessary since page is popped)
      setState(() => _isCancelling = false);
    } else {
      _isCancelling = false;
    }
  }

  // Built-in fallback pickers. Replace calls to these functions with custom pickers
  Future<DateTime?> _showDatePickerFallback(BuildContext context, DateTime initialDate) async {
    final first = DateTime.now().subtract(const Duration(days: 365));
    final last = DateTime.now().add(const Duration(days: 365 * 2));
    final picked = await showDatePicker(context: context, initialDate: initialDate, firstDate: first, lastDate: last);
    return picked;
  }

  Future<TimeOfDay?> _showTimePickerFallback(BuildContext context, TimeOfDay initialTime) async {
    final picked = await showTimePicker(context: context, initialTime: initialTime);
    return picked;
  }

  /// Wrapper that tries to call custom picker; otherwise fallback.
  /// Replace the body to call custom pickers.
  Future<void> _pickDate() async {
    // Example placeholder call to a custom picker:
    // final picked = await showCustomDatePicker(context, _selectedDate);
    // if (picked == null) return;
    final picked = await _showDatePickerFallback(context, _selectedDate ?? DateTime.now());
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    // Example placeholder call to a custom time picker:
    // final picked = await showCustomTimePicker(context, _selectedTime);
    final picked = await _showTimePickerFallback(context, _selectedTime ?? const TimeOfDay(hour: 9, minute: 0));
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  // Helper to format display of date/time
  String _dateLabel() {
    final d = _selectedDate!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _timeLabel() {
    final t = _selectedTime!;
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${t.minute.toString().padLeft(2, '0')} $suffix';
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeButton(AddMode.voice, Icons.mic, 'Voice'),
          _modeButton(AddMode.type, Icons.keyboard_alt, 'Type'),
        ],
      ),
    );
  }

  Widget _modeButton(AddMode mode, IconData icon, String label) {
    final active = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: active ? _primary : Colors.transparent, borderRadius: BorderRadius.circular(26)),
        child: Row(
          children: [
            Icon(icon, color: active ? Colors.white : Colors.black54),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: active ? FontWeight.w700 : FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _voiceView() {
    return Expanded(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Large circle mic
          Semantics(
            label: 'Voice dictation',
            child: GestureDetector(
              onTap: _startOrStopDictation,
              child: CircleAvatar(
                radius: 44,
                backgroundColor: _isListening ? _primary : _surface,
                child: Icon(Icons.mic, color: _isListening ? Colors.white : _primary, size: 36),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(_isListening ? 'Listening...' : 'Tap to speak', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Tap the microphone and speak your task',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Show transcript editor for confirmation (editable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: TextField(
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Transcript will appear here. Edit if necessary before saving.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
              controller: TextEditingController(text: _transcript),
              onChanged: (v) => setState(() => _transcript = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeView() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            const Text('Task Title', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g., Take medication at 8 AM',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                // reveal note textfield focus
                // no-op; the text field below is visible
              },
              child: TextButton(
                onPressed: () => FocusScope.of(context).requestFocus(FocusNode()),
                child: const Text('+ Add a Note (Optional)', style: TextStyle(color: _primary, fontWeight: FontWeight.w600)),
              ),
            ),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Notes or details (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 18),
            const Text('When?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                _dateOptionButton('Today', () {
                  final now = DateTime.now();
                  setState(() {
                    _selectedDate = DateTime(now.year, now.month, now.day);
                  });
                }, selected: DateTime.now().difference(_selectedDate!).inDays == 0),
                const SizedBox(width: 8),
                _dateOptionButton('Tomorrow', () {
                  final tomorrow = DateTime.now().add(const Duration(days: 1));
                  setState(() {
                    _selectedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
                  });
                }, selected: DateTime.now().add(const Duration(days: 1)).difference(_selectedDate!).inDays == 0),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _pickDate,
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Pick Date...  (${_dateLabel()})', style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _pickTime,
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Pick Time...  (${_timeLabel()})', style: const TextStyle(fontSize: 16)),
              ),
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
                // Add custom input option if needed
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateOptionButton(String label, VoidCallback onTap, {required bool selected}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: selected ? _primary : Colors.transparent, borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.black54)),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _reminderChip(String label, Duration dur) {
    final isSelected = _selectedReminder == dur;
    return GestureDetector(
      onTap: () => setState(() => _selectedReminder = dur),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? _primary : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black54)),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaveEnabled = ((_mode == AddMode.voice && _transcript.trim().isNotEmpty) || (_mode == AddMode.type && _titleController.text.trim().isNotEmpty)) && !_isSaving;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: _onCancel),
        title: const Text('Add Task', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildModeToggle(),
            // main content area
            if (_mode == AddMode.voice) _voiceView() else _typeView(),

            // Bottom action buttons: Save and Cancel
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSaveEnabled ? _onSave : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      disabledBackgroundColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Save Task', style: TextStyle(fontSize: 16, color: isSaveEnabled ? Colors.white : Colors.grey.shade600)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: _isSaving ? null : _onCancel, child: const Text('Cancel', style: TextStyle(color: Colors.black54))),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
