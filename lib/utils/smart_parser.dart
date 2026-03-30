// lib/utils/smart_parser.dart
import 'package:flutter/material.dart';

enum ReminderType { before, fromNow }

class ParsedData {
  final String title;
  final DateTime? date;
  final TimeOfDay? time;
  final Duration? reminder;
  final ReminderType? reminderType;

  ParsedData({
    required this.title,
    this.date,
    this.time,
    this.reminder,
    this.reminderType,
  });
}

class SmartParser {
  static ParsedData parse(String text) {
    String cleanText = text;
    DateTime? foundDate;
    TimeOfDay? foundTime;
    Duration? foundReminder;
    ReminderType? reminderType;

    final now = DateTime.now();

    // --- 1. EXTRACT DYNAMIC REMINDER FIRST ---
    // We do this first so "2 hours" doesn't get confused with "2:00 PM"
    // Matches: "remind me 2 hours", "remind me in 30 mins", "remind me 1 day before"
    // final reminderRegex = RegExp(r'reminds?\s+me\s+(in|before)?\s*((?:\d+\s*(?:hour|hr|minute|min|day)s?\s*)+)\s*(before)?', caseSensitive: false);
    final reminderRegex = RegExp(r'\b(in|before)?\s*((?:\d+\s*(?:hour|hr|minute|min|day)s?\s*)+)\s*(before)?\b', caseSensitive: false);
    final reminderMatch = reminderRegex.firstMatch(cleanText);

    if (reminderMatch != null) {
      final prefix = reminderMatch.group(1)?.toLowerCase(); // "in", "before", or null
      final durationText = reminderMatch.group(2)!;         // "2 hours 30 minutes"
      final suffix = reminderMatch.group(3)?.toLowerCase(); // "before" or null

      // Determine type safely
      if (suffix == 'before' || prefix == 'before') {
        reminderType = ReminderType.before;
      } else if (prefix == 'in') {
        reminderType = ReminderType.fromNow;
      } else {
        // Default fallback if they just say "remind me 30 mins" 
        reminderType = ReminderType.fromNow; 
      }
      
      final unitRegex = RegExp(
        r'(\d+)\s*(hour|hr|minute|min|day)s?',
        caseSensitive: false,
      );

      int totalMinutes = 0;
      int totalHours = 0;
      int totalDays = 0;

      for (final match in unitRegex.allMatches(durationText)) {
        final value = int.parse(match.group(1)!);
        final unit = match.group(2)!.toLowerCase();

        if (unit.startsWith('min')) {
          totalMinutes += value;
        } else if (unit.startsWith('hour') || unit.startsWith('hr')) {
          totalHours += value;
        } else if (unit.startsWith('day')) {
          totalDays += value;
        }
      }

      foundReminder = Duration(
        days: totalDays,
        hours: totalHours,
        minutes: totalMinutes,
      );
      // Remove the reminder phrase from the title
      cleanText = cleanText.replaceAll(reminderMatch.group(0)!, '');
    } 
    // Fallback: If they just said "remind me" without a time
    // else if (cleanText.toLowerCase().contains(RegExp(r'reminds?\s+me'))) {
    //   foundReminder = const Duration(hours: 1); // Default
    //   reminderType = ReminderType.before;
    //   cleanText = cleanText.replaceAll(RegExp(r'\breminds?\s+me\b', caseSensitive: false), '').trim();
    // }
    // --- STRIP "REMIND ME" & HANDLE FALLBACK ---
    // Now we clean up the words "remind me" separately
    if (cleanText.toLowerCase().contains(RegExp(r'reminds?\s+me'))) {
      if (foundReminder == null) {
        // ONLY apply the 1-hour fallback if no specific time was found earlier
        foundReminder = const Duration(hours: 1);
        reminderType = ReminderType.before;
      }
      // Pro-tip: This regex also removes the word "to" if it follows "remind me"
      // So "Remind me to buy milk" elegantly becomes "Buy milk"!
      cleanText = cleanText
          .replaceAll(RegExp(r'\breminds?\s+me\s*(?:to\s+)?', caseSensitive: false), '')
          .trim();
    }

    // --- 2. RELATIVE DATES (Tomorrow, Today) ---
    if (cleanText.toLowerCase().contains('tomorrow')) {
      foundDate = now.add(const Duration(days: 1));
      cleanText = _removeKeyword(cleanText, 'tomorrow');
    } else if (cleanText.toLowerCase().contains('today')) {
      foundDate = now;
      cleanText = _removeKeyword(cleanText, 'today');
    }

    // --- 3. ABSOLUTE DATES (15 June, June 25) ---
    if (foundDate == null) {
      final dateMatch = _findAbsoluteDate(cleanText);
      if (dateMatch != null) {
        foundDate = dateMatch.date;
        cleanText = cleanText.replaceAll(dateMatch.matchString, '');
      }
    }

    // --- 4. TIME (at 9 AM, 9:30 PM) ---
    // Improved Regex: Handles "9am", "9:00 am", "at 9"
    final timeRegex = RegExp(r'\b(at\s+)?(\d{1,2})(:(\d{2}))?\s*(a\.?m\.?|p\.?m\.?)\b', caseSensitive: false);
    final timeMatch = timeRegex.firstMatch(cleanText);

    if (timeMatch != null) {
      final hourStr = timeMatch.group(2);
      final minuteStr = timeMatch.group(4);
      // Clean the period string (remove dots) so "a.m." becomes "am"
      final period = timeMatch.group(5)?.toLowerCase().replaceAll('.', '');

      if (hourStr != null) {
        int hour = int.parse(hourStr);
        int minute = minuteStr != null ? int.parse(minuteStr) : 0;

        if (period == 'pm' && hour < 12) hour += 12;
        if (period == 'am' && hour == 12) hour = 0;

        foundTime = TimeOfDay(hour: hour, minute: minute);
        // Remove the match from the text
        // cleanText = cleanText.replaceAll(timeMatch.group(0)!, '');
      }
    }

    // --- 5. CLEANUP ---
    // Remove punctuation (commas, dots) left over from cutting
    cleanText = cleanText.replaceAll(RegExp(r'[,\.]'), ''); 
    // Normalize spaces
    cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Capitalize
    if (cleanText.isNotEmpty) {
      cleanText = cleanText[0].toUpperCase() + cleanText.substring(1);
    }

    return ParsedData(
      title: cleanText,
      date: foundDate,
      time: foundTime,
      reminder: foundReminder,
      reminderType: reminderType,
    );
  }

  static String _removeKeyword(String text, String keyword) {
    return text.replaceAll(RegExp(r'\b(?:on\s+)?' + keyword + r'\b', caseSensitive: false), '');
  }

  // --- HELPER: Find "15 June" or "June 15" ---
  static _DateMatch? _findAbsoluteDate(String text) {
    final months = {
      'january': 1, 'jan': 1,
      'february': 2, 'feb': 2,
      'march': 3, 'mar': 3,
      'april': 4, 'apr': 4,
      'may': 5,
      'june': 6, 'jun': 6,
      'july': 7, 'jul': 7,
      'august': 8, 'aug': 8,
      'september': 9, 'sep': 9, 'sept': 9,
      'october': 10, 'oct': 10,
      'november': 11, 'nov': 11,
      'december': 12, 'dec': 12
    };

    // Regex for "15 June" or "15th June"
    // Group 1: Day, Group 3: Month
    final dayMonthRegex = RegExp(r'\b(?:on\s+)?(\d{1,2})(st|nd|rd|th)?\s+([a-zA-Z]+)\b', caseSensitive: false);
    
    // Regex for "June 15" or "June 15th"
    // Group 1: Month, Group 2: Day
    final monthDayRegex = RegExp(r'\b(?:on\s+)?([a-zA-Z]+)\s+(\d{1,2})(st|nd|rd|th)?\b', caseSensitive: false);

    final now = DateTime.now();

    // Check "15 June" format
    final todayAtMidnight = DateTime(now.year, now.month, now.day);

    _DateMatch? processMatch(String? monthStr, String? dayStr, String fullMatch) {
      if (monthStr == null || dayStr == null) return null;
      final monthKey = monthStr.toLowerCase();
      if (!months.containsKey(monthKey)) return null;

      final day = int.parse(dayStr);
      final month = months[monthKey]!;
      int year = now.year;

      final parsedDateThisYear = DateTime(year, month, day);

      if (parsedDateThisYear.isBefore(todayAtMidnight)) {
        year++;
      }

      return _DateMatch(
        date: DateTime(year, month, day),
        matchString: fullMatch,
      );
    }

    for (final match in dayMonthRegex.allMatches(text)) {
      final result = processMatch(match.group(3), match.group(1), match.group(0)!);
      if (result != null) return result;
    }

    for (final match in monthDayRegex.allMatches(text)) {
      final result = processMatch(match.group(1), match.group(2), match.group(0)!);
      if (result != null) return result;
    }

    return null;
  }
}

class _DateMatch {
  final DateTime date;
  final String matchString;
  _DateMatch({required this.date, required this.matchString});
}