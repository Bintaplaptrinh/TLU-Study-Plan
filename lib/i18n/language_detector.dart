/// Decides whether a runtime string is Vietnamese or English.
///
/// The app never ships translation keys — it translates whatever text reaches
/// the widget tree. So before translating we have to know what we're looking
/// at: text already in the target language must be left completely alone.
class LanguageDetector {
  LanguageDetector._();

  /// Characters that only ever appear in Vietnamese.
  static final RegExp _vietnameseDiacritics = RegExp(
    r'[àáảãạăằắẳẵặâầấẩẫậđèéẻẽẹêềếểễệ'
    r'ìíỉĩịòóỏõọôồốổỗộơờớởỡợ'
    r'ùúủũụưừứửữựỳýỷỹỵ]',
    caseSensitive: false,
  );

  /// Common Vietnamese words that carry no diacritics, so diacritic-spotting
  /// alone would miss them ("Thu Hang", "Lich thi", "Phong A2"…).
  static const Set<String> _vietnameseStopWords = {
    'va', 'cua', 'cho', 'khong', 'co', 'la', 'trong', 'ngay', 'thang', 'nam',
    'gio', 'phut', 'lop', 'hoc', 'thi', 'tiet', 'phong', 'toa', 'nha', 'tuan',
    'sinh', 'vien', 'giang', 'day', 'mon', 'diem', 'ky', 'hoc_ky', 'dang',
    'nhap', 'cai', 'dat', 'tien', 'ich', 'lich', 'hom', 'nay', 'mai', 'chao',
    'buoi', 'sang', 'trua', 'chieu', 'toi', 'xem', 'chon', 'luu', 'huy', 'dong',
  };

  /// Frequent English function words. Their presence is strong evidence the
  /// string is English, since Vietnamese rarely borrows them.
  static const Set<String> _englishStopWords = {
    'the', 'and', 'for', 'you', 'your', 'with', 'from', 'this', 'that', 'have',
    'has', 'are', 'was', 'were', 'will', 'not', 'can', 'all', 'any', 'please',
    'today', 'tomorrow', 'week', 'month', 'year', 'class', 'classes', 'exam',
    'exams', 'schedule', 'settings', 'login', 'logout', 'room', 'building',
    'teacher', 'student', 'save', 'cancel', 'close', 'retry', 'loading',
  };

  static final RegExp _wordSplitter = RegExp(r'[^a-zA-ZÀ-ỹ]+');

  /// Text with no letters at all — "07:00 – 09:25", "25/8/2026", "3" — carries
  /// no language and must never be sent to a translator.
  static bool isTranslatable(String text) {
    if (text.trim().length < 2) return false;
    return RegExp(r'[a-zA-ZÀ-ỹ]{2,}').hasMatch(text);
  }

  /// 'vi' or 'en'. Falls back to [fallback] when the evidence is inconclusive.
  static String detect(String text, {String fallback = 'vi'}) {
    if (_vietnameseDiacritics.hasMatch(text)) return 'vi';

    final words = text
        .toLowerCase()
        .split(_wordSplitter)
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return fallback;

    var vi = 0;
    var en = 0;
    for (final w in words) {
      if (_vietnameseStopWords.contains(w)) vi++;
      if (_englishStopWords.contains(w)) en++;
    }

    if (en > vi) return 'en';
    if (vi > en) return 'vi';
    return fallback;
  }
}
