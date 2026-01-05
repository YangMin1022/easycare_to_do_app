// lib/settings.dart
import 'package:flutter/material.dart';

const Color kPrimaryBlue = Color(0xFF0A6CF0);
const Color kSurfaceGrey = Color(0xFFF4F6F8);
const Color kBackground = Colors.white;

enum FontSizeOption { small, medium, large }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // local interactive state
  FontSizeOption _fontSize = FontSizeOption.medium;
  double _ttsSpeed = 1.2; // multiplier 0.5x - 2.0x
  double _ttsVolume = 50.0; // percent
  bool _notificationsEnabled = true;

  // helper getters
  double get _fontPreviewSize {
    switch (_fontSize) {
      case FontSizeOption.small:
        return 14.0;
      case FontSizeOption.medium:
        return 18.0;
      case FontSizeOption.large:
        return 22.0;
    }
  }

  String get _fontLabel {
    switch (_fontSize) {
      case FontSizeOption.small:
        return 'Small';
      case FontSizeOption.medium:
        return 'Medium';
      case FontSizeOption.large:
        return 'Large';
    }
  }

  void _setFontSize(FontSizeOption opt) {
    setState(() => _fontSize = opt);
  }

  void _sendTestNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test notification (demo)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackground,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: kBackground,
          appBar: AppBar(
            backgroundColor: kBackground,
            elevation: 0.6,
            centerTitle: true,
            title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
            iconTheme: const IconThemeData(color: Colors.black87),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Accessibility section
                const _SectionTitle(title: 'Accessibility', subtitle: null),
                const SizedBox(height: 8),
                const Text('Font Size', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SegmentedOption(
                      label: 'Small',
                      selected: _fontSize == FontSizeOption.small,
                      onTap: () => _setFontSize(FontSizeOption.small),
                    ),
                    const SizedBox(width: 8),
                    _SegmentedOption(
                      label: 'Medium',
                      selected: _fontSize == FontSizeOption.medium,
                      onTap: () => _setFontSize(FontSizeOption.medium),
                    ),
                    const SizedBox(width: 8),
                    _SegmentedOption(
                      label: 'Large',
                      selected: _fontSize == FontSizeOption.large,
                      onTap: () => _setFontSize(FontSizeOption.large),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  color: kSurfaceGrey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Sample text preview',
                      style: TextStyle(fontSize: _fontPreviewSize),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Text-to-Speech section
                const _SectionTitle(title: 'Text-to-Speech', subtitle: null),
                const SizedBox(height: 8),
                const Text('Voice Speed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _LabeledSlider(
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  value: _ttsSpeed,
                  onChanged: (v) => setState(() => _ttsSpeed = double.parse(v.toStringAsFixed(2))),
                  leftLabel: 'Slow',
                  rightLabel: 'Fast',
                  valueLabel: '${_ttsSpeed.toStringAsFixed(1)}x',
                ),
                const SizedBox(height: 12),
                const Text('Voice Volume', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _LabeledSlider(
                  min: 0,
                  max: 100,
                  divisions: 100,
                  value: _ttsVolume,
                  onChanged: (v) => setState(() => _ttsVolume = v.roundToDouble()),
                  leftLabel: 'Quiet',
                  rightLabel: 'Loud',
                  valueLabel: '${_ttsVolume.round()}%',
                ),

                const SizedBox(height: 20),

                // Notifications section
                const _SectionTitle(title: 'Notifications', subtitle: null),
                const SizedBox(height: 8),
                Card(
                  color: kSurfaceGrey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_none, color: kPrimaryBlue),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Enable Notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                        Switch.adaptive(
                          value: _notificationsEnabled,
                          activeColor: kPrimaryBlue,
                          onChanged: (v) => setState(() => _notificationsEnabled = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _notificationsEnabled ? _sendTestNotification : null,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Send Test Notification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      disabledBackgroundColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // About & Privacy section
                const _SectionTitle(title: 'About & Privacy', subtitle: null),
                const SizedBox(height: 8),
                Card(
                  color: kSurfaceGrey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                          Icon(Icons.privacy_tip_outlined, color: kPrimaryBlue),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text('Privacy First', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        const Text(
                          'All your tasks are processed locally on your device. We do not collect or store your personal information.',
                          style: TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                          Icon(Icons.info_outline, color: kPrimaryBlue),
                          SizedBox(width: 10),
                          Expanded(child: Text('EasyCare v1.0', style: TextStyle(fontWeight: FontWeight.w700))),
                        ]),
                        const SizedBox(height: 8),
                        const Text(
                          'Built with accessibility in mind for elderly users and those with cognitive challenges.',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
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

/// Rounded segmented option used for font-size buttons
class _SegmentedOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegmentedOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? kPrimaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black54),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}

/// A labelled slider with left/right labels and a small value label below.
class _LabeledSlider extends StatelessWidget {
  final double min;
  final double max;
  final int? divisions;
  final double value;
  final ValueChanged<double> onChanged;
  final String leftLabel;
  final String rightLabel;
  final String valueLabel;

  const _LabeledSlider({
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    required this.leftLabel,
    required this.rightLabel,
    required this.valueLabel,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSurfaceGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(leftLabel, style: const TextStyle(color: Colors.black54)),
            Text(rightLabel, style: const TextStyle(color: Colors.black54)),
          ]),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            activeColor: kPrimaryBlue,
            inactiveColor: Colors.grey.shade300,
            onChanged: onChanged,
          ),
          Align(
            alignment: Alignment.center,
            child: Text(valueLabel, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          )
        ]),
      ),
    );
  }
}