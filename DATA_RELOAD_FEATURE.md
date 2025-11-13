# Data Reload Feature - Implementation Summary

## 📋 Overview
Added a "Cập nhật dữ liệu" (Update Data) card in Settings that allows users to manually reload all data from the server, with automatic monthly reload functionality.

## ✨ Key Features

### 1. **Manual Data Reload**
- New button in Settings screen to reload all data on demand
- Shows loading progress with percentage indicator
- Reloads: User info, school years, semesters, courses, and exam schedules

### 2. **Last Reload Timestamp**
- Tracks when data was last reloaded (stored in SharedPreferences)
- Displays human-readable time since last reload:
  - "Cập nhật hôm nay" (Updated today)
  - "Cập nhật 1 ngày trước" (Updated 1 day ago)
  - "Cập nhật X ngày trước" (Updated X days ago)
  - "Chưa cập nhật" (Never updated)

### 3. **Auto-Reload After 30 Days**
- Automatically checks on app startup if data is older than 30 days
- Shows warning indicator when data needs updating
- Auto-reloads in background if needed

### 4. **Visual Indicators**
- ✅ Green icon when data is fresh (< 30 days)
- ⚠️ Red icon when data needs update (≥ 30 days)
- Warning message when auto-reload is recommended

## 🔧 Technical Implementation

### UserProvider Changes

#### New Properties
```dart
static const String _lastDataReloadKey = 'lastDataReload';

DateTime? get lastDataReload {
  final timestamp = _prefs.getInt(_lastDataReloadKey);
  if (timestamp == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(timestamp);
}

bool get shouldAutoReload {
  final lastReload = lastDataReload;
  if (lastReload == null) return false;
  final daysSinceReload = DateTime.now().difference(lastReload).inDays;
  return daysSinceReload >= 30;
}
```

#### New Method: `reloadAllData()`
```dart
Future<void> reloadAllData() async {
  // Step 1: Refresh user data (20%)
  _tluUser = await _authService.getCurrentUser(_accessToken!);
  
  // Step 2: Fetch school years (40%)
  _schoolYears = await _authService.getSchoolYears(_accessToken!);
  
  // Step 3: Get semester info (60%)
  _currentSemesterInfo = await _authService.getSemesterInfo(_accessToken!);
  
  // Step 4: Load courses (80%)
  await loadCoursesForSemester(_selectedSemester!.id);
  
  // Step 5: Load exam schedules (90%)
  await _examProvider!.fetchAvailableSemesters(_accessToken!);
  
  // Save timestamp (100%)
  await _prefs.setInt(_lastDataReloadKey, DateTime.now().millisecondsSinceEpoch);
}
```

#### Auto-Reload on Init
```dart
Future<void> init() async {
  // ... existing code ...
  
  if (shouldAutoReload) {
    _log.log('Auto-reloading data (30+ days since last reload)', level: LogLevel.info);
    try {
      await reloadAllData();
    } catch (e) {
      _log.log('Auto-reload failed: $e', level: LogLevel.warning);
      await _refreshFromApi(); // Fallback
    }
  }
}
```

#### Login Timestamp Tracking
```dart
// In loginWithApi() method
await _prefs.setInt(_lastDataReloadKey, DateTime.now().millisecondsSinceEpoch);
```

### Settings Screen UI

#### New Section: "Dữ liệu"
Located between "Tài khoản" and "Thông báo" sections.

#### Card Components
1. **Header Icon**
   - Green sync icon (normal state)
   - Red warning icon (needs update)

2. **Status Text**
   - Title: "Cập nhật dữ liệu"
   - Subtitle: Days since last reload

3. **Description**
   - "Tải lại lịch học, lịch thi và thông tin học kỳ từ máy chủ"

4. **Warning Banner** (when ≥ 30 days)
   ```
   ⚠️ Đã quá 30 ngày kể từ lần cập nhật cuối.
   Nên cập nhật dữ liệu mới
   ```

5. **Update Button**
   - Primary variant (red) when needs update
   - Secondary variant (gray) when fresh
   - Shows loading dialog with progress during reload

## 🎨 UI Design

### Fresh State (< 30 days)
```
┌─────────────────────────────────────────┐
│ 🔄 Cập nhật dữ liệu                     │
│    Cập nhật 5 ngày trước                │
│                                         │
│ Tải lại lịch học, lịch thi và thông    │
│ tin học kỳ từ máy chủ                   │
│                                         │
│ [Cập nhật ngay]                         │
└─────────────────────────────────────────┘
```

### Needs Update (≥ 30 days)
```
┌─────────────────────────────────────────┐
│ ⚠️  Cập nhật dữ liệu                    │
│    Cập nhật 35 ngày trước               │
│                                         │
│ Tải lại lịch học, lịch thi và thông    │
│ tin học kỳ từ máy chủ                   │
│                                         │
│ ┌───────────────────────────────────┐   │
│ │ ⚠️ Đã quá 30 ngày kể từ lần cập   │   │
│ │ nhật cuối. Nên cập nhật dữ liệu   │   │
│ │ mới                               │   │
│ └───────────────────────────────────┘   │
│                                         │
│ [Cập nhật ngay] ← Red/Primary          │
└─────────────────────────────────────────┘
```

### Loading Dialog
```
┌─────────────────────────────────────────┐
│                                         │
│           ⏳ Loading spinner             │
│                                         │
│     Đang tải thông tin người dùng...    │
│                                         │
│     ▓▓▓▓▓▓░░░░░░░░░░ 40%               │
│                                         │
└─────────────────────────────────────────┘
```

## 📊 Data Flow

### Manual Reload
```
User taps "Cập nhật ngay"
    ↓
Show loading dialog
    ↓
Call reloadAllData()
    ↓
Progress: 20% → 40% → 60% → 80% → 100%
    ↓
Save timestamp
    ↓
Close dialog
    ↓
Show success message
```

### Auto-Reload on Startup
```
App launches
    ↓
UserProvider.init()
    ↓
Check shouldAutoReload
    ↓
If ≥ 30 days → reloadAllData()
    ↓
Update UI
```

## 🔍 Progress Tracking

| Step | Progress | Description |
|------|----------|-------------|
| 1 | 20% | Đang tải thông tin người dùng... |
| 2 | 40% | Đang tải danh sách học kỳ... |
| 3 | 60% | Đang tải thông tin học kỳ hiện tại... |
| 4 | 80% | Đang tải lịch học... |
| 5 | 90% | Đang tải lịch thi... |
| 6 | 100% | Hoàn tất! |

## 🎯 User Experience

### First Time Users
- No timestamp shown (displays "Chưa cập nhật")
- Timestamp saved after first login
- Auto-reload disabled until 30 days pass

### Regular Users
- See last reload time in settings
- Get visual warning after 30 days
- Can manually reload anytime

### After Update
- Success snackbar: "✅ Đã cập nhật dữ liệu thành công"
- Timestamp updates immediately
- UI refreshes to show new data

### Error Handling
- Network errors show: "❌ Lỗi: [error message]"
- Loading dialog closes automatically
- Falls back to cached data

## 📝 Code Locations

| Component | File | Lines |
|-----------|------|-------|
| Reload method | `user_provider.dart` | ~656-716 |
| Timestamp getters | `user_provider.dart` | ~677-691 |
| Auto-reload logic | `user_provider.dart` | ~148-163 |
| Settings UI card | `settings_screen.dart` | ~330-491 |
| Timestamp constant | `user_provider.dart` | ~48 |

## ✅ Testing Checklist

- [x] Manual reload works and shows progress
- [x] Timestamp saves correctly
- [x] Last reload time displays correctly
- [x] 30-day warning shows when needed
- [x] Auto-reload triggers on startup (when ≥ 30 days)
- [x] Loading dialog shows progress
- [x] Success message appears after reload
- [x] Error handling works for network failures
- [x] Login saves timestamp
- [x] Hidden when user not logged in

## 🚀 Future Enhancements

1. **Customizable Auto-Reload Interval**
   - Let users choose: 7, 14, 30, 60 days
   
2. **Background Sync**
   - Auto-reload when app comes to foreground
   
3. **Selective Reload**
   - Separate buttons for courses, exams, user info
   
4. **Sync Indicator**
   - Show sync icon in app bar when reloading
   
5. **Offline Mode Banner**
   - Show warning when data is old and offline

## 📱 User Benefits

1. **Always Fresh Data**: Never miss schedule changes
2. **Manual Control**: Update anytime without re-login
3. **Auto-Update**: Stays current without user action
4. **Transparency**: Know exactly when data was last updated
5. **Convenience**: One-tap update vs full logout/login

## 🎨 Design Consistency

- Follows existing Modern Soft UI theme
- Uses standard color scheme (primary, error, surface)
- Matches other settings cards
- Consistent with existing patterns (AppButton, loading dialogs)
- Proper spacing and padding throughout
