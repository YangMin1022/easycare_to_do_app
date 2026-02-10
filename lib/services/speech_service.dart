// lib/services/speech_service.dart
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  // Singleton pattern for easy global access
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  /// Returns true if the engine is currently capturing audio
  bool get isListening => _speech.isListening;

  /// Returns true if the engine is initialized and available
  bool get isAvailable => _isInitialized;

  /// Initialize the Speech Engine
  /// [onStatus] - Callback for engine status updates (e.g., 'listening', 'notListening')
  /// [onError] - Callback for errors
  Future<bool> init({
    Function(String status)? onStatus,
    Function(String error)? onError,
  }) async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech Status: $status');
          if (onStatus != null) onStatus(status);
        },
        onError: (errorNotification) {
          debugPrint('Speech Error: ${errorNotification.errorMsg}');
          if (onError != null) onError(errorNotification.errorMsg);
        },
      );
      return _isInitialized;
    } catch (e) {
      debugPrint("Speech Service Init Error: $e");
      return false;
    }
  }

  /// Start capturing speech
  /// [onResult] - Returns the transcribed text (including partial results)
  Future<void> startListening({required Function(String text) onResult}) async {
    if (!_isInitialized) {
      debugPrint("Speech Service not initialized.");
      return;
    }

    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      // --- CONFIGURATION FOR OFFLINE & UX ---
      localeId: 'en_US',         // Enforce English
      listenOptions: stt.SpeechListenOptions(
        onDevice: true,            // Offline priority
        cancelOnError: true,       // Stop on error
        partialResults: true,      // Stream words as spoken
        listenMode: stt.ListenMode.dictation,
      ),
      pauseFor: const Duration(seconds: 5), // Auto-stop after silence
    );
  }

  /// Stop capturing (processes final result)
  Future<void> stop() async {
    await _speech.stop();
  }

  /// Cancel capturing (discards result)
  Future<void> cancel() async {
    await _speech.cancel();
  }
}