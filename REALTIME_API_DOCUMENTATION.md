# Real-Time API Functions Documentation

This document explains the three new real-time API functions added to the TLU Calendar app for fetching student marks, behavior marks, and tuition data.

## Overview

These APIs provide **real-time data** that should **NOT be cached** to the database. They are designed to be called fresh every time a user navigates to the corresponding page to ensure the most up-to-date information is displayed.

## API Endpoints

### 1. Student Subject Marks (Điểm sinh viên)

**Endpoint:** `GET /api/studentsubjectmark/studentLoginUser/{semesterId}`

**Method:** `UserProvider.fetchStudentMarks(int semesterId)`

**Returns:** `List<StudentSubjectMark>`

**Fields:**
- `id` - Mark record ID
- `subjectCode` - Subject code (e.g., "CSE101")
- `subjectName` - Subject name
- `credits` - Number of credits
- `mark10` - Mark on scale of 10 (nullable)
- `mark4` - Mark on scale of 4 (nullable)
- `markLetter` - Letter grade (A, B+, B, C+, C, D+, D, F) (nullable)
- `markText` - Text representation (nullable)
- `semesterId` - Semester ID
- `semesterName` - Semester name
- `isPassed` - Whether the student passed

**Example Usage:**
```dart
final userProvider = context.read<UserProvider>();
final selectedSemester = userProvider.selectedSemester;

if (selectedSemester != null) {
  final marks = await userProvider.fetchStudentMarks(selectedSemester.id);
  
  for (var mark in marks) {
    print('${mark.subjectName}: ${mark.mark10}');
  }
}
```

---

### 2. Student Behavior Marks (Điểm rèn luyện)

**Endpoint:** `GET /api/student_semester_behavior_mark/viewStudentBehaviorMarkByLoginUser`

**Method:** `UserProvider.fetchBehaviorMarks()`

**Returns:** `List<StudentBehaviorMark>`

**Fields:**
- `id` - Behavior mark record ID
- `semesterId` - Semester ID
- `semesterName` - Semester name
- `mark` - Behavior mark (0-100)
- `classification` - Classification level (Xuất sắc, Giỏi, Khá, Trung bình, Yếu)
- `note` - Additional notes (nullable)

**Example Usage:**
```dart
final userProvider = context.read<UserProvider>();
final behaviorMarks = await userProvider.fetchBehaviorMarks();

for (var mark in behaviorMarks) {
  print('${mark.semesterName}: ${mark.mark} - ${mark.classification}');
}
```

---

### 3. Student Tuition Payment (Học phí)

**Endpoint:** `GET /api/student/viewstudentpayablebyLoginUser`

**Method:** `UserProvider.fetchStudentPayable()`

**Returns:** `List<StudentTuition>`

**Fields:**
- `semesterId` - Semester ID
- `semesterName` - Semester name
- `tuitionFee` - Total tuition fee
- `paidAmount` - Amount already paid
- `remainingAmount` - Amount remaining to be paid
- `paymentStatus` - Payment status (e.g., "Đã đóng", "Chưa đóng")
- `paymentDeadline` - Payment deadline date (nullable)

**Example Usage:**
```dart
final userProvider = context.read<UserProvider>();
final tuitionData = await userProvider.fetchStudentPayable();

for (var tuition in tuitionData) {
  print('${tuition.semesterName}:');
  print('  Tổng: ${tuition.tuitionFee}');
  print('  Đã đóng: ${tuition.paidAmount}');
  print('  Còn lại: ${tuition.remainingAmount}');
  print('  Trạng thái: ${tuition.paymentStatus}');
}
```

---

## Important Notes

### 🔄 Real-Time Data (Not Cached)

Unlike course schedules and exam periods which are cached to the database for offline access, these three API functions return **real-time data** that should be:

1. ✅ **Fetched fresh** every time the user navigates to the page
2. ✅ **Reloaded** when the user pulls to refresh
3. ❌ **NOT cached** to the database
4. ❌ **NOT stored** in SharedPreferences

### 🔐 Authentication Required

All three functions require a valid access token. They will:
- Return an empty list `[]` if no access token is available
- Log an error message to the console
- Handle SSL certificate errors gracefully

### 📱 UI Integration Pattern

The recommended pattern for integrating these APIs in a screen:

```dart
class MyMarksScreen extends StatefulWidget {
  @override
  State<MyMarksScreen> createState() => _MyMarksScreenState();
}

class _MyMarksScreenState extends State<MyMarksScreen> {
  List<StudentSubjectMark> _marks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load data when screen first opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMarks();
    });
  }

  Future<void> _loadMarks() async {
    setState(() => _isLoading = true);
    
    final userProvider = context.read<UserProvider>();
    final selectedSemester = userProvider.selectedSemester;
    
    if (selectedSemester != null) {
      final marks = await userProvider.fetchStudentMarks(selectedSemester.id);
      setState(() {
        _marks = marks;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Điểm số')),
      body: RefreshIndicator(
        onRefresh: _loadMarks, // Pull to refresh
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _marks.length,
                itemBuilder: (context, index) {
                  final mark = _marks[index];
                  return ListTile(
                    title: Text(mark.subjectName),
                    trailing: Text('${mark.mark10}'),
                  );
                },
              ),
      ),
    );
  }
}
```

### 🛡️ Error Handling

All three functions handle errors gracefully:
- SSL certificate errors
- Network timeouts (10 seconds)
- Invalid responses
- Authentication failures

On error, they return an empty list and log the error to the console.

### 📊 Example Screen

A complete example implementation is provided in:
```
lib/screens/marks_screen_example.dart
```

This example shows:
- ✅ Loading all three data types
- ✅ Pull-to-refresh functionality
- ✅ Loading indicators
- ✅ Empty states
- ✅ Formatted display of marks, behavior marks, and tuition
- ✅ Color-coded status indicators

---

## Migration from Cached Data

If you previously had cached versions of this data:

**Before (Cached):**
```dart
// ❌ Old pattern with database caching
List<StudentCourseSubject> get studentCourses => _studentCourses;
```

**After (Real-Time):**
```dart
// ✅ New pattern without caching
Future<List<StudentSubjectMark>> fetchStudentMarks(int semesterId) async {
  return await _authService.getStudentMarks(_accessToken!, semesterId);
}
```

The key difference is that courses/exams are **cached for offline use**, while marks/tuition are **fetched fresh each time** to show current data.

---

## Testing

To test these functions:

1. Make sure you're logged in with valid TLU credentials
2. Navigate to a screen that calls one of these functions
3. Check the console logs for fetch status
4. Verify data is displayed correctly
5. Test pull-to-refresh functionality
6. Test with no internet connection (should show error gracefully)

---

## Related Files

- **Models:** `lib/models/api_response.dart`
  - `StudentSubjectMark`
  - `StudentBehaviorMark`
  - `StudentTuition`

- **Services:** `lib/services/auth_service.dart`
  - `getStudentMarks()`
  - `getBehaviorMarks()`
  - `getStudentPayable()`

- **Provider:** `lib/providers/user_provider.dart`
  - `fetchStudentMarks()`
  - `fetchBehaviorMarks()`
  - `fetchStudentPayable()`

- **Example:** `lib/screens/marks_screen_example.dart`
  - Complete implementation example
