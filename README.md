# TLU Study Planner

A modern Flutter application for TLU students to manage their study schedule, view course information, track exams, and access academic data.

> **Version 2.0** brings course registration, a redesigned Utilities hub, and a
> per-screen loading model. See [What's new in 2.0](#whats-new-in-20).

## Features

### Study & schedule

- **Calendar View** - View daily schedule with horizontal date picker
- **Course Management** - Track courses, credits, and subject marks
- **Exam Schedule** - Never miss an exam with notifications
- **Academic Records** - View grades and behavior marks
- **Smart Notifications** - Daily reminders at 6 AM
- **Dark Mode** - Automatic theme switching
- **Auto Data Sync** - Automatic refresh every 30 days
- **Offline Mode** - Cached data stays readable without a connection

### Course registration *(new in 2.0)*

- **Register and drop classes** directly from the app during an open period
- **Three-level selector** - school year -> term -> registration period
  (Học kỳ chính, Học kỳ phụ, Tiếng Anh tăng cường, Học phần tốt nghiệp,
  Chuẩn đầu ra ngoại ngữ, Ôn thi Chuẩn đầu ra ngoại ngữ)
- **Live seat counts** with full classes blocked before the request is sent
- **Period window banner** showing whether registration is open and until when
- **Timetable preview** per class - weekday, periods, room, lecturer, week range
- **Schedule-clash warning** before registering an overlapping class
- **Confirmation on drop**, matching the portal's own behaviour

### Utilities hub *(redesigned in 2.0)*

- **Card grid** replacing the old scrolling tab row - every utility visible at once
- **Dedicated pages** for Điểm, Rèn luyện, Học phí, Chương trình đào tạo
- **Slide-up transitions** with a back button on each page

## What's new in 2.0

| Area | Change |
|---|---|
| Course registration | New feature - register and drop course classes by period |
| Utilities | Four cramped tabs replaced by a card grid, one page per utility |
| Navigation | Shared slide-up page transition and a back button on every sub-page |
| Performance | Each utility page loads only its own data. Previously opening Utilities fetched all four sections, including one marks request *per semester* |
| Tests | Enrollment parsing covered by unit tests built from real portal payloads |

### Notes on the registration API

The registration endpoints are only reachable while a period is open, so they
were traced against a live period rather than guessed. Three details cost real
debugging time and are worth knowing before touching that code:

- The write endpoints expect the **entire class object** returned by
  `findByPeriod` as the request body, not a trimmed payload.
- The period-level `isAllowUnRegister` flag reads `false` even when dropping a
  class succeeds. Gate the drop button on the per-subject
  `isAllowSubjectUnRegister` flag instead.
- Timetable entries carry `startDate` / `endDate` as epoch milliseconds;
  `fromWeekStr` / `toWeekStr` exist but are always null.

## Screenshots

<table>
  <tr>
    <td align="center" width="50%">
      <img src="image/01-today-light.png" alt="01-today-light" width="420" />
    </td>
    <td align="center" width="50%">
      <img src="image/05-calendar-month-light.png" alt="05-calendar-month-light" width="420" />
    </td>
  </tr>
</table>

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

### Tests

```bash
flutter test
```

## Building

### Android
```bash
flutter build apk --release
```

Release signing reads `STORE_PASSWORD`, `KEY_ALIAS` and `KEY_PASSWORD` from the
environment and expects `rel.jks` at the project root. Both the keystore and
`local.properties` are gitignored - never commit them.

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

### Project layout

```
lib/
  models/        Data models and JSON parsing
  services/      Portal API clients, database, notifications
  providers/     App state (user, schedule, exams, enrollment)
  screens/       Screens and page-level widgets
  widgets/       Shared UI components
  utils/         Helpers, page transitions
  i18n/          Runtime translation layer
```

## API Integration

The app connects to TLU's education portal at `https://sinhvien1.tlu.edu.vn/education` to fetch:
- Student information
- Semester courses
- Subject marks
- Behavior marks
- Tuition information
- Exam schedules
- Course registration data

Authentication uses OAuth2 password grant against `/oauth/token`; every
`/api/...` call carries the resulting bearer token.

## License

This project is private and intended for TLU students only.

## Version

Current version: **2.0.0** <br>
Release Date: **26/08/2026**
