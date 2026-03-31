// lib/main.dart
import 'package:flutter/material.dart';
import 'data/app_database.dart';
import 'add_task.dart';
import 'task_item.dart';
import 'task_details.dart';
import 'edit_task.dart';
import 'help_screen.dart';
import 'settings.dart';
import 'services/tts_service.dart';
import 'services/tts_helpers.dart';
import 'services/settings_service.dart';
import 'package:timezone/data/latest.dart' as tz; // Initialize timezone data
import 'package:timezone/timezone.dart' as tzi;
import 'services/notification_service.dart';
import 'dart:math';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize timezone package (critical for accurate local notifications)
  tz.initializeTimeZones();
  // Initialize Notifications
  await NotificationService().init();
  await SettingsService().init();
  runApp(const EasyCareApp());
}

class EasyCareApp extends StatelessWidget {
  const EasyCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to changes in the global font size setting
    return ValueListenableBuilder<FontSizeOption>(
      valueListenable: SettingsService().fontSizeNotifier,
      builder: (context, fontSize, child) {
        return MaterialApp(
          title: 'EasyCare Demo',
          theme: ThemeData(
            primaryColor: const Color(0xFF0A6CF0),
            scaffoldBackgroundColor: Colors.white,
            useMaterial3: false,
          ),
          // Apply the text scale(font size) globally to every screen based on the user's selection in Settings
          // Wrap the entire app in a MediaQuery to globally override the text scale(font size).
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(SettingsService().textScaleFactor),
              ),
              child: child!,
            );
          },
          home: const OnboardingThenHome(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

/* ========= Shared design constants ========= */

class _Design {
  static const Color primary = Color(0xFF0A6CF0);
  static const Color accentYellow = Color(0xFFFFF1D9); // light for badge background
  static const Color accentGreen = Color(0xFF16A34A);
  static const Color surface = Color(0xFFF4F6F8);
  static const double horizontalPadding = 16.0;
  static const double headlineSize = 24.0;
  static const double headlineSizeSmall = 22.0;
  static const double bodySize = 22.0;
  static const double smallSize = 20.0;
  static const double actionHeight = 56.0;
}

/* ========= Simple onboarding (PageView) ========= */

class OnboardingThenHome extends StatefulWidget {
  const OnboardingThenHome({super.key});
  @override
  State<OnboardingThenHome> createState() => _OnboardingThenHomeState();
}

class _OnboardingThenHomeState extends State<OnboardingThenHome> {
  final PageController _controller = PageController();
  int _pageIndex = 0;

  /// Skips onboarding and navigates to the Home screen
  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TaskListHome()),
    );
  }

  /// Advances to the next onboarding page, or finishes if at the end
  void _nextPage() {
    final next = _pageIndex + 1;
    if (next < 2) {
      _controller.animateToPage(next, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _goToHome();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildSkipButton() => TextButton(onPressed: _goToHome, 
  style: TextButton.styleFrom(
  // Increases the touch area size
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  child: const Text('Skip', style: TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.w500)));

  /// Builds the dot indicators at the bottom of the onboarding screen
  Widget _buildPageIndicator() {
    Widget dot(bool active) => Container(
          width: active ? 18 : 10,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(color: active ? _Design.primary : Colors.grey.shade300, borderRadius: BorderRadius.circular(6)),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [dot(_pageIndex == 0), dot(_pageIndex == 1)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: Colors.white, actions: [_buildSkipButton()]),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _Design.horizontalPadding),
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _pageIndex = i),
                  children: const [
                    SimpleOnboardingPage(icon: Icons.mic, title: 'Add Tasks by Voice', bullets: [
                      'Tap the microphone button to start speaking',
                      'Say your task naturally, like "Take medication at 8 AM on June 26. Remind me 2 hours before."',
                      'Review and edit the transcript before saving'
                    ]),
                    SimpleOnboardingPage(icon: Icons.volume_up, title: 'Listen to Your Tasks', bullets: [
                      'Tap the speaker button to hear your tasks read aloud',
                      'Adjust voice speed and volume in Settings'
                    ]),
                  ],
                ),
              ),
              Column(children: [
                _buildPageIndicator(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: _Design.actionHeight,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(backgroundColor: _Design.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(_pageIndex == 0 ? 'Next' : "Let's Get Started", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),
              ])
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}

/// Reusable layout for individual onboarding pages
class SimpleOnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> bullets;
  const SimpleOnboardingPage({super.key, required this.icon, required this.title, required this.bullets});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        Semantics(label: title, child: CircleAvatar(radius: 60, backgroundColor: Colors.white, child: CircleAvatar(radius: 50, backgroundColor: _Design.surface, child: Icon(icon, size: 60, color: _Design.primary)))),
        const SizedBox(height: 26),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: _Design.headlineSize)),
        const SizedBox(height: 14),
        ...bullets.map((b) => Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.check_circle, color: _Design.accentGreen, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Text(b, style: const TextStyle(fontSize: _Design.headlineSizeSmall, height: 1.35, color: Colors.black87))),
            ]))),
    ]);
  }
}


/* ========= Task List Home page ========= */

enum SortBy { due, title }

/// Home screen displaying the user's tasks.
class TaskListHome extends StatefulWidget {
  const TaskListHome({super.key});
  @override
  State<TaskListHome> createState() => _TaskListHomeState();
}

class _TaskListHomeState extends State<TaskListHome> {
  final TextEditingController _searchCtrl = TextEditingController();
  final AppDatabase _db = AppDatabase();
  
  bool _isNavigatingToAdd = false;
  SortBy _sortBy = SortBy.due;
  int _navIndex = 0; // Tracks bottom navigation state

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    // Trigger the background cleanup as soon as the screen loads
    _runStartupTasks();
  }

  /// Performs notification cleanup operations on app launch
  Future<void> _runStartupTasks() async {
    try {
      // Fetch the current snapshot of all tasks from the database stream
      final allTasks = await _db.watchAllTaskItems().first;
      
      // Pass them to our new NotificationService cleanup method
      // Clean up orphaned or outdated OS notifications
      await NotificationService().cleanUpOutdatedNotifications(allTasks);
    } catch (e) {
      debugPrint('Failed to clean up notifications on startup: $e');
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {}); // Rebuild UI to apply search filter
  }

  /// Filters tasks locally based on the search input
  List<TaskItem> _filterTasks(List<TaskItem> tasks) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return tasks;
    return tasks.where((t) => t.title.toLowerCase().contains(q) || t.note.toLowerCase().contains(q)).toList();
  }

  /// Toggles the completion status of a task and updates the database
  void _toggleComplete(TaskItem t) async {
    // Optimistic update handled by Stream, but we call DB here
    await _db.setTaskCompleted(t.id, !t.completed);
    
    final msg = !t.completed ? 'Marked done' : 'Marked as not done'; // Logic flipped because we just toggled it
    if(mounted) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$msg: ${t.title}'), duration: const Duration(seconds: 1)));
    }
  }

  /// Navigates to Add Task Page and handles the returned new task
  Future<void> _openAddTask() async {
    if (_isNavigatingToAdd) return; // guard: already navigating/prevent double taps
    _isNavigatingToAdd = true;
    try {
      final TaskItem? newTask = await Navigator.push<TaskItem>(
        context,
        MaterialPageRoute(builder: (_) => const AddTaskPage()),
      );

      if (!mounted) return;
      
      if (newTask != null) {
        // Insert into DB. The DB automatically generates the real unique ID.
        await _db.insertTaskItem(newTask);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task added')));
      }
    } finally {
      // ensure navigation guard resets even if user dismisses the route with back/swipe
      if (mounted) {
        setState(() {
          _isNavigatingToAdd = false;
        });
      } else {
        _isNavigatingToAdd = false;
      }
    }
  }

  /// Navigates to Edit Task Page and handles DB updates
  Future<void> _openEditTask(TaskItem t) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTaskScreen(
          task: t,
          // 1. Handle Saving: Replace the old task with the edited one
          onSave: (editedTask) async {
            await _db.updateTaskItem(editedTask);
            if(mounted){
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task updated successfully')),);
            }
          },
          // 2. Handle Deleting (Optional, since Edit screen has a delete button)
          onDelete: () async{
            await _db.deleteTaskByStringId(t.id);
            if(mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task deleted')),);
            }
          },
        ),
      ),
    );
  }

  // Open Task Details page with callbacks for actions that can be triggered from there (mark done, delete, edit)
  void _openTaskDetails(TaskItem t) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailsScreen(
          task: t,
          // Handle 'Mark Done' from the details page
          onMarkDone: (task) {
             _toggleComplete(task);
             Navigator.pop(context); // close details page after action
          },
          // Handle 'Delete' from the details page
          onDelete: (task) async {
            await _db.deleteTaskByStringId(task.id);
            if(mounted) {
                // Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted ${task.title}'))
                );
            }
          },
          // Handle 'Edit' (Placeholder)
          onEdit: (task) {
            // Step A: Close the Details screen first
            Navigator.pop(context);
            
            // Step B: Open the Edit screen immediately
            _openEditTask(task);
          },
        ),
      ),
    );
    // When coming back, ensure UI updates (in case changes happened without popping)
    setState(() {});
  }

  void _onSortToggle(SortBy s) {
    setState(() {
      _sortBy = s;
    });
  }

  /// Helper to format Dates nicely for UI list
  String _formatDate(DateTime d) {
    // Simple dd/Mon/yyyy format
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day.toString().padLeft(2,'0')}/${months[d.month-1]}/${d.year}';
  }

  /// Helper to format Durations into readable text (e.g., "2 hours")
  String _reminderLabel(Duration? dur) {
    if (dur == null) return '';
    if (dur.inDays >= 1) {
      final days = dur.inDays;
      return '$days days';
    } else {
      final hours = dur.inHours;
      return '$hours hours';
    }
  }

  /// Builds the toggle controls for sorting tasks
  Widget _buildSortControl() {
    return Row(children: [
      const Icon(Icons.tune, size: 20, color: Colors.black54),
      const SizedBox(width: 8),
      const Text('Sort by:', style: TextStyle(fontSize: _Design.smallSize, color: Colors.black87)),
      const SizedBox(width: 8),
      // Two options look like segmented control
      Container(
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(4),
        child: Row(children: [
          GestureDetector(
            onTap: () => _onSortToggle(SortBy.due),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: _sortBy == SortBy.due ? _Design.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
              child: Text('Due', style: TextStyle(color: _sortBy == SortBy.due ? Colors.white : Colors.black87, fontSize: _Design.smallSize)),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _onSortToggle(SortBy.title),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: _sortBy == SortBy.title ? _Design.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
              child: Text('Title', style: TextStyle(color: _sortBy == SortBy.title ? Colors.white : Colors.black87, fontSize: _Design.smallSize)),
            ),
          )
        ]),
      )
    ]);
  }

  /// Builds the individual Card widget for a TaskItem in the list
  Widget _buildTaskCard(TaskItem t) {
    String badgeText = '';
    // Prioritize showing absolute reminder time if available
    if (t.reminderTime != null) {
      // Format it nicely: "22/1 14:30"
      final dt = t.reminderTime!;
      final dateStr = '${dt.day}/${dt.month}';
      final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final timeStr = '$hour12:$minute $period';
      badgeText = '$dateStr $timeStr'; 
    } 
    else if (t.reminderBefore != null) {
      // Fallback: If for some reason time is null but duration isn't
      badgeText = _reminderLabel(t.reminderBefore);
    }
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias, // Required for InkWell ripple effect
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        // === TRIGGER NAVIGATION HERE ===
        onTap: () => _openTaskDetails(t),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // large circle checkbox
            GestureDetector(
              onTap: () => _toggleComplete(t),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade400, width: 2), color: t.completed ? _Design.primary : Colors.white),
                child: t.completed ? const Icon(Icons.check, color: Colors.white) : null,
              ),
            ),
            const SizedBox(width: 12),
            // main content
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Text(t.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, decoration: t.completed ? TextDecoration.lineThrough : null))),
                    const SizedBox(width: 8),
                    // edit icon in the card
                    IconButton(
                      onPressed: () => _openEditTask(t),
                      icon: const Icon(Icons.edit, color: _Design.primary),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(t.note, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 10),
                  // Bottom Row: Date & Reminder Badge
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10.0,    // Horizontal gap between the date and the badge
                    runSpacing: 8.0,  // Vertical gap if the badge wraps to the next line
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        Icon(Icons.schedule, size: 16, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text(_formatDate(t.due), style: const TextStyle(fontSize: 15, color: Colors.black54)),
                        ]
                      ),
                      // const SizedBox(width: 10),
                      if (badgeText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(color: _Design.accentYellow, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            const Icon(Icons.notifications_active, size: 16, color: Colors.orange),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                badgeText, 
                                style: const TextStyle(fontSize: 15, color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]
                        ),
                      ),
                    ]
                  )
                ]
              ),
            )
          ]),
        ),
      ),
    );
  }

  /// Builds the text input for local search filtering
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12), color: Colors.white),
      child: Row(children: [
        const Icon(Icons.search, color: Colors.black45),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(border: InputBorder.none, hintText: 'Search tasks or tap + to add'),
            style: const TextStyle(fontSize: _Design.bodySize),
            textInputAction: TextInputAction.search,
          ),
        ),
      ]),
    );
  }

  /// Main body builder for the TaskListHome screen
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _Design.horizontalPadding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 40),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Today's Tasks", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          // Text-to-Speech Control Button
          ValueListenableBuilder<bool>(
            valueListenable: TtsService().isSpeakingNotifier,
            builder: (context, isSpeaking, child) {
              return IconButton(
                iconSize: 36,
                onPressed: () async {
                  // If currently speaking, this will STOP it.
                  // If stopped, this will START it.
                  if (isSpeaking) {
                    // Logic to STOP
                    await TtsService().stop();

                    // Check mounted before using context after async gap
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reading stopped.')),);
                  } else {
                    // Logic to START - Fetch tasks from DB explicitly for reading, ensuring we get the latest data and sorting based on current UI state
                    final allTasks = await _db.watchAllTaskItems(sortByDue: _sortBy == SortBy.due).first;

                    // Check mounted before using context after async gap
                    if (!context.mounted) return;

                    final tasksToRead = _filterTasks(allTasks);

                    if (tasksToRead.isEmpty) {
                      await TtsService().speak("You have no tasks today.");
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reading tasks... Tap stop to cancel.')),);
                      // This helper now handles the looping and stopping check
                      await readAllTasks(tasksToRead);
                    }
                  }
                },
                // CHANGE Text-To-Speech ICON BASED ON STATE
                icon: Icon(
                  isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up, 
                  color: isSpeaking ? Colors.red : _Design.primary, // Make stop button red
                  // size: isSpeaking ? 28 : 24,
                ),
                tooltip: isSpeaking ? 'Stop reading' : 'Read tasks aloud',
              );
            },
          ),
        ]),
        // Debugging Action (Hidden utility for devs)
        IconButton(
          icon: const Icon(Icons.bug_report),
          tooltip: 'Debug notifications',
          onPressed: () async {
            await NotificationService().debugPending();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked pending notifications — see log.')));
          }
        ),

        _buildSearchBar(),
        const SizedBox(height: 12),
        _buildSortControl(),
        const SizedBox(height: 14),
        const Text('To Do', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        // Task List renders here, wrapped in StreamBuilder to listen to DB changes
        Expanded(
          child: StreamBuilder<List<TaskItem>>(
            // Listen to the database stream. It handles sorting by due/title internally based on the arg.
            stream: _db.watchAllTaskItems(sortByDue: _sortBy == SortBy.due),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              final allTasks = snapshot.data ?? [];
              final visible = _filterTasks(allTasks); // Apply search filter

              final pendingTasks = visible.where((t) => !t.completed).toList();
              final completedTasks = visible.where((t) => t.completed).toList();

              if (pendingTasks.isEmpty && completedTasks.isEmpty) {
                return const Center(child: Text('No tasks', style: TextStyle(fontSize: 16, color: Colors.black54)));
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 120, top: 4),
                // +1 for the "Completed" header text if we have completed tasks
                itemCount: pendingTasks.length + (completedTasks.isNotEmpty ? 1 + completedTasks.length : 0),
                itemBuilder: (_, index) {
                  // 1. Render Pending Tasks
                  if (index < pendingTasks.length) {
                    return _buildTaskCard(pendingTasks[index]);
                  }
                  
                  // 2. Render the "Completed" Header
                  int completedIndex = index - pendingTasks.length;
                  if (completedIndex == 0) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 24, bottom: 8),
                      child: Text('Completed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black54)),
                    );
                  }
                  
                  // 3. Render Completed Tasks
                  return _buildTaskCard(completedTasks[completedIndex - 1]);
                },
              );
            },
          ),
        )
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Swap out the main view based on bottom nav selection
      body: _navIndex == 0 ? _buildBody() : _navIndex == 1 ? const HelpScreen() : _navIndex == 2 ? const SettingsScreen() : Container(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: 'Help'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        selectedItemColor: _Design.primary,
        unselectedItemColor: Colors.black54,
        showUnselectedLabels: true,
      ),
      // Large "Add Task" centrally placed above bottom navigation
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _navIndex != 0 
        ? null // Hide FAB on Help and Settings screens
        : Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: ElevatedButton.icon(
            onPressed: _isNavigatingToAdd ? null : _openAddTask,
            icon: const Icon(Icons.add, size: 22),
            label: const Text(' Add Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _Design.primary,
              minimumSize: const Size(180, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 6,
            ),
          ),
        ),
    );
  }
}
