// lib/help_screen.dart
import 'package:flutter/material.dart';

// Style constants used in the HelpScreen.
const Color kPrimaryBlue = Color(0xFF0A6CF0);
const Color kSurfaceGrey = Color(0xFFF4F6F8);
const Color kBackground = Colors.white;

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scrollable Column so the content fits on small screens.
    return Container(
      color: kBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Help & Support',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Audio Tutorials section
              _SectionTitle(title: 'Audio Tutorials', subtitle: 'Tap a tutorial to hear step-by-step instructions'),
              SizedBox(height: 8),
              _TutorialCard(
                icon: Icons.mic,
                title: 'How to add a task by voice',
                subtitle: 'Learn to use voice dictation to create tasks quickly',
              ),
              SizedBox(height: 8),
              _TutorialCard(
                icon: Icons.volume_up,
                title: 'How to hear your tasks',
                subtitle: 'Listen to your tasks being read aloud',
              ),
              SizedBox(height: 8),
              _TutorialCard(
                icon: Icons.notifications_active,
                title: 'Setting up reminders',
                subtitle: 'Get notified before your tasks are due',
              ),
              SizedBox(height: 8),
              _TutorialCard(
                icon: Icons.accessibility_new,
                title: 'Accessibility settings',
                subtitle: 'Customise EasyCare to meet your needs',
              ),
              SizedBox(height: 20),

              // Quick Tips section
              _SectionTitle(title: 'Quick Tips'),
              SizedBox(height: 8),
              _TipRow(number: 1, text: 'Tap the + Add Task button to create a new task'),
              SizedBox(height: 8),
              _TipRow(number: 2, text: 'Use the speaker icon to hear all your tasks'),
              SizedBox(height: 8),
              _TipRow(number: 3, text: 'Tap the circle next to a task to mark it complete'),
              SizedBox(height: 8),
              _TipRow(number: 4, text: 'Visit Settings to make text larger or enable high contrast'),
              SizedBox(height: 20),

              // FAQ section
              _SectionTitle(title: 'Frequently Asked Questions'),
              SizedBox(height: 8),
              _FAQCard(
                question: 'How do I edit a task?',
                answer: 'Tap the pencil icon on any task card, or tap the task to view details and then tap Edit.',
              ),
              SizedBox(height: 8),
              _FAQCard(
                question: 'How do I delete a task?',
                answer: 'Open the task details or edit screen, then tap the Delete button. You will be asked to confirm.',
              ),
              SizedBox(height: 8),
              _FAQCard(
                question: 'Can I use this app without internet?',
                answer: 'Yes! EasyCare works completely offline. All your tasks are stored on your device.',
              ),
              SizedBox(height: 8),
              _FAQCard(
                question: 'Why don’t I receive notifications?',
                answer: 'Make sure notifications are enabled in Settings. You may also need to allow notifications in your device settings.',
              ),
              SizedBox(height: 20),

              // Footer
              _NeedMoreHelpFooter(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- Private / Reusable Widgets ----------

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(subtitle!, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      ],
    ]);
  }
}

class _TutorialCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TutorialCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSurfaceGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // placeholder: integrate audio playback
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Play: $title')));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              // Leading circular icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: kPrimaryBlue,
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title + subtitle
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ]),
              ),

              // Play icon
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Play: $title')));
                },
                icon: const Icon(Icons.play_circle_fill),
                color: kPrimaryBlue,
                iconSize: 28,
                tooltip: 'Play tutorial',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final int number;
  final String text;
  const _TipRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSurfaceGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // blue number circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: kPrimaryBlue, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text(number.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }
}

class _FAQCard extends StatelessWidget {
  final String question;
  final String answer;

  const _FAQCard({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSurfaceGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 12, backgroundColor: kPrimaryBlue, child: const Icon(Icons.help_outline, color: Colors.white, size: 16)),
            const SizedBox(width: 10),
            Expanded(child: Text(question, style: const TextStyle(fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 10),
          Text(answer, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ]),
      ),
    );
  }
}

class _NeedMoreHelpFooter extends StatelessWidget {
  const _NeedMoreHelpFooter();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSurfaceGrey,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(children: [
          const Text('Need More Help?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: kPrimaryBlue, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.mail_outline, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Ask a Helper', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text(
                    'If you need assistance, please ask a family member, caregiver, or friend for help with EasyCare.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          const Text('Contact: support@easycare.app', style: TextStyle(fontSize: 13, color: Colors.black54)),
        ]),
      ),
    );
  }
}
