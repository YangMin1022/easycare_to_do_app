import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontSizeOption { small, medium, large }

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // A reactive variable that broadcasts font size changes. 
  // In `main.dart`, a `ValueListenableBuilder` listens to this notifier and instantly
  // rebuilds the entire `MaterialApp` with the new text scale when it changes.
  final ValueNotifier<FontSizeOption> fontSizeNotifier = ValueNotifier(FontSizeOption.medium);
  SharedPreferences? _prefs;

  // 1. LOAD: Initialize SharedPreferences and load the saved value
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Enums cannot be saved directly to SharedPreferences, so we save them as integer indexes.
    // 0 = small, 1 = medium, 2 = large.
    // We default to 1 (medium) if the user is opening the app for the very first time.
    final savedIndex = _prefs?.getInt('fontSizeIndex') ?? 1; 
    
    // Safely map the integer back to the Enum
    if (savedIndex >= 0 && savedIndex < FontSizeOption.values.length) {
      fontSizeNotifier.value = FontSizeOption.values[savedIndex];
    }
  }

  /// Converts the currently selected `FontSizeOption` enum into an actual double multiplier.
  /// This multiplier is fed directly into Flutter's `TextScaler.linear()` in `main.dart`.
  double get textScaleFactor {
    switch (fontSizeNotifier.value) {
      case FontSizeOption.small:
        return 1.0; // Default size
      case FontSizeOption.medium:
        return 1.25;  // 25% larger
      case FontSizeOption.large:
        return 1.50; // 50% larger
    }
  }

  // 2. SAVE: Update the notifier and write the new value to device storage
  Future<void> setFontSize(FontSizeOption option) async {
    fontSizeNotifier.value = option;
    // Persist the choice for the next time the app launches
    await _prefs?.setInt('fontSizeIndex', option.index);
  }

  // Retrieves the saved notification state (defaults to true)
  bool get notificationsEnabled => _prefs?.getBool('notifications_enabled') ?? true;

  // Saves the notification state to device storage
  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs?.setBool('notifications_enabled', value);
  }
}