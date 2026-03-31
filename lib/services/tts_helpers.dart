// lib/services/tts_helpers.dart
import 'package:intl/intl.dart';
import '../task_item.dart';
import 'tts_service.dart';
// Global instance of the TTS Singleton service.
final _tts = TtsService();

// Formats a [TaskItem] into a natural, conversational string optimized for text-to-speech.
 
// Standard DateTime strings (like "2026-03-31") sound terrible when read aloud by a robot.
// This helper uses the `intl` package to convert the date into a human-friendly format
// so the TTS engine speaks naturally.
String _formatTaskForSpeech(TaskItem t) {
  // Convert to human-readable date: "Friday November 7th"
  final date = DateFormat('EEEE MMMM d').format(t.due);
  // Convert to human-readable time: "8:30 AM"
  final time = DateFormat('h:mm a').format(t.due);
  
  String text = 'Task: ${t.title}.';
  
  // Only append the note if one actually exists, preventing awkward pauses
  if (t.note.isNotEmpty) {
    text += ' Note: ${t.note}.';
  }
  
  text += ' Due on $date at $time.';
  return text;
}

/// Reads a single task
Future<void> readSingleTask(TaskItem t) async {
  // If already speaking, stop it first
  if (_tts.isPlaying) {
    await _tts.stop();
    return; // Acts as a toggle
  }
  // Initialize and Speak
  await _tts.init();
  final text = _formatTaskForSpeech(t);
  await _tts.speak(text);
}

/// Reads a list of tasks sequentially
Future<void> readAllTasks(List<TaskItem> tasks) async {
  await _tts.init();

  // 1. If currently speaking, STOP and exit.
  if (_tts.isPlaying) {
    await _tts.stop();
    return;
  }
  // 2. If no tasks
  if (tasks.isEmpty) {
    await _tts.speak('You have no tasks to do right now.');
    return;
  }
  // Provide contextual summary before reading individual tasks
  await _tts.speak('You have ${tasks.length} tasks.');
  
  // Loop through and read each one. 
  // Because we set awaitSpeakCompletion(true) in the service, 
  // the loop will naturally pause until the voice finishes the current task.
  for (final t in tasks) {
    await _tts.speak(_formatTaskForSpeech(t));
  }
}