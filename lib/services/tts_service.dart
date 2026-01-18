// lib/services/tts_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TtsService {
  TtsService._internal();
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final FlutterTts _tts = FlutterTts();

  // Observable state: Is the TTS currently talking?
  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier(false);

  // Defaults optimized for elderly users
  double _speechRate = 0.4; // 0.4 is comfortable (range is 0.0 to 1.0 on Android)
  double _volume = 1.0;
  String _language = 'en-US'; 

  bool _initialized = false;

  double get speechRate => _speechRate;
  double get volume => _volume;

  bool get isPlaying => isSpeakingNotifier.value;

  Future<void> init() async {
    if (_initialized) return;

    // Load saved settings
    final prefs = await SharedPreferences.getInstance();
    _speechRate = prefs.getDouble('tts_rate') ?? _speechRate;
    _volume = prefs.getDouble('tts_volume') ?? _volume;

    // Apply settings
    await _tts.setVolume(_volume);
    await _tts.setSpeechRate(_speechRate);
    await _tts.setLanguage(_language);
    await _tts.setPitch(1.0); // Natural pitch

    // IMPORTANT: Wait for one sentence to finish before starting the next
    await _tts.awaitSpeakCompletion(true);

    // Handlers to track state
    _tts.setStartHandler(() {
      isSpeakingNotifier.value = true;
    });

    _tts.setCompletionHandler(() {
      isSpeakingNotifier.value = false;
    });

    _tts.setCancelHandler(() {
      isSpeakingNotifier.value = false;
    });

    _initialized = true;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await init(); // Ensure we are ready
    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
      isSpeakingNotifier.value = false;
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    isSpeakingNotifier.value = false;
  }

  // Update and Save Rate
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    await _tts.setSpeechRate(_speechRate);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_rate', _speechRate);
  }

  // Update and Save Volume
  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    await _tts.setVolume(_volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_volume', _volume);
  }
}