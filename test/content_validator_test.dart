import 'package:choimana_core/experience/boundary_rule.dart';
import 'package:choimana_core/lesson.dart';
import 'package:choimana_core/src/source.dart';
import 'package:choimana_core/validation/content_validator.dart';
import 'package:test/test.dart';

Source _source() => Source(
      title: 't',
      url: 'https://example.com',
      publisher: 'p',
      retrievedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('validateLesson', () {
    test('問題なければエラーなし', () {
      final lesson = Lesson(
        lessonId: 'A-1',
        trackId: 'A',
        title: 't',
        minutes: 3,
        kind: LessonKind.basic,
        rank: LessonRank.low,
        cards: const [LessonCard(cardId: 'c1', text: '要点')],
        quiz: const [
          Quiz(qid: 'q1', type: QuizType.truefalse, stem: 's', answer: 'true', explain: 'e'),
          Quiz(qid: 'q2', type: QuizType.truefalse, stem: 's2', answer: 'true', explain: 'e2'),
        ],
        sources: [_source()],
        reviewedAt: DateTime(2026, 1, 1),
        contentVer: '1',
      );

      final issues = validateLesson(lesson, DateTime(2026, 1, 2));
      expect(issues, isEmpty);
    });

    test('禁止語をカード・確認問題から検出する', () {
      final lesson = Lesson(
        lessonId: 'A-1',
        trackId: 'A',
        title: 't',
        minutes: 3,
        kind: LessonKind.basic,
        rank: LessonRank.low,
        cards: const [LessonCard(cardId: 'c1', text: '必ず儲かる方法')],
        quiz: const [
          Quiz(qid: 'q1', type: QuizType.truefalse, stem: 's', answer: 'true', explain: 'おすすめです'),
          Quiz(qid: 'q2', type: QuizType.truefalse, stem: 's2', answer: 'true', explain: 'e2'),
        ],
        sources: [_source()],
        reviewedAt: DateTime(2026, 1, 1),
        contentVer: '1',
      );

      final issues = validateLesson(lesson, DateTime(2026, 1, 2));
      expect(issues.where((i) => i.level == IssueLevel.error).length, greaterThanOrEqualTo(3));
    });

    test('境界線レッスンに「目安」表示がないとエラー', () {
      final lesson = Lesson(
        lessonId: 'A-1',
        trackId: 'A',
        title: 't',
        minutes: 3,
        kind: LessonKind.boundary,
        rank: LessonRank.low,
        cards: const [LessonCard(cardId: 'c1', text: '扶養の境目')],
        quiz: const [
          Quiz(qid: 'q1', type: QuizType.truefalse, stem: 's', answer: 'true', explain: 'e'),
          Quiz(qid: 'q2', type: QuizType.truefalse, stem: 's2', answer: 'true', explain: 'e2'),
        ],
        sources: [_source()],
        reviewedAt: DateTime(2026, 1, 1),
        contentVer: '1',
      );

      final issues = validateLesson(lesson, DateTime(2026, 1, 2));
      expect(
        issues.any((i) => i.message.contains('目安')),
        isTrue,
      );
    });

    test('鮮度期限切れはエラー', () {
      final lesson = Lesson(
        lessonId: 'A-1',
        trackId: 'A',
        title: 't',
        minutes: 3,
        kind: LessonKind.basic,
        rank: LessonRank.low,
        cards: const [LessonCard(cardId: 'c1', text: '要点')],
        quiz: const [
          Quiz(qid: 'q1', type: QuizType.truefalse, stem: 's', answer: 'true', explain: 'e'),
          Quiz(qid: 'q2', type: QuizType.truefalse, stem: 's2', answer: 'true', explain: 'e2'),
        ],
        sources: [_source()],
        reviewedAt: DateTime(2020, 1, 1),
        contentVer: '1',
      );

      final issues = validateLesson(lesson, DateTime(2026, 1, 1));
      expect(
        issues.any((i) => i.level == IssueLevel.error && i.message.contains('配信できません')),
        isTrue,
      );
    });
  });

  group('validateBoundaryRule', () {
    test('出典・施行日があれば問題なし', () {
      final rule = BoundaryRule(
        ruleId: 'r1',
        title: 't',
        conditions: const [
          BoundaryCondition(conditionId: 'c', label: 'l', trueLabel: 't', falseLabel: 'f'),
        ],
        outcomes: const [
          BoundaryOutcome(conditionValues: {'c': true}, conclusion: '結論（目安）', basis: '根拠'),
        ],
        sources: [_source()],
        lawVersion: 'v1',
        reviewedAt: DateTime(2026, 1, 1),
        contentVer: '1',
      );

      expect(validateBoundaryRule(rule, DateTime(2026, 1, 2)), isEmpty);
    });

    test('結論に優劣表現があればエラー', () {
      final rule = BoundaryRule(
        ruleId: 'r1',
        title: 't',
        conditions: const [
          BoundaryCondition(conditionId: 'c', label: 'l', trueLabel: 't', falseLabel: 'f'),
        ],
        outcomes: const [
          BoundaryOutcome(conditionValues: {'c': true}, conclusion: '一番良い（目安）', basis: '根拠'),
        ],
        sources: [_source()],
        lawVersion: 'v1',
        reviewedAt: DateTime(2026, 1, 1),
        contentVer: '1',
      );

      final issues = validateBoundaryRule(rule, DateTime(2026, 1, 2));
      expect(issues.any((i) => i.message.contains('一番良い')), isTrue);
    });
  });
}
