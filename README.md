# 🎙️ Smart Voice Task & Reminder App

A Flutter-based intelligent task management application developed as a Final Year Project (FYP). This app leverages Natural Language Processing (NLP) to allow users to create complex tasks and reminders using conversational voice commands or text input. 

## ✨ Key Features

*   **🎙️ Voice Dictation Mode:** Create tasks hands-free using built-in speech-to-text functionality.
*   **🧠 Smart NLP Parsing:** Automatically extracts task titles, absolute/relative dates, times, and reminder constraints from natural language (e.g., *"Remind me to call mom tomorrow at 6 pm"*).
*   **⏰ Dynamic Scheduling:** Intelligently distinguishes between event-based reminders (e.g., *"1 hour before my 9 AM meeting"*) and time-less tasks (e.g., *"Remind me to buy milk in 2 hours"*).
*   **🔔 Local Notifications:** Reliable, offline-first scheduled push notifications.
*   **📝 Dual Input Modes:** Seamlessly switch between Voice and Type modes with auto-filling UI controllers.

---

## 🛠️ Tech Stack

*   **Framework:** [Flutter](https://flutter.dev/) (Dart)
*   **Local Storage:** [Mention your DB here, e.g., SQLite / Hive / Isar]
*   **Speech Recognition:** `speech_to_text` (or your specific speech package)
*   **Notifications:** `flutter_local_notifications`

---

## 💡 How the Smart Parser Works

The core of this FYP is the custom-built `SmartParser`. It uses advanced Regular Expressions (Regex) and contextual logic to extract structured data from messy human language. It handles edge cases like substring traps, Daylight Saving Time (DST) safe math, and "middleman" phrasing.

### Parsing Examples:

| User Input | Extracted Task | Extracted Date/Time | Extracted Reminder |
| :--- | :--- | :--- | :--- |
| *"Take medication today at 8 am, remind me 30 mins before"* | Take medication | Today, 08:00 | 30 minutes before |
| *"Doctor appointment on 15 June at 10 am"* | Doctor appointment | 15 June, 10:00 | 1 hour before (Fallback) |
| *"Remind me to buy milk in 2 hours"* | Buy milk | Time-less | +2 hours from now |
| *"Check oven 15 minutes before"* | Check oven | Time-less | +15 minutes from now |

---

## 📂 Project Architecture

A quick look at the core files driving the intelligence of the app:

*   `lib/utils/smart_parser.dart`: The NLP engine. Decouples duration extraction from target phrases, calculates relative vs. absolute dates, and standardizes formats.
*   `lib/add_task_page.dart`: The dynamic UI. Handles the state between voice/type modes, validates missing data, and safely calculates `finalDue` and `reminderTime` for the notification service.
*   `lib/services/notification_service.dart`: Handles the OS-level alarm scheduling.
*   `lib/services/speech_service.dart`: Manages the microphone permissions and dictation streams.

---

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (v3.0.0 or higher)
*   Dart SDK
*   Android Studio / Xcode for emulators

### Installation

1. Clone the repository:
   ```bash
   git clone [https://github.com/](https://github.com/)[your-username]/[your-repo-name].git