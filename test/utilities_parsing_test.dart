// Field mappings for the Tiện ích screens, locked against the shapes the TLU
// portal actually returns (captured from a live account). Every structure
// below - nesting, the misspellings, the object-where-a-string-was-expected -
// is copied from real responses.
import 'package:flutter_test/flutter_test.dart';
import 'package:tlustudy_planner/models/api_response.dart';

void main() {
  group('StudentSubjectMark', () {
    // GET /api/studentsubjectmark/getListStudentMarkBySemesterByLoginUser/{id}
    final row = {
      'id': 12345,
      'studentId': 999,
      'subjectId': 77,
      'semesterId': 14,
      'mark': 7.2,
      'mark4': 3.0,
      'charMark': 'B',
      'markQT': 6.0,
      'markTHI': 8.0,
      'examRound': 1,
      'studyTime': 1,
      'isCounted': true,
      'isPublished': true,
      'result': 'ĐẠT',
      'subject': {
        'subjectCode': 'BC111',
        'subjectName': 'Bóng chuyền 1',
        'numberOfCredit': 1,
      },
      'semester': {'id': 14, 'semesterName': '2_2025_2026'},
    };

    test('reads the nested subject and semester', () {
      final m = StudentSubjectMark.fromJson(Map<String, dynamic>.from(row));

      // The old model read these as flat fields and got empty strings.
      expect(m.subjectCode, 'BC111');
      expect(m.subjectName, 'Bóng chuyền 1');
      expect(m.credits, 1);
      expect(m.semesterId, 14);
      expect(m.semesterName, '2_2025_2026');
      expect(m.mark10, 7.2);
      expect(m.mark4, 3.0);
      expect(m.markLetter, 'B');
      expect(m.markProcess, 6.0);
      expect(m.markExam, 8.0);
      expect(m.isPassed, isTrue);
    });

    test('survives a round-trip through the cache', () {
      final original = StudentSubjectMark.fromJson(
        Map<String, dynamic>.from(row),
      );
      final restored = StudentSubjectMark.fromCache(original.toJson());

      expect(restored.subjectCode, original.subjectCode);
      expect(restored.credits, original.credits);
      expect(restored.mark4, original.mark4);
      expect(restored.semesterName, original.semesterName);
      expect(restored.isPassed, original.isPassed);
    });

    test('an F is not a pass', () {
      final failed = StudentSubjectMark.fromJson({
        ...row,
        'charMark': 'F',
        'mark': 2.0,
        'mark4': 0.0,
        'result': 'KHÔNG ĐẠT',
      });
      expect(failed.isPassed, isFalse);
    });
  });

  group('StudentBehaviorMark', () {
    // The response is one object; semesters are two levels down.
    final response = {
      'id': 1,
      'mark': 78.5,
      'classication': 5, // the portal's own misspelling, and it is a number
      'schoolYearBehaviorMarks': [
        {
          'id': 10,
          'schoolYear': {'name': '2023-2024'},
          'mark': 78.5,
          'semesterMarks': [
            {
              'id': 201590,
              'mark': 77.0,
              'sort': 'Khá', // the readable grade lives here
              'code': '2.3', // a criteria number, NOT the semester
              'level': 4,
              'classification': {'id': 163, 'classificationName': ''},
              'semester': {'id': 9, 'semesterName': '1_2023_2024'},
            },
            {
              'id': 201591,
              'mark': 80.0,
              'sort': 'Tốt',
              'semester': {'id': 10, 'semesterName': '2_2023_2024'},
            },
          ],
        },
      ],
    };

    test('flattens to one row per semester', () {
      final rows = StudentBehaviorMark.listFromResponse(response);

      expect(rows, hasLength(2));
      // Newest first.
      expect(rows.first.semesterId, 10);
      expect(rows.first.semesterName, '2_2023_2024');
      expect(rows.first.mark, 80);
      expect(rows.first.classification, 'Tốt');
      expect(rows.first.schoolYearName, '2023-2024');
    });

    test('never renders the classification object or the criteria code', () {
      final row = StudentBehaviorMark.listFromResponse(
        response,
      ).firstWhere((r) => r.semesterId == 9);

      expect(row.classification, 'Khá');
      // Regressions to guard: dumping the map, or using code "2.3".
      expect(row.classification, isNot(contains('{')));
      expect(row.semesterName, isNot('2.3'));
      expect(row.semesterName, '1_2023_2024');
    });

    test('falls back to the standard bands when no label is sent', () {
      final rows = StudentBehaviorMark.listFromResponse({
        'schoolYearBehaviorMarks': [
          {
            'schoolYear': {'name': '2025-2026'},
            'semesterMarks': [
              {
                'mark': 91,
                'semester': {'id': 1},
              },
              {
                'mark': 70,
                'semester': {'id': 2},
              },
              {
                'mark': 40,
                'semester': {'id': 3},
              },
            ],
          },
        ],
      });
      final byId = {for (final r in rows) r.semesterId: r.classification};
      expect(byId[1], 'Xuất sắc');
      expect(byId[2], 'Khá');
      expect(byId[3], 'Yếu');
    });

    test('an empty response is not an error', () {
      expect(StudentBehaviorMark.listFromResponse(null), isEmpty);
      expect(
        StudentBehaviorMark.listFromResponse(<String, dynamic>{}),
        isEmpty,
      );
    });
  });

  group('StudentTuition', () {
    // GET /api/student/viewstudentpayablebyLoginUser - a summary object with
    // two lists, not the flat list the old model expected.
    final response = {
      'totalReceiveAble': 53590000.0,
      'totalReceived': 53590000.0,
      'totalReceiveAbleNotComplete': 0.0,
      'receiveAbleDtos': [
        {
          'id': 1,
          'amount': 4650000.0,
          'amountReceived': 4650000.0,
          'semester': {'semesterName': '1_2023_2024'},
        },
        {
          'id': 2,
          'amount': 5625000.0,
          'amountReceived': 0.0,
          'semester': {'semesterName': '2_2023_2024'},
        },
      ],
      'receivedDtos': [
        {
          'id': 9,
          'totalRecivedAmount': 5000000.0, // note the portal's spelling
          'voucherDate': '28/08/2023',
          'semester': {'semesterName': '1_2023_2024'},
        },
      ],
    };

    test('splits fees from receipts and keeps the totals', () {
      final t = StudentTuition.fromJson(Map<String, dynamic>.from(response));

      expect(t.isEmpty, isFalse);
      expect(t.fees, hasLength(2));
      expect(t.payments, hasLength(1));
      expect(t.totalReceivable, 53590000.0);
      expect(t.totalReceived, 53590000.0);
      expect(t.totalOutstanding, 0.0);
      expect(t.fees.first.semesterName, '1_2023_2024');
      expect(t.payments.first.amount, 5000000.0);
      expect(t.payments.first.isPayment, isTrue);
    });

    test('outstanding is per fee, never negative', () {
      final t = StudentTuition.fromJson(Map<String, dynamic>.from(response));
      expect(t.fees[0].outstanding, 0.0);
      expect(t.fees[1].outstanding, 5625000.0);
    });

    test('survives a round-trip through the cache', () {
      final t = StudentTuition.fromJson(Map<String, dynamic>.from(response));
      final restored = StudentTuition.fromCache(t.toJson());

      expect(restored.fees, hasLength(2));
      expect(restored.payments, hasLength(1));
      expect(restored.totalReceivable, t.totalReceivable);
      expect(restored.fees[1].outstanding, 5625000.0);
    });

    test('a response with no lists is empty, not a crash', () {
      final t = StudentTuition.fromJson({'totalReceiveAble': 0});
      expect(t.isEmpty, isTrue);
    });
  });

  group('ProgramSubject.fromTree - the real flat shape', () {
    // programsubject/tree returns 92 nodes, all root, none with children.
    final content = [
      {
        'id': 1,
        'root': true,
        'subjectType': 1,
        'displaySubjectCode': 'BOI111',
        'displaySubjectName': 'Bơi',
        'subject': {
          'subjectCode': 'BOI111',
          'subjectName': 'Bơi',
          'numberOfCredit': 1,
        },
        'knowledgeProgram': {
          'blockType': 3,
          'knowledgeBlock': {'name': 'Giáo dục thể chất'},
        },
      },
      {
        'id': 2,
        'root': true,
        'subjectType': 2,
        'semesterIndex': 5,
        'subject': {
          'subjectCode': 'CSE441',
          'subjectName': 'Lập trình di động',
          'numberOfCredit': 3,
        },
        'knowledgeProgram': {
          'blockType': 2,
          'knowledgeBlock': {'name': 'Kiến thức tự chọn'},
        },
      },
      {
        'id': 3,
        'root': true,
        'subject': {
          'subjectCode': 'MAT201',
          'subjectName': 'Giải tích 2',
          'numberOfCredit': 3,
        },
        'knowledgeProgram': {
          'blockType': 1,
          'knowledgeBlock': {'name': 'Khoa học tự nhiên và tin học'},
        },
      },
    ];

    test('resolves the block from knowledgeProgram.knowledgeBlock.name', () {
      final subjects = ProgramSubject.fromTree({'content': content});

      expect(subjects, hasLength(3));
      // The regression: every one of these used to land in "Khác".
      expect(subjects.every((s) => s.knowledgeBlock.isNotEmpty), isTrue);
      expect(subjects.map((s) => s.knowledgeBlock).toSet(), {
        'Giáo dục thể chất',
        'Kiến thức tự chọn',
        'Khoa học tự nhiên và tin học',
      });
      expect(totalProgramCredits(subjects), 7);
    });

    test('blockType 2 means elective, 1 and 3 do not', () {
      final byCode = {
        for (final s in ProgramSubject.fromTree({'content': content}))
          s.subjectCode: s,
      };

      expect(byCode['CSE441']!.isRequired, isFalse);
      expect(byCode['BOI111']!.isRequired, isTrue);
      expect(byCode['MAT201']!.isRequired, isTrue);
    });

    test('semesterIndex becomes the term label', () {
      final s = ProgramSubject.fromTree({
        'content': content,
      }).firstWhere((s) => s.subjectCode == 'CSE441');
      expect(s.semesterLabel, '5');
    });
  });
}
