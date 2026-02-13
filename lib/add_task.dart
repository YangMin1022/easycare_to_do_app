// lib/add_task_page.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'data/app_database.dart';
import 'services/notification_service.dart';
import 'services/speech_service.dart';
import 'utils/smart_parser.dart';
import 'task_item.dart';
/// Replace or expand with domain model / DB ID later.
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
  bool _speechEnabled = false;

  // Type mode fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  late TextEditingController _transcriptController;
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
    _initServices();
    // default due date = today at 09:00
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedTime = const TimeOfDay(hour: 9, minute: 0);
    _selectedReminder = const Duration(hours: 1);
    _transcriptController = TextEditingController(text: _transcript);

    // Check/Request permissions on load
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   NotificationService().requestPermissions(context);
    // });
  }

  /// Initialize all external services
  Future<void> _initServices() async {
    // 1. Notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().requestPermissions(context);
    });

    // 2. Speech Service
    _speechEnabled = await SpeechService().init(
      onStatus: (status) {
        // Auto-update UI state based on engine status
        if (status == 'listening') {
          setState(() => _isListening = true);
        } else if (status == 'notListening' || status == 'done') {
          setState(() => _isListening = false);
        }
      },
      onError: (errorMsg) {
        setState(() => _isListening = false);
        debugPrint('Speech Error in UI: $errorMsg');
      },
    );
    // Refresh UI to show Mic status
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _transcriptController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    SpeechService().cancel();
    super.dispose();
  }

  /// Toggle Dictation using the Service
  Future<void> _startOrStopDictation() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available.')),
      );
      return;
    }

    if (_isListening) {
      await SpeechService().stop();
      setState(() => _isListening = false);
      // --- NEW: Apply Smart Parsing when stopping ---
      _applySmartParsing(_transcript);
    } else {
      // Clear previous transcript if you want a fresh start
      // setState(() => _transcript = ''); 
      // START LISTENING
      setState(() => _isListening = true);
      await SpeechService().startListening(
        // onResult: (text) {
        //   setState(() => _transcript = text);
        // },
        onResult: (text) {
          setState(() {
            _transcript = text;
            
            // Update the controller so the text appears in the box
            _transcriptController.text = text;
            
            // OPTIONAL: Move cursor to the end so user can type immediately after
            _transcriptController.selection = TextSelection.fromPosition(
              TextPosition(offset: _transcriptController.text.length)
            );
          });
        },
      );
      setState(() => _isListening = true);
    }
  }

  /// Helper to apply parsed data to UI controllers
  void _applySmartParsing(String rawText) {
    if (rawText.trim().isEmpty) return;

    final data = SmartParser.parse(rawText);

    setState(() {
      // 1. Auto-fill Title
      _transcript = data.title; // Update the transcript view
      _titleController.text = data.title; // Also sync Type mode controller just in case

      // 2. Auto-set Date (if found)
      if (data.date != null) {
        _selectedDate = data.date;
      }

      // 3. Auto-set Time (if found)
      if (data.time != null) {
        _selectedTime = data.time;
      }
      
      // 4. Auto-set Reminder (if found)
      if (data.reminder != null) {
         _selectedReminder = data.reminder;
      }
    });

    // Optional feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Smart set: ${data.date != null ? "Date updated. " : ""}${data.time != null ? "Time updated." : ""}'),
        duration: const Duration(seconds: 1),
      )
    );
  }

  /// Save action - validate and return TaskItem
  void _onSave() async {
    if (_isSaving) return; // prevent double save
    setState(() => _isSaving = true);

    try {
      String title = '';
      String note = '';
      if (_mode == AddMode.voice) {
        if (_transcript.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a transcript or use Type mode.')));
          return;
        }
        title = _transcript.trim();
        note = _noteController.text.trim();
      } else { // AddMode.type
        // final title = _titleController.text.trim();
        if (_titleController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a task title.')));
          return;
        }
        title = _titleController.text.trim();
        note = _noteController.text.trim();
      }
      //DATE SETUP
      final due = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      //CALCULATE REMINDER LOGIC
      DateTime? reminderTime;
      int? notificationId;

      if (_selectedReminder != null) {
        reminderTime = due.subtract(_selectedReminder!);
        
        // Generate a safe 32-bit Integer ID for Android Notification System
        notificationId = Random().nextInt(100000000); 

        // Schedule it
        await NotificationService().scheduleReminder(
          id: notificationId,
          title: "Reminder: $title",
          body: "Due at ${_timeLabel()}",
          scheduledTime: reminderTime,
          payload: notificationId.toString(), // Store ID in payload for navigation later
        );
      }
      //Task Item
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final task = TaskItem(
        id: newId,
        title: title,
        note: note,
        // note: _noteController.text.trim().isEmpty ? '' : _noteController.text.trim(),
        due: due,
        reminderBefore: _selectedReminder,
        reminderTime: reminderTime,
        notificationId: notificationId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(task);
    } catch (e) {
      debugPrint("Save error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error saving task')));
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

  // Future<TimeOfDay?> _showTimePickerFallback(BuildContext context, TimeOfDay initialTime) async {
  //   final picked = await showTimePicker(context: context, initialTime: initialTime);
  //   return picked;
  // }

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

  // Future<void> _pickTime() async {
  //   // Example placeholder call to a custom time picker:
  //   // final picked = await showCustomTimePicker(context, _selectedTime);
  //   final picked = await _showTimePickerFallback(context, _selectedTime ?? const TimeOfDay(hour: 9, minute: 0));
  //   if (picked != null) {
  //     setState(() => _selectedTime = picked);
  //   }
  // }

  Future<void> _pickTime() async {
    // 1. Prepare initial DateTime based on current selection
    final now = DateTime.now();
    final initial = _selectedTime ?? const TimeOfDay(hour: 9, minute: 0);
    // CupertinoDatePicker requires a DateTime, not just TimeOfDay
    final initialDateTime = DateTime(now.year, now.month, now.day, initial.hour, initial.minute);
    
    // Variable to track changes as user spins the wheel
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
              // --- Toolbar with "Done" button ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Save the selected time
                        setState(() {
                          _selectedTime = TimeOfDay.fromDateTime(tempPickedDate);
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Done',
                        // Uses your app's Primary Color
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0A6CF0)),
                      ),
                    ),
                  ],
                ),
              ),
              // --- The Spinner Widget ---
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initialDateTime,
                  use24hFormat: false, // Sets AM/PM mode like your image
                  // This callback runs every time the wheel moves
                  onDateTimeChanged: (DateTime newDate) {
                    tempPickedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
        // Centers children vertically & horizontally
        mainAxisAlignment: MainAxisAlignment.center, 
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Large circle mic
          Semantics(
            label: 'Voice dictation',
            child: GestureDetector(
              onTap: _startOrStopDictation,
              child: CircleAvatar(
                radius: 44,
                backgroundColor: _isListening ? Colors.redAccent : (_speechEnabled ? _primary : _surface),
                child: Icon(Icons.mic, color: _isListening ? Colors.white : _primary, size: 60),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(_isListening ? 'Listening...' : (_speechEnabled ? 'Tap to speak' : 'Mic unavailable'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
              // controller: TextEditingController(text: _transcript),
              // onChanged: (v) => setState(() => _transcript = v),
              controller: _transcriptController, 
              // Update the state variable when user types manually
              onChanged: (v) => _transcript = v,
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
            const Text('Date?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
                _customReminderChip(),
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

  // 1. The Widget for the Custom Chip
  Widget _customReminderChip() {
    // Check if the current selection is one of the standard presets
    final isStandard = [
      const Duration(hours: 1),
      const Duration(days: 1),
      const Duration(days: 3),
      const Duration(days: 7)
    ].contains(_selectedReminder);

    // If it's not standard and not null, it must be custom
    final isCustomSelected = _selectedReminder != null && !isStandard;

    // Logic to show a nice label like "Custom (2h 30m)"
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
      onTap: _pickCustomReminder, // Opens the dialog
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isCustomSelected ? _primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black54),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(
              color: isCustomSelected ? Colors.white : Colors.black87, 
              fontWeight: FontWeight.w600
            )),
            if (isCustomSelected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.edit, size: 14, color: Colors.white),
            ]
          ],
        ),
      ),
    );
  }

  // 2. The Dialog Logic to pick Hours/Minutes
  Future<void> _pickCustomReminder() async {
    final hoursCtrl = TextEditingController();
    final minsCtrl = TextEditingController();

    // Pre-fill if we already have a custom value
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
                // Hours Input
                Expanded(
                  child: TextField(
                    controller: hoursCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'Hours',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Minutes Input
                Expanded(
                  child: TextField(
                    controller: minsCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'Minutes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final h = int.tryParse(hoursCtrl.text) ?? 0;
              final m = int.tryParse(minsCtrl.text) ?? 0;
              
              if (h == 0 && m == 0) {
                // If user entered 0, maybe clear reminder or do nothing
                setState(() => _selectedReminder = null);
              } else {
                setState(() {
                  _selectedReminder = Duration(hours: h, minutes: m);
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: const Text('Set'),
          ),
        ],
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
