// The `programsubject/tree` endpoint answers in more than one shape. Only the
// nested one used to be understood; on the flat shape every course lost its
// knowledge block and the Chương trình đào tạo screen collapsed into a single
// "Khác" group. Block names below are the real ones captured from the portal.
import 'package:flutter_test/flutter_test.dart';
import 'package:tlustudy_planner/models/api_response.dart';

void main() {
  group('ProgramSubject.fromTree', () {
    test('nested shape: inner nodes are knowledge blocks', () {
      final tree = [
        {
          'name': 'Chuẩn đầu ra (Chứng chỉ)',
          'children': [
            {
              'subject': {
                'subjectCode': 'CDR.NN',
                'subjectName': 'Chuẩn đầu ra Ngoại ngữ',
                'numberOfCredit': 1,
              },
            },
            {
              'subject': {
                'subjectCode': 'OTCDR.NN',
                'subjectName': 'Ôn thi Chuẩn đầu ra Ngoại ngữ',
                'numberOfCredit': 2,
              },
            },
          ],
        },
        {
          'name': 'Kiến thức cơ sở ngành (Tự chọn)',
          'children': [
            {
              'subject': {
                'subjectCode': 'CSE441',
                'subjectName': 'Lập trình di động',
                'numberOfCredit': 3,
              },
            },
          ],
        },
      ];

      final subjects = ProgramSubject.fromTree(tree);

      expect(subjects, hasLength(3));
      expect(subjects.map((s) => s.knowledgeBlock).toSet(), {
        'Chuẩn đầu ra (Chứng chỉ)',
        'Kiến thức cơ sở ngành (Tự chọn)',
      });
      expect(totalProgramCredits(subjects), 6);
      // The requirement is read from the block label when no flag is present.
      expect(subjects.firstWhere((s) => s.subjectCode == 'CSE441').isRequired,
          isFalse);
      expect(subjects.firstWhere((s) => s.subjectCode == 'CDR.NN').isRequired,
          isTrue);
    });

    test('flat shape: each entry names its own block', () {
      final response = {
        'content': [
          {
            'subjectCode': 'GDQP321',
            'subjectName': 'Công tác quốc phòng và an ninh',
            'numberOfCredit': 2,
            'knowledgeBlock': 'Giáo dục quốc phòng an ninh (Chứng chỉ)',
          },
          {
            'subjectCode': 'MAT201',
            'subjectName': 'Giải tích 2',
            'numberOfCredit': 3,
            'subjectGroup': {'name': 'Kiến thức cơ bản (Bắt buộc)'},
          },
        ],
      };

      final subjects = ProgramSubject.fromTree(response);

      expect(subjects, hasLength(2));
      // The regression: these used to come back with an empty block, which the
      // provider then relabelled "Khác" for every single course.
      expect(subjects.every((s) => s.knowledgeBlock.isNotEmpty), isTrue);
      expect(
        subjects.firstWhere((s) => s.subjectCode == 'MAT201').knowledgeBlock,
        'Kiến thức cơ bản (Bắt buộc)',
      );
      expect(subjects.map((s) => s.knowledgeBlock).toSet(), hasLength(2));
    });

    test('flat shape: entries point at their block by parent id', () {
      final response = [
        {'id': 10, 'name': 'Kiến thức ngành (Bắt buộc)'},
        {
          'id': 11,
          'parentId': 10,
          'subjectCode': 'CSE310',
          'subjectName': 'Cấu trúc dữ liệu',
          'numberOfCredit': 3,
        },
        {
          'id': 12,
          'parent': {'id': 10},
          'subjectCode': 'CSE320',
          'subjectName': 'Cơ sở dữ liệu',
          'numberOfCredit': 3,
        },
      ];

      final subjects = ProgramSubject.fromTree(response);

      expect(subjects, hasLength(2));
      expect(
        subjects.every(
            (s) => s.knowledgeBlock == 'Kiến thức ngành (Bắt buộc)'),
        isTrue,
      );
    });

    test('a node that is both a heading and a course is not dropped', () {
      final tree = [
        {
          'name': 'Đồ án tốt nghiệp',
          'subjectCode': 'CSE499',
          'subjectName': 'Đồ án tốt nghiệp',
          'numberOfCredit': 10,
          'children': [
            {
              'subjectCode': 'CSE499A',
              'subjectName': 'Đồ án tốt nghiệp phần 1',
              'numberOfCredit': 5,
            },
          ],
        },
      ];

      final codes =
          ProgramSubject.fromTree(tree).map((s) => s.subjectCode).toSet();

      expect(codes, containsAll(<String>['CSE499', 'CSE499A']));
    });

    test('credits survive being sent as strings', () {
      final subjects = ProgramSubject.fromTree([
        {
          'subjectCode': 'BC111',
          'subjectName': 'Bóng chuyền 1',
          'numberOfCredit': '1',
          'knowledgeBlock': 'Giáo dục thể chất (Chứng chỉ)',
        },
      ]);

      expect(subjects.single.credits, 1);
    });

    test('blockTitle and category split the label for display', () {
      final subject = ProgramSubject.fromTree([
        {
          'subjectCode': 'X1',
          'subjectName': 'X',
          'numberOfCredit': 2,
          'knowledgeBlock': 'Kiến thức chuyên ngành (Tự chọn)',
        },
      ]).single;

      expect(subject.blockTitle, 'Kiến thức chuyên ngành');
      expect(subject.category, 'Tự chọn');
      expect(subject.isRequired, isFalse);
    });
  });
}
