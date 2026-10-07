import 'package:choimana_kit/lesson.dart';
import 'package:choimana_kit/src/source.dart';
import 'package:test/test.dart';

Lesson _buildLesson({DateTime? reviewedAt, LessonRank rank = LessonRank.low}) {
  return Lesson(
    lessonId: 'A-1',
    trackId: 'A',
    title: '給与明細の「引かれるもの」を読む',
    minutes: 3,
    kind: LessonKind.reverse,
    rank: rank,
    cards: const [LessonCard(cardId: 'c1', text: '要点1')],
    quiz: const [
      Quiz(
        qid: 'q1',
        type: QuizType.choice,
        stem: 'どれ？',
        choices: ['a', 'b'],
        answer: '0',
        explain: '説明',
      ),
      Quiz(
        qid: 'q2',
        type: QuizType.truefalse,
        stem: '正しい？',
        answer: 'true',
        explain: '説明2',
      ),
    ],
    sources: [
      Source(
        title: '出典',
        url: 'https://example.com',
        publisher: '国税庁',
        retrievedAt: DateTime(2026, 1, 1),
      ),
    ],
    reviewedAt: reviewedAt ?? DateTime(2026, 1, 1),
    contentVer: '1',
  );
}

void main() {
  group('Lesson', () {
    test('制約: 3分以内・要点3枚以内・確認問題2〜3問・出典必須', () {
      expect(() => _buildLesson(), returnsNormally);
    });

    test('低ランクは180日超で配信停止', () {
      final lesson = _buildLesson(reviewedAt: DateTime(2026, 1, 1));
      final farFuture = DateTime(2026, 1, 1).add(const Duration(days: 200));
      expect(lesson.isDeliverableAt(farFuture), isFalse);
    });

    test('高ランクは60日超で配信停止（法令系）', () {
      final lesson = _buildLesson(
        reviewedAt: DateTime(2026, 1, 1),
        rank: LessonRank.high,
      );
      final after61 = DateTime(2026, 1, 1).add(const Duration(days: 61));
      expect(lesson.isDeliverableAt(after61), isFalse);
      final after59 = DateTime(2026, 1, 1).add(const Duration(days: 59));
      expect(lesson.isDeliverableAt(after59), isTrue);
    });

    test('JSON往復', () {
      final lesson = _buildLesson();
      final restored = Lesson.fromJson(lesson.toJson());
      expect(restored.lessonId, lesson.lessonId);
      expect(restored.quiz.length, 2);
      expect(restored.sources.single.publisher, '国税庁');
    });
  });
}
