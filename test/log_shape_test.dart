// _logShape is what turns "the screen is empty" into something diagnosable, so
// it must never throw on an unexpected payload. This exercises the same logic
// against every envelope the portal is known to use, plus the awkward cases.
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

/// Mirror of AuthService._logShape's inspection, returning the lines instead
/// of writing them to the log.
List<String> describe(String label, dynamic decoded) {
  final out = <String>[];
  try {
    String envelope;
    List<dynamic> rows;

    if (decoded is List) {
      envelope = 'mảng gốc';
      rows = decoded;
    } else if (decoded is Map) {
      String? listKey;
      for (final entry in decoded.entries) {
        if (entry.value is List) {
          listKey = entry.key.toString();
          break;
        }
      }
      envelope = listKey == null
          ? 'object: ${decoded.keys.take(12).join(", ")}'
          : 'object.$listKey';
      rows = listKey == null ? const [] : decoded[listKey] as List;
    } else {
      return ['$label: kiểu dữ liệu lạ ${decoded.runtimeType}'];
    }

    out.add('$label: envelope=$envelope, ${rows.length} bản ghi');
    final first = rows.isEmpty ? null : rows.first;
    if (first is Map) {
      out.add('$label: trường = ${first.keys.join(", ")}');
      for (final entry in first.entries) {
        if (entry.value is Map) {
          out.add('$label:   ${entry.key}.{ '
              '${(entry.value as Map).keys.take(15).join(", ")} }');
        }
      }
    } else if (rows.isNotEmpty) {
      out.add('$label: bản ghi đầu không phải object (${first.runtimeType})');
    }
  } catch (e) {
    out.add('$label: không đọc được cấu trúc: $e');
  }
  return out;
}

void main() {
  test('paginated envelope with nested objects', () {
    final lines = describe(
      'Điểm học phần',
      jsonDecode(jsonEncode({
        'content': [
          {
            'id': 1,
            'semester': {'id': 41, 'semesterName': '1_2023_2024'},
            'subject': {'subjectCode': 'BC111', 'subjectName': 'Bóng chuyền 1'},
            'mark': 7.2,
          }
        ],
        'totalElements': 46,
      })),
    );

    expect(lines.first, contains('envelope=object.content'));
    expect(lines.first, contains('1 bản ghi'));
    expect(lines[1], contains('semester'));
    // Nested keys matter: semester.id is what the semester filter compares.
    expect(lines.any((l) => l.contains('semester.{') && l.contains('id')),
        isTrue);
    expect(lines.any((l) => l.contains('subject.{')), isTrue);
  });

  test('bare array root', () {
    final lines = describe(
      'Điểm rèn luyện',
      jsonDecode(jsonEncode([
        {
          'schoolYear': {'name': '2023-2024'},
          'semesterBehaviorMarks': [
            {'semester': '1_2023_2024', 'mark': 77}
          ],
        }
      ])),
    );

    expect(lines.first, contains('envelope=mảng gốc'));
    expect(lines[1], contains('semesterBehaviorMarks'));
  });

  test('object with no list at all still reports its keys', () {
    final lines = describe('Học phí', jsonDecode('{"message":"no data"}'));
    expect(lines.first, contains('object: message'));
    expect(lines.first, contains('0 bản ghi'));
  });

  test('empty list does not throw', () {
    expect(describe('Học phí', <dynamic>[]).first, contains('0 bản ghi'));
  });

  test('list of scalars is reported, not crashed on', () {
    final lines = describe('Học phí', jsonDecode('[1,2,3]'));
    expect(lines.last, contains('không phải object'));
  });

  test('a bare scalar body is reported', () {
    expect(describe('Học phí', 42).first, contains('kiểu dữ liệu lạ'));
  });

  test('never throws, whatever it is handed', () {
    for (final payload in <dynamic>[
      null,
      'text',
      <dynamic>[],
      <String, dynamic>{},
      [<dynamic>[]],
      {'a': <dynamic>[]},
    ]) {
      expect(() => describe('X', payload), returnsNormally);
    }
  });
}
