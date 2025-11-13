# TLU Study Planner

A modern Flutter application for TLU students to manage their study schedule, view course information, track exams, and access academic data.

## Features

- **Calendar View** - View daily schedule with horizontal date picker
- **Course Management** - Track courses, credits, and subject marks
- **Exam Schedule** - Never miss an exam with notifications
- **Academic Records** - View grades and behavior marks
- **Smart Notifications** - Daily reminders at 6 AM
- **Dark Mode** - Automatic theme switching
- **Auto Data Sync** - Automatic refresh every 30 days

## Requirements

- Flutter SDK: ^3.9.2
- iOS: 18.0+
- Android: API level 21+

## Getting Started

### Prerequisites

```bash
flutter doctor
```

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Bintaplaptrinh/TLU-Study-Plan.git
cd TLU-Study-Plan
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Building

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Architecture

- **State Management**: Provider
- **Database**: SQLite (sqflite)
- **HTTP Client**: Dio
- **Local Storage**: SharedPreferences
- **Notifications**: flutter_local_notifications

## API Integration

The app connects to TLU's education portal at `https://sinhvien1.tlu.edu.vn/education` to fetch:
- Student information
- Semester courses
- Subject marks
- Behavior marks
- Tuition information
- Exam schedules

## License

This project is private and intended for TLU students only.

## Version

Current version: **1.0.1**
