import 'package:flutter/material.dart';

/// Mã vạch Code 128 (bộ ký tự B) vẽ thẳng bằng [CustomPainter].
///
/// Tự vẽ thay vì thêm thư viện: bảng mã Code 128 chỉ là 103 hằng số, còn thêm
/// một package chỉ để in mấy vạch đen thì phải kéo theo cả phần sinh QR,
/// DataMatrix, PDF417 không bao giờ dùng tới.
class StudentBarcode extends StatelessWidget {
  const StudentBarcode({
    super.key,
    required this.data,
    this.height = 58,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  });

  /// Chuỗi cần mã hoá - ở đây là mã số sinh viên.
  final String data;

  /// Chiều cao phần vạch, chưa tính [padding].
  final double height;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final modules = _encodeCode128B(data.trim());
    if (modules.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        // Nền trắng cố định kể cả ở chế độ tối: máy quét cần nền sáng, vạch
        // tối - đảo màu là không đọc được.
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _BarcodePainter(modules)),
      ),
    );
  }
}

/// Mẫu vạch của 103 giá trị Code 128, mỗi mẫu là 11 mô-đun đọc từ bit thấp.
const List<int> _code128Patterns = [
  0x19b, 0x1b3, 0x333, 0x0c9, 0x189, 0x191, 0x099, 0x119,
  0x131, 0x093, 0x113, 0x123, 0x1cd, 0x1d9, 0x399, 0x19d,
  0x1b9, 0x339, 0x273, 0x1d3, 0x393, 0x13b, 0x173, 0x3b7,
  0x197, 0x1a7, 0x327, 0x137, 0x167, 0x267, 0x0db, 0x31b,
  0x363, 0x0c5, 0x0d1, 0x311, 0x08d, 0x0b1, 0x231, 0x08b,
  0x0a3, 0x223, 0x0ed, 0x38d, 0x3b1, 0x0dd, 0x31d, 0x371,
  0x377, 0x38b, 0x3a3, 0x0bb, 0x23b, 0x3bb, 0x0d7, 0x317,
  0x347, 0x0b7, 0x237, 0x2c7, 0x2f7, 0x213, 0x28f, 0x065,
  0x185, 0x069, 0x309, 0x1a1, 0x321, 0x04d, 0x10d, 0x059,
  0x219, 0x161, 0x261, 0x243, 0x053, 0x2ef, 0x143, 0x2f1,
  0x1e5, 0x1e9, 0x3c9, 0x13d, 0x179, 0x279, 0x12f, 0x14f,
  0x24f, 0x3db, 0x37b, 0x36f, 0x0f5, 0x3c5, 0x3d1, 0x0bd,
  0x23d, 0x0af, 0x22f, 0x3dd, 0x3bd, 0x3d7, 0x3af,
];

const int _startCodeB = 0x4b;
const int _stop = 0x2e3;
const int _startCodeBValue = 104;

/// Chuỗi ASCII in được → danh sách mô-đun (true = vạch đen).
///
/// Trả về danh sách rỗng nếu chuỗi trống hoặc có ký tự nằm ngoài bảng B - thà
/// không hiện gì còn hơn hiện một mã vạch quét ra sai.
List<bool> _encodeCode128B(String data) {
  if (data.isEmpty) return const [];

  final values = <int>[];
  for (final unit in data.codeUnits) {
    if (unit < 32 || unit > 126) return const [];
    values.add(unit - 32);
  }

  // Ký tự Start tính trọng số 1, các ký tự sau tính theo vị trí 1, 2, 3...
  var sum = _startCodeBValue;
  for (var i = 0; i < values.length; i++) {
    sum += values[i] * (i + 1);
  }

  final modules = <bool>[];
  void emit(int pattern) {
    for (var i = 0; i < 11; i++) {
      modules.add((pattern >> i) & 1 == 1);
    }
  }

  emit(_startCodeB);
  for (final value in values) {
    emit(_code128Patterns[value]);
  }
  emit(_code128Patterns[sum % 103]);
  emit(_stop);
  // Hai vạch kết thúc của Code 128.
  modules.addAll(const [true, true]);

  return modules;
}

class _BarcodePainter extends CustomPainter {
  const _BarcodePainter(this.modules);

  final List<bool> modules;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / modules.length;
    final paint = Paint()..color = const Color(0xFF0B1220);

    // Gộp các mô-đun đen liền nhau thành một hình chữ nhật: ít lệnh vẽ hơn và
    // không để lộ khe trắng do làm tròn pixel giữa hai vạch sát nhau.
    var start = -1;
    for (var i = 0; i <= modules.length; i++) {
      final dark = i < modules.length && modules[i];
      if (dark && start < 0) start = i;
      if (!dark && start >= 0) {
        canvas.drawRect(
          Rect.fromLTRB(start * unit, 0, i * unit, size.height),
          paint,
        );
        start = -1;
      }
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter oldDelegate) =>
      oldDelegate.modules != modules;
}
