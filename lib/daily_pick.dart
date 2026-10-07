import 'genre.dart';
import 'lesson.dart';
import 'srs.dart';

/// 今日のちょい（DailyPick: 今日の1レッスン＋復習1問）。
/// ホームの主役（共通基盤設計 v0.5 §4-3）。
class DailyPick {
  const DailyPick({required this.lesson, this.reviewQuiz});

  final Lesson lesson;

  /// SRS で復習時期が来た確認問題（なければ null）。
  final Quiz? reviewQuiz;
}

/// [DailyPick] の選び方。配信停止中のレッスンは除外する。
class DailyPickSelector {
  DailyPickSelector._();

  /// [tracks] の順序（Track.order→lessonIds の順）に沿って、
  /// [completedLessonIds] に含まれない最初のレッスンを選ぶ。
  /// 復習は [srsItems] のうち due のものの先頭から、[quizById] で問題を探す。
  static DailyPick? pick({
    required List<Track> tracks,
    required Map<String, Lesson> lessonsById,
    required Set<String> completedLessonIds,
    required List<SrsItem> srsItems,
    required Map<String, Quiz> quizById,
    required DateTime now,
  }) {
    final sortedTracks = [...tracks]..sort((a, b) => a.order.compareTo(b.order));

    Lesson? nextLesson;
    for (final track in sortedTracks) {
      for (final lessonId in track.lessonIds) {
        final lesson = lessonsById[lessonId];
        if (lesson == null) continue;
        if (completedLessonIds.contains(lessonId)) continue;
        if (!lesson.isDeliverableAt(now)) continue;
        nextLesson = lesson;
        break;
      }
      if (nextLesson != null) break;
    }
    if (nextLesson == null) return null;

    Quiz? reviewQuiz;
    for (final item in Srs.due(srsItems, now)) {
      final quiz = quizById[item.qid];
      if (quiz != null) {
        reviewQuiz = quiz;
        break;
      }
    }

    return DailyPick(lesson: nextLesson, reviewQuiz: reviewQuiz);
  }
}
