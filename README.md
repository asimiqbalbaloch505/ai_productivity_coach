# 🎯 AI Personal Productivity & Habit Coach

An AI-powered mobile app designed to help users manage daily tasks, build healthy habits, track deep-work focus sessions, and optimize daily routines through personalized AI coaching[cite: 1].

---

## 🚀 Key Features

* **Smart Task Manager**: Task CRUD operations, priority tags, deadline tracking, and overdue status handling[cite: 1].
* **Habit Tracker**: Daily and weekly habit check-ins, streak tracking, and completion logs[cite: 1].
* **Focus Mode**: Customizable Pomodoro timer with deep-work session logging[cite: 2].
* **AI Personal Coach**: Personalized daily planning and productivity recommendations driven by user activity history[cite: 1].
* **Progress & Analytics**: Interactive charts for habit streaks, focus time, and task completion rates[cite: 2].
* **Push Notifications**: Task deadline alerts, habit reminders, and weekly summaries via FCM[cite: 2].

---

## 🛠️ Tech Stack

* **Frontend**: [Flutter](https://flutter.dev/) (Dart)
* **Backend & Database**: [Supabase](https://supabase.com/) (PostgreSQL & Row-Level Security)[cite: 2]
* **AI Integration**: Gemini / OpenAI LLM API[cite: 2]
* **Notifications**: Firebase Cloud Messaging (FCM) & Local Notifications[cite: 2]

---

## 📁 Architecture & Folder Structure

This project follows a **Decentralized Feature-Sliced Architecture** to allow team members to work concurrently across isolated modules without Git merge conflicts:

```text
lib/
├── db_helper.dart                  # Shared Supabase Client
├── main.dart                       # App Entry Runner
└── features/                       # Feature Modules
    ├── auth/                       # User Auth & Profile
    ├── tasks/                      # Smart Task Manager
    ├── habits/                     # Habit Tracker
    ├── focus/                      # Pomodoro Focus Mode
    ├── ai_coach/                   # AI Coaching & Prompts
    ├── analytics/                  # Progress Reports & Charts
    ├── notifications/              # Push & Local Reminders
    └── testing/                    # Automated Tests & Mock Data
