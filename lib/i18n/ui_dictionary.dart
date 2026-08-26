/// Hand-written vi → en pairs for the app's own interface strings.
///
/// These are consulted before the network translator, which means the labels a
/// student sees most are instant, work offline, and use the wording we chose
/// rather than whatever a machine returns. Anything not listed here (course
/// names, lecturer names, server messages) falls through to the translator.
class UiDictionary {
  UiDictionary._();

  /// Vietnamese → English. Keys are matched case-insensitively after trimming.
  static const Map<String, String> viToEn = {
    // ── Navigation & screen titles ──
    'Hôm nay': 'Today',
    'Lịch học': 'Schedule',
    'Lịch thi': 'Exams',
    'Tiện ích': 'Utilities',
    'Cài đặt': 'Settings',
    'Lịch hôm nay': "Today's schedule",
    'Lịch học hôm nay': "Today's schedule",
    'Thời khóa biểu': 'Timetable',
    'Quản lý lịch học': 'Manage your schedule',
    'Điểm & Học phí': 'Grades & Tuition',
    'Thông tin': 'About',
    'Hiển thị': 'Display',
    'Dữ liệu': 'Data',
    'Tài khoản': 'Account',
    'Thông báo': 'Notifications',

    // ── Calendar ──
    'Tuần': 'Week',
    'Tháng': 'Month',
    'Ngày': 'Day',
    'Hiện tại': 'Current',
    'Chọn ngày': 'Pick a date',
    'Về hôm nay': 'Back to today',
    'Chọn học kỳ': 'Select semester',
    'Chưa chọn học kỳ': 'No semester selected',
    'Vui lòng chọn học kỳ': 'Please select a semester',
    'Vui lòng chọn học kỳ trong cài đặt': 'Please select a semester in Settings',
    'Đợt học': 'Study period',
    'Lần thi': 'Exam session',
    'Vui lòng chọn đợt học và lần thi':
        'Please select a study period and exam session',
    'Thứ Hai': 'Monday',
    'Thứ Ba': 'Tuesday',
    'Thứ Tư': 'Wednesday',
    'Thứ Năm': 'Thursday',
    'Thứ Sáu': 'Friday',
    'Thứ Bảy': 'Saturday',
    'Chủ Nhật': 'Sunday',

    // ── Class list ──
    'ĐANG HỌC': 'IN CLASS',
    'Không có lớp': 'No classes',
    'Không có lớp hôm nay': 'No classes today',
    'Hãy tận hưởng ngày nghỉ của bạn!': 'Enjoy your day off!',
    'Chọn một ngày khác để xem lịch học': 'Pick another day to see its classes',
    'Đang tải lịch học...': 'Loading your schedule…',
    'Còn lại': 'Remaining',
    'Tiết kế tiếp': 'Next class',
    'Đã xong': 'All done',
    'Nghỉ': 'Free',
    'Phòng': 'Room',
    'Giảng viên': 'Lecturer',
    'Nhà': 'Bldg',
    'Toà nhà': 'Building',
    'Tòa nhà': 'Building',
    'Cơ sở': 'Campus',
    'Giảng đường': 'Lecture hall',
    'Phòng máy': 'Computer lab',
    'Sân vận động': 'Stadium',
    'Nhà thi đấu': 'Sports hall',

    // ── Exams ──
    'Không có lịch thi': 'No exams scheduled',
    'Chưa có lịch thi nào được công bố cho học kỳ này':
        'No exams have been published for this semester yet',
    'Chưa có thông tin phòng thi': 'Exam room not announced yet',
    'Vui lòng đăng nhập để xem lịch thi': 'Sign in to see your exam schedule',
    'Sắp đến giờ học!': 'Class starting soon',
    'Sắp đến giờ thi!': 'Exam starting soon',

    // ── Auth ──
    'Đăng nhập': 'Sign in',
    'Đăng xuất': 'Sign out',
    'Đã đăng nhập': 'Signed in',
    'Đã đăng xuất': 'Signed out',
    'Chưa đăng nhập': 'Not signed in',
    'Vui lòng đăng nhập': 'Please sign in',
    'Đăng nhập thành công!': 'Signed in successfully',
    'Đăng nhập để xem lịch học': 'Sign in to see your schedule',
    'Đăng nhập để xem lịch học của bạn': 'Sign in to see your schedule',
    'Chào mừng': 'Welcome',
    'Tên đăng nhập': 'Username',
    'Mật khẩu': 'Password',

    // ── Weather ──
    'Cảm giác': 'Feels like',
    'Độ ẩm': 'Humidity',
    'Gió': 'Wind',
    'Không tải được thời tiết.': 'Could not load the weather.',
    'Chạm để thử lại.': 'Tap to retry.',
    'Chào buổi sáng': 'Good morning',
    'Chào buổi trưa': 'Good afternoon',
    'Chào buổi chiều': 'Good afternoon',
    'Chào buổi tối': 'Good evening',
    'Sinh viên': 'Student',

    // ── Data & sync ──
    'Cập nhật dữ liệu': 'Refresh data',
    'Cập nhật ngay': 'Refresh now',
    'Đã cập nhật dữ liệu thành công': 'Data refreshed successfully',
    'Đã quá 30 ngày kể từ lần cập nhật cuối. Nên cập nhật dữ liệu mới':
        "It has been over 30 days since the last refresh. Updating is recommended",
    'Đang tải dữ liệu. Vui lòng không thoát ứng dụng.':
        'Loading data. Please keep the app open.',
    'Tải dữ liệu offline': 'Download for offline use',
    'Trạng thái dữ liệu offline': 'Offline data status',
    'Đã tải xong dữ liệu offline': 'Offline data downloaded',
    'Tiếp tục tải dữ liệu': 'Resume download',
    'Vui lòng đăng nhập để tải dữ liệu': 'Sign in to download your data',
    'Ứng dụng có thể hoạt động hoàn toàn offline':
        'The app works fully offline',
    'Lỗi tải dữ liệu': 'Could not load data',

    // ── Notifications ──
    'Thông báo lịch học': 'Class reminders',
    'Nhận thông báo trước giờ học và thi':
        'Get notified before classes and exams',
    'Không thể bật thông báo - cần cấp quyền':
        'Notifications need permission before they can be turned on',
    'Cần cấp quyền thông báo': 'Notification permission required',
    'Vui lòng cấp quyền thông báo trong cài đặt hệ thống để nhận thông báo':
        'Allow notifications in your system settings to receive reminders',
    'Mở cài đặt hệ thống': 'Open system settings',
    'Đã mở cài đặt - Vui lòng bật Thông báo':
        'Settings opened - please turn Notifications on',
    'Nhắc nhở hàng ngày': 'Daily summary',
    'Đã kích hoạt kiểm tra thủ công - Xem log để biết kết quả':
        'Manual check started - see the logs for the result',
    'Test ngay bây giờ': 'Run a test now',

    // ── Generic actions ──
    'Thử lại': 'Retry',
    'Tải lại': 'Reload',
    'Đóng': 'Close',
    'Huỷ': 'Cancel',
    'Hủy': 'Cancel',
    'Lưu': 'Save',
    'Xong': 'Done',
    'Xoá': 'Delete',
    'Xóa': 'Delete',
    'Tiếp tục': 'Continue',
    'Quay lại': 'Back',
    'Xem chi tiết': 'View details',
    'Đang tải...': 'Loading…',
    'Ngôn ngữ': 'Language',
    'Tiếng Việt': 'Vietnamese',
    'Tiếng Anh': 'English',
    'Giao diện tối': 'Dark mode',
    'lớp': 'classes',
  };

  /// English → Vietnamese, derived from [viToEn] plus the English-only strings
  /// that already exist in the codebase.
  static final Map<String, String> enToVi = {
    for (final e in viToEn.entries) e.value.toLowerCase(): e.key,
    'choose date': 'Chọn ngày',
    'continue': 'Tiếp tục',
    'cancel': 'Huỷ',
    'clear': 'Xoá',
    'clear logs?': 'Xoá toàn bộ log?',
    'this will delete all log entries.': 'Thao tác này sẽ xoá mọi bản ghi log.',
    'no logs yet': 'Chưa có log nào',
    'system logs': 'Nhật ký hệ thống',
    'logs copied to clipboard': 'Đã sao chép log vào bộ nhớ tạm',
  };

  static final Map<String, String> _viLookup = {
    for (final e in viToEn.entries) e.key.toLowerCase().trim(): e.value,
  };

  /// Returns the canonical translation of [text] into [target], or null when
  /// the string isn't one of ours and should go to the network translator.
  static String? lookup(String text, String target) {
    final key = text.toLowerCase().trim();
    final table = target == 'en' ? _viLookup : enToVi;
    return table[key];
  }
}
