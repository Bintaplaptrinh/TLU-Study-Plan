import 'package:flutter_test/flutter_test.dart';
import 'package:tlustudy_planner/models/api_response.dart';

void main() {
  // Shape mirrors what programsubject/tree returns: inner nodes are knowledge
  // blocks, leaves carry the subject.
  final tree = {
    'content': [
      {
        'name': 'Kiến thức ngành (Bắt buộc)',
        'children': [
          {
            'subject': {
              'subjectCode': 'CSE441',
              'subjectName': 'Phân tích dữ liệu lớn',
              'numberOfCredit': 3,
            },
            'semester': '5',
          },
          {
            'subjectCode': 'CSE442',
            'subjectName': 'Quản trị mạng',
            'numberOfCredit': '2',
          },
        ],
      },
      {
        'name': 'Kiến thức tự chọn (Tự chọn)',
        'nodes': [
          {
            'subject': {
              'subjectCode': 'CSE500',
              'subjectName': 'Học máy',
              'numberOfCredit': 3,
            },
          },
        ],
      },
      {
        'name': 'Khối rỗng',
        'children': <dynamic>[],
      },
    ],
  };

  test('flattens tree, inherits block, parses credits from int and string', () {
    final subjects = ProgramSubject.fromTree(tree);

    expect(subjects.length, 3);

    final first = subjects[0];
    expect(first.subjectCode, 'CSE441');
    expect(first.subjectName, 'Phân tích dữ liệu lớn');
    expect(first.credits, 3);
    expect(first.semesterLabel, '5');
    expect(first.knowledgeBlock, 'Kiến thức ngành (Bắt buộc)');

    // Credits given as a string must still parse.
    expect(subjects[1].credits, 2);
    // Flat leaves (no nested `subject`) still resolve.
    expect(subjects[1].subjectCode, 'CSE442');
  });

  test('derives requirement and display fields from the block label', () {
    final subjects = ProgramSubject.fromTree(tree);

    expect(subjects[0].isRequired, isTrue);
    expect(subjects[0].category, 'Bắt buộc');
    expect(subjects[0].blockTitle, 'Kiến thức ngành');

    final elective = subjects[2];
    expect(elective.isRequired, isFalse);
    expect(elective.category, 'Tự chọn');
    expect(elective.blockTitle, 'Kiến thức tự chọn');
  });

  test('totals credits and tolerates a bare list root', () {
    expect(totalProgramCredits(ProgramSubject.fromTree(tree)), 8);
    expect(ProgramSubject.fromTree(tree['content']).length, 3);
    expect(ProgramSubject.fromTree(null), isEmpty);
    expect(ProgramSubject.fromTree(<dynamic>[]), isEmpty);
  });

  test('exam row survives fields moving between nesting levels', () {
    final nested = StudentExamRoom.fromJson({
      'id': 1,
      'subject': {'subjectName': 'Toán rời rạc'},
      'examPeriod': {'name': 'Học kỳ chính'},
      'examRoom': {
        'room': {'id': 9, 'code': 'A2-323', 'name': '323-A2'},
        'examCourseHour': {'id': 3, 'start': '07:00', 'endString': '08:40'},
      },
    });

    expect(nested.subjectName, 'Toán rời rạc');
    expect(nested.examPeriodCode, 'Học kỳ chính');
    // roomCode absent at the top level -> falls back to room.code
    expect(nested.examRoom!.roomCode, 'A2-323');
    expect(nested.examRoom!.examHour!.startString, '07:00');
  });
}
