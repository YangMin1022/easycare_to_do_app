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
*   **Local Storage:** Drift
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
| *"Check oven in 15 minutes* | Check oven | Time-less | +15 minutes from now |

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
   git clone https://github.com/YangMin1022/easycare_to_do_app.git
   ```
2. Navigate to the project directory:
   ```bash
   cd [repo-name]
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application:
   ```bash
   flutter run
   ```

*(Note: Voice dictation requires a physical device or an emulator with a configured microphone).*

---

## 🧪 Testing

The NLP parsing logic has been rigorously tested against various edge cases, including:
*   Standard Date/Time formats (e.g., "15 June", "June 15th")
*   Relative Time constraints (e.g., "in 2 hours", "1 day before")
*   Time-less scheduling fallbacks (e.g., "Remind me tomorrow")
*   Punctuation variants (e.g., "9a.m.", "6pm")

---

## 🎓 Academic Context

This project was developed as a Final Year Project by **Poh Yang Min** at **Peninsula College, The Ship Campus**. 

It demonstrates proficiency in cross-platform mobile development, asynchronous programming, natural language text processing, and user-centric UI/UX design.

---