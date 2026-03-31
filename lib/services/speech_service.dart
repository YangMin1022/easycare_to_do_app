// lib/services/speech_service.dart
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  // Singleton pattern for easy global access
  // Ensures only one instance of the microphone listener is active across the entire app
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  //The underlying plugin instance that interacts with the native Android speech APIs.
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  /// Returns true if the engine/microphone is currently capturing audio
  bool get isListening => _speech.isListening;

  /// Returns true if the engine is initialized and available
  bool get isAvailable => _isInitialized;

  // Initialize the Speech Engine
  // [onStatus] - Callback for engine status updates (e.g., 'listening', 'notListening')
  // [onError] - Callback for errors
  Future<bool> init({
    Function(String status)? onStatus,
    Function(String error)? onError,
  }) async {
    // If already initialized, skip re-initialization
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

  // Start capturing speech
  // [onResult] - Returns the transcribed text (including partial results)
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
        // Forces the OS to process speech locally rather than sending audio to the cloud. 
        // This ensures the app works without an internet connection and protects user privacy!
        onDevice: true,            // Offline priority
        cancelOnError: true,       // Stop on error
        partialResults: true,      // Stream words as spoken
        listenMode: stt.ListenMode.dictation, // Optimized for natural speech with pauses
      ),
      // Automatically stops the microphone if the user stops talking for 15 seconds,
      // preventing infinite background recording.
      pauseFor: const Duration(seconds: 15), // Auto-stop after silence
    );
  }

  // Stops capturing audio but processes and returns the final transcribed sentence.
  Future<void> stop() async {
    await _speech.stop();
  }

  // Abruptly cancels the recording session and completely discards any transcribed text.
  Future<void> cancel() async {
    await _speech.cancel();
  }
}