import 'package:choimana_core/daily_pick.dart';
import 'package:choimana_core/genre.dart';
import 'package:choimana_core/lesson.dart';
import 'package:choimana_core/src/source.dart';
import 'package:choimana_core/srs.dart';
import 'package:test/test.dart';

Lesson _lesson(String id, {DateTime? reviewedAt}) => Lesson(
      lessonId: id,
      trackId: 'A',
      title: id,
      minutes: 3,
      kind: LessonKind.basic,
      rank: LessonRank.low,
      cards: const [LessonCard(cardId: 'c1', text: '要点')],
      quiz: const [
        Quiz(qid: 'q1', type: QuizType.truefalse, stem: 's', answer: 'true', explain: 'e'),
        Quiz(qid: 'q2', type: QuizType.truefalse, stem: 's2', answer: 'true', explain: 'e2'),
      ],
      sources: [
        Source(
          title: 't',
          url: 'https://example.com',
          publisher: 'p',
          retrievedAt: DateTime(2026, 1, 1),
        ),
      ],
      reviewedAt: reviewedAt ?? DateTime(2026, 1, 1),
      contentVer: '1',
    );

void main() {
  test('未完了の最初のレッスンを選ぶ', () {
    final track = const Track(
      trackId: 'A',
      genreId: 'money',
      name: 'トラックA',
      order: 1,
      lessonIds: ['A-1', 'A-2'],
    );
    final lessons = {'A-1': _lesson('A-1'), 'A-2': _lesson('A-2')};

    final pick = DailyPickSelector.pick(
      tracks: [track],
      lessonsById: lessons,
      completedLessonIds: {'A-1'},
      srsItems: const [],
      quizById: const {},
      now: DateTime(2026, 1, 2),
    );

    expect(pick!.lesson.lessonId, 'A-2');
    expect(pick.reviewQuiz, isNull);
  });

  test('配信停止中のレッスンはスキップする', () {
    final track = const Track(
      trackId: 'A',
      genreId: 'money',
      name: 'トラックA',
      order: 1,
      lessonIds: ['A-1', 'A-2'],
    );
    final stale = _lesson('A-1', reviewedAt: DateTime(2020, 1, 1));
    final lessons = {'A-1': stale, 'A-2': _lesson('A-2')};

    final pick = DailyPickSelector.pick(
      tracks: [track],
      lessonsById: lessons,
      completedLessonIds: {},
      srsItems: const [],
      quizById: const {},
      now: DateTime(2026, 1, 2),
    );

    expect(pick!.lesson.lessonId, 'A-2');
  });

  test('復習期日が来た問題を一緒に出す', () {
    final track = const Track(
      trackId: 'A',
      genreId: 'money',
      name: 'トラックA',
      order: 1,
      lessonIds: ['A-1'],
    );
    final lesson = _lesson('A-1');
    const quiz = Quiz(qid: 'q1', type: QuizType.truefalse, stem: 's', answer: 'true', explain: 'e');
    final due = SrsItem(qid: 'q1', box: 1, dueAt: DateTime(2026, 1, 1));

    final pick = DailyPickSelector.pick(
      tracks: [track],
      lessonsById: {'A-1': lesson},
      completedLessonIds: {},
      srsItems: [due],
      quizById: const {'q1': quiz},
      now: DateTime(2026, 1, 2),
    );

    expect(pick!.reviewQuiz!.qid, 'q1');
  });
}
