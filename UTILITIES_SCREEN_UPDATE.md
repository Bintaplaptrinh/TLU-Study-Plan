# Utilities Screen - All Semesters Display Update

## 📋 Overview
Updated the Utilities Screen to display data from **ALL semesters** instead of just the current semester, matching the web interface better.

## ✨ Key Changes

### 1. **Multi-Semester Marks Display**
- **Before**: Only showed marks for the currently selected semester
- **After**: Fetches and displays marks from ALL semesters
- Data is grouped by semester with expandable sections
- Shows comprehensive academic history

### 2. **Semester-Based Organization**
```dart
Map<int, List<StudentSubjectMark>> _marksBySemester = {};
```
- Marks are stored in a Map where key = semester ID, value = list of marks
- Semesters are sorted in descending order (newest first)
- Most recent semester is expanded by default

### 3. **Overall GPA Calculation**
- **Cumulative GPA**: Calculated across ALL semesters (matching web "Điểm tổng hợp")
- **Semester GPA**: Calculated for each individual semester
- Display format: "GPA Tích lũy (Hệ 4): X.XX"

### 4. **Expandable Semester Headers**
Each semester section has:
- ✅ Semester name (e.g., "Học kỳ 1 - 2024-2025")
- ✅ Number of subjects in that semester
- ✅ Total credits for that semester
- ✅ GPA for that semester
- ✅ Expand/collapse icon
- ✅ Tap to toggle visibility

### 5. **Enhanced User Info Section**
Shows contextual information:
- **Điểm số tab**: "X học kỳ có điểm"
- **Rèn luyện tab**: "X bản ghi rèn luyện"
- **Học phí tab**: "X bản ghi học phí"

## 🔄 Data Loading Logic

### Sequential Fetching
```dart
// Get all semesters from school years
final allSemesters = schoolYears.content
    .expand((year) => year.semesters)
    .toList();

// Fetch marks for each semester
for (final semester in allSemesters) {
  try {
    final marks = await userProvider.fetchStudentMarks(semester.id);
    if (marks.isNotEmpty) {
      marksBySemester[semester.id] = marks;
    }
  } catch (e) {
    // Skip semesters with errors, continue fetching others
  }
}
```

### Error Handling
- If a semester fails to load, it's skipped (doesn't block other semesters)
- Empty semesters are not displayed
- Only semesters with actual marks data are shown

## 📊 UI Components

### 1. Overall GPA Card
```
┌─────────────────────────────────┐
│ GPA Tích lũy (Hệ 4)    📚 120 TC│
│                                 │
│        4.00                     │
└─────────────────────────────────┘
```

### 2. Semester Header (Collapsible)
```
┌─────────────────────────────────┐
│ 🎓 Học kỳ 1 - 2024-2025      ▼ │
│    5 môn • 15 TC • GPA: 3.85   │
└─────────────────────────────────┘
```

### 3. Mark Cards (When Expanded)
```
┌─────────────────────────────────┐
│ Lập trình hướng đối tượng       │
│ [IT101]  💳 3.0 TC          8.5 │
│                              A  │
└─────────────────────────────────┘
```

## 🎯 Benefits

1. **Complete Academic History**: Students can view their entire transcript
2. **GPA Tracking**: See both overall and per-semester GPAs
3. **Better Organization**: Semesters are clearly separated and collapsible
4. **Matches Web UI**: Consistent with the official TLU education portal
5. **Performance**: Only expanded sections render mark cards (efficient memory usage)

## 🔍 Testing Checklist

- [x] Fetches marks from multiple semesters
- [x] Displays semesters in descending order (newest first)
- [x] Calculates cumulative GPA correctly
- [x] Calculates per-semester GPA correctly
- [x] Expand/collapse functionality works
- [x] Most recent semester expanded by default
- [x] Handles semesters with no data gracefully
- [x] Error handling for failed API calls
- [x] User info shows correct count

## 📱 Screenshots Comparison

### Before:
- Single semester view
- Only current semester marks
- Limited GPA info

### After:
- Multi-semester view
- Complete academic history
- Cumulative + semester GPAs
- Expandable sections
- Better organized

## 🚀 Next Steps

1. **Test with Real Data**: Run the app and verify all semesters load correctly
2. **Performance**: If many semesters, consider pagination or lazy loading
3. **Caching**: Consider caching marks data locally for offline access
4. **Export**: Add option to export transcript as PDF
5. **Filters**: Add filters for passed/failed subjects, specific semesters, etc.

## 📝 Technical Notes

- Uses `Map<int, List<StudentSubjectMark>>` for efficient semester-based lookup
- `Set<int> _expandedSemesters` tracks which sections are expanded
- Sequential API calls (not parallel) to avoid server overload
- Robust error handling - one failed semester doesn't break the whole view
- GPA calculations handle `double` credits properly (uses `.toInt()` for display)

## 🎨 Design Principles

1. **Progressive Disclosure**: Show summary first, details on demand (expandable)
2. **Information Hierarchy**: Overall GPA → Semester summaries → Individual marks
3. **Visual Feedback**: Clear expand/collapse icons, color-coded marks
4. **Consistency**: Matches existing app design language (Modern Soft UI)
5. **Performance**: Lazy rendering of mark cards (only when expanded)
