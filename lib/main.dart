// lib/main.dart
import 'package:flutter/material.dart';
import 'add_task.dart';
import 'task_item.dart';
import 'dart:math';

void main() {
  runApp(const EasyCareApp());
}

class EasyCareApp extends StatelessWidget {
  const EasyCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyCare Demo',
      theme: ThemeData(
        primaryColor: const Color(0xFF0A6CF0),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: false,
      ),
      home: const OnboardingThenHome(),
      debugShowCheckedModeBanner: false,
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
  static const double headlineSize = 22.0;
  static const double bodySize = 18.0;
  static const double smallSize = 14.0;
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

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TaskListHome()),
    );
  }

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

  Widget _buildSkipButton() => TextButton(onPressed: _goToHome, child: const Text('Skip', style: TextStyle(color: Colors.black87)));

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
                      'Say your task naturally, like "Take medication at 8 AM"',
                      'Review and edit the transcript before saving'
                    ]),
                    SimpleOnboardingPage(icon: Icons.volume_up, title: 'Listen to Your Tasks', bullets: [
                      'Tap the speaker button to hear your tasks read aloud',
                      'Adjust voice speed and volume in Settings',
                      'Get audio reminders for important tasks'
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

class SimpleOnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> bullets;
  const SimpleOnboardingPage({super.key, required this.icon, required this.title, required this.bullets});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 12),
      Semantics(label: title, child: CircleAvatar(radius: 44, backgroundColor: Colors.white, child: CircleAvatar(radius: 34, backgroundColor: _Design.surface, child: Icon(icon, size: 36, color: _Design.primary)))),
      const SizedBox(height: 26),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: _Design.headlineSize)),
      const SizedBox(height: 14),
      ...bullets.map((b) => Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.check_circle, color: _Design.accentGreen, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(b, style: const TextStyle(fontSize: _Design.bodySize, height: 1.35, color: Colors.black87))),
          ]))),
    ]);
  }
}

/* ========= Task model and demo sample data ========= */

// class TaskItem {
//   final String id;
//   final String title;
//   final String note;
//   final DateTime due;
//   final Duration? reminderBefore; // e.g., Duration(hours:1) or Duration(days:1)
//   bool completed;

//   TaskItem({
//     required this.id,
//     required this.title,
//     required this.note,
//     required this.due,
//     this.reminderBefore,
//     this.completed = false,
//   });
// }

/* Demo data */
final List<TaskItem> _demoTasks = [
  TaskItem(id: '1', title: 'Take morning medication', note: 'With breakfast - 2 pills', due: DateTime(2025, 11, 25), reminderBefore: const Duration(hours: 1)),
  TaskItem(id: '2', title: 'Call Dr. Smith for appointment', note: 'Schedule follow-up visit', due: DateTime(2025, 11, 27), reminderBefore: const Duration(days: 1)),
  TaskItem(id: '3', title: 'Buy groceries', note: 'Milk, eggs, bread', due: DateTime(2025, 11, 28), reminderBefore: const Duration(days: 3)),
];

/* ========= Task List Home page ========= */

enum SortBy { due, title }

class TaskListHome extends StatefulWidget {
  const TaskListHome({super.key});
  @override
  State<TaskListHome> createState() => _TaskListHomeState();
}

class _TaskListHomeState extends State<TaskListHome> {
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isNavigatingToAdd = false;

  SortBy _sortBy = SortBy.due;
  List<TaskItem> _tasks = List<TaskItem>.from(_demoTasks); // copy
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _applySort();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {}); // rebuild to filter
  }

  void _applySort() {
    setState(() {
      if (_sortBy == SortBy.due) {
        _tasks.sort((a, b) => a.due.compareTo(b.due));
      } else {
        _tasks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      }
    });
  }

  List<TaskItem> get _visibleTasks {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _tasks;
    return _tasks.where((t) => t.title.toLowerCase().contains(q) || t.note.toLowerCase().contains(q)).toList();
  }

  void _toggleComplete(TaskItem t) {
    setState(() {
      t.completed = !t.completed;
    });
    final msg = t.completed ? 'Marked done' : 'Marked as not done';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$msg: ${t.title}'), duration: const Duration(seconds: 1)));
  }

  Future<void> _openAddTask() async {
    if (_isNavigatingToAdd) return; // guard: already navigating
    _isNavigatingToAdd = true;
    try {
      final TaskItem? newTask = await Navigator.push<TaskItem>(
        context,
        MaterialPageRoute(builder: (_) => const AddTaskPage()),
      );

      if (newTask != null) {
        setState(() {
          _tasks.add(newTask);
          _applySort();
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task added')));
      }
    } finally {
      // ensure flag resets even if user dismisses the route with back/swipe
      if (mounted) {
        setState(() {
          _isNavigatingToAdd = false;
        });
      } else {
        _isNavigatingToAdd = false;
      }
    }
  }

  void _onSortToggle(SortBy s) {
    setState(() {
      _sortBy = s;
      _applySort();
    });
  }

  String _formatDate(DateTime d) {
    // Simple dd/Mon/yyyy format
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day.toString().padLeft(2,'0')}/${months[d.month-1]}/${d.year}';
  }

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
              child: Text('Due', style: TextStyle(color: _sortBy == SortBy.due ? Colors.white : Colors.black87)),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _onSortToggle(SortBy.title),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: _sortBy == SortBy.title ? _Design.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
              child: Text('Title', style: TextStyle(color: _sortBy == SortBy.title ? Colors.white : Colors.black87)),
            ),
          )
        ]),
      )
    ]);
  }

  Widget _buildTaskCard(TaskItem t) {
    final badgeText = _reminderLabel(t.reminderBefore);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(t.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, decoration: t.completed ? TextDecoration.lineThrough : null))),
                const SizedBox(width: 8),
                // edit icon
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit ${t.title} (demo)')));
                  },
                  icon: const Icon(Icons.edit, color: _Design.primary),
                ),
              ]),
              const SizedBox(height: 6),
              Text(t.note, style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.schedule, size: 16, color: Colors.black54),
                const SizedBox(width: 6),
                Text(_formatDate(t.due), style: const TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(width: 10),
                if (badgeText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(color: _Design.accentYellow, borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.notifications_active, size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(badgeText, style: TextStyle(fontSize: 13, color: Colors.black87)),
                    ]),
                  ),
              ])
            ]),
          )
        ]),
      ),
    );
  }

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

  Widget _buildBody() {
    final visible = _visibleTasks;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _Design.horizontalPadding),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Today's Tasks", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Read aloud (demo)'))), icon: const Icon(Icons.volume_up, color: _Design.primary), tooltip: 'Read tasks aloud'),
        ]),
        _buildSearchBar(),
        const SizedBox(height: 6),
        _buildSortControl(),
        const SizedBox(height: 12),
        const Text('To Do', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Expanded(
          child: visible.isEmpty
              ? const Center(child: Text('No tasks', style: TextStyle(fontSize: 16, color: Colors.black54)))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120, top: 4),
                  itemCount: visible.length,
                  itemBuilder: (_, i) => _buildTaskCard(visible[i]),
                ),
        )
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          if (i == 1) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open Help (demo)')));
          } else if (i == 2) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open Settings (demo)')));
          }
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ElevatedButton.icon(
          onPressed: _isNavigatingToAdd ? null : _openAddTask,
          icon: const Icon(Icons.add, size: 22),
          label: const Text('+  Add Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
