//Not yet
// lib/widgets/custom_date_picker.dart
import 'package:flutter/material.dart';

/// Show the custom date picker as a modal bottom sheet.
/// Returns the chosen DateTime (with time set to midnight) or null if cancelled.
///
/// Example:
/// final picked = await showCustomDatePicker(context, initialDate: DateTime.now());
/// if (picked != null) { setState(()=> _selectedDate = picked); }
Future<DateTime?> showCustomDatePicker(BuildContext context, {DateTime? initialDate}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // so we can have rounded corners
    builder: (ctx) => _CustomDatePickerSheet(initialDate: initialDate),
  );
}

class _CustomDatePickerSheet extends StatefulWidget {
  final DateTime? initialDate;
  const _CustomDatePickerSheet({Key? key, this.initialDate}) : super(key: key);

  @override
  State<_CustomDatePickerSheet> createState() => _CustomDatePickerSheetState();
}

class _CustomDatePickerSheetState extends State<_CustomDatePickerSheet> {
  // Month names (English). Replace if you need locale support.
  static const List<String> _months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // Limits for year increments
  static const int _minYear = 1900;
  static const int _maxYear = 2100;

  late int _selectedYear;
  late int _selectedMonth; // 1..12
  late int _selectedDay; // 1..daysInMonth

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final init = widget.initialDate ?? now;
    _selectedYear = init.year;
    _selectedMonth = init.month;
    _selectedDay = init.day.clamp(1, _daysInMonth(init.year, init.month));
  }

  static int _daysInMonth(int year, int month) {
    // February and leap-year handling
    final nextMonth = month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    final lastDayOfMonth = nextMonth.subtract(const Duration(days: 1));
    return lastDayOfMonth.day;
  }

  void _incMonth() {
    setState(() {
      if (_selectedMonth == 12) {
        if (_selectedYear < _maxYear) {
          _selectedMonth = 1;
          _selectedYear++;
        }
      } else {
        _selectedMonth++;
      }
      _selectedDay = _selectedDay.clamp(1, _daysInMonth(_selectedYear, _selectedMonth));
    });
  }

  void _decMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        if (_selectedYear > _minYear) {
          _selectedMonth = 12;
          _selectedYear--;
        }
      } else {
        _selectedMonth--;
      }
      _selectedDay = _selectedDay.clamp(1, _daysInMonth(_selectedYear, _selectedMonth));
    });
  }

  void _incDay() {
    setState(() {
      final max = _daysInMonth(_selectedYear, _selectedMonth);
      if (_selectedDay < max) _selectedDay++;
    });
  }

  void _decDay() {
    setState(() {
      if (_selectedDay > 1) _selectedDay--;
    });
  }

  void _incYear() {
    setState(() {
      if (_selectedYear < _maxYear) {
        _selectedYear++;
        _selectedDay = _selectedDay.clamp(1, _daysInMonth(_selectedYear, _selectedMonth));
      }
    });
  }

  void _decYear() {
    setState(() {
      if (_selectedYear > _minYear) {
        _selectedYear--;
        _selectedDay = _selectedDay.clamp(1, _daysInMonth(_selectedYear, _selectedMonth));
      }
    });
  }

  DateTime get _selectedDate => DateTime(_selectedYear, _selectedMonth, _selectedDay);

  @override
  Widget build(BuildContext context) {
    // Visual tokens (you can adjust to your design tokens)
    const Color primary = Color(0xFF0A6CF0);
    const Color surface = Color(0xFFF4F6F8);
    const Color badgeBg = Color(0xFFFFCB05); // yellow-like summary card
    final radius = const Radius.circular(20);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 24),
        // main sheet with rounded corners
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 12),

              // Blue header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.only(topLeft: radius, topRight: radius)),
                child: const Text('Pick a Specific Date', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              ),

              const SizedBox(height: 16),

              // Month selector
              _boxedRow(
                child: Row(
                  children: [
                    _circleIconButton(icon: Icons.chevron_left, onPressed: _decMonth, color: primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: primary, width: 2)),
                        child: Center(child: Text(_months[_selectedMonth - 1], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _circleIconButton(icon: Icons.chevron_right, onPressed: _incMonth, color: primary),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Day selector
              _boxedRow(
                child: Row(
                  children: [
                    _circleIconButton(icon: Icons.remove, onPressed: _decDay, color: primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: primary, width: 2)),
                        child: Center(child: Text('$_selectedDay', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _circleIconButton(icon: Icons.add, onPressed: _incDay, color: primary),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Year selector
              _boxedRow(
                child: Row(
                  children: [
                    _circleIconButton(icon: Icons.remove, onPressed: _decYear, color: primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: primary, width: 2)),
                        child: Center(child: Text('$_selectedYear', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _circleIconButton(icon: Icons.add, onPressed: _incYear, color: primary),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Selected date preview (yellow)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Text('Selected Date:', style: TextStyle(fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 8),
                    Text('${_months[_selectedMonth - 1]} ${_selectedDay.toString().padLeft(2, '0')}, $_selectedYear',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Confirm / Cancel
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // return the selected date (time set to midnight)
                        Navigator.of(context).pop(DateTime(_selectedYear, _selectedMonth, _selectedDay));
                      },
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: const Text('Confirm Date', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
              ),

            ],
          ),
        ),
      ),
    );
  }

  /// Utility to render a row inside a white/rounded boxed card with some spacing.
  Widget _boxedRow({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: child,
    );
  }

  Widget _circleIconButton({required IconData icon, required VoidCallback onPressed, required Color color}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 52,
        height: 44,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
