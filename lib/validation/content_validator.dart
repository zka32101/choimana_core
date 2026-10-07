/// コンテンツ検証（共通基盤設計 v0.5 §7「データ検証」「表現チェック」）。
///
/// 配信前のCIで実行する。Dartの `assert` はリリースビルドで無効になるため、
/// モデルのコンストラクタ制約とは別に、配信データそのものを独立して検証する。
library;

import '../experience/boundary_rule.dart';
import '../freshness.dart';
import '../lesson.dart';
import 'forbidden_words.dart';

enum IssueLevel { error, warn }

class ValidationIssue {
  const ValidationIssue({
    required this.level,
    required this.contentId,
    required this.message,
  });

  final IssueLevel level;
  final String contentId;
  final String message;

  @override
  String toString() =>
      '[${level == IssueLevel.error ? "ERROR" : "WARN"}] $contentId: $message';
}

List<ValidationIssue> _scanTextFields(
  String contentId,
  Map<String, String> fields,
) {
  final issues = <ValidationIssue>[];
  for (final entry in fields.entries) {
    for (final hit in scanForbiddenWords(entry.value)) {
      issues.add(
        ValidationIssue(
          level: IssueLevel.error,
          contentId: contentId,
          message: '禁止語「${hit.word}」を検出（${entry.key}）: ${hit.reason}',
        ),
      );
    }
  }
  return issues;
}

/// [Lesson] 1件の検証。[now] は鮮度判定の基準時刻。
List<ValidationIssue> validateLesson(Lesson lesson, DateTime now) {
  final issues = <ValidationIssue>[];
  final contentId = lesson.lessonId;

  if (lesson.sources.isEmpty) {
    issues.add(
      ValidationIssue(level: IssueLevel.error, contentId: contentId, message: '出典が必須です'),
    );
  }
  if (lesson.minutes > 3) {
    issues.add(
      ValidationIssue(
        level: IssueLevel.error,
        contentId: contentId,
        message: 'レッスンは3分以内にする必要があります（minutes=${lesson.minutes}）',
      ),
    );
  }
  if (lesson.cards.length > 3) {
    issues.add(
      ValidationIssue(
        level: IssueLevel.error,
        contentId: contentId,
        message: '要点カードは3枚以内にする必要があります（${lesson.cards.length}枚）',
      ),
    );
  }
  if (lesson.quiz.length < 2 || lesson.quiz.length > 3) {
    issues.add(
      ValidationIssue(
        level: IssueLevel.error,
        contentId: contentId,
        message: '確認問題は2〜3問にする必要があります（${lesson.quiz.length}問）',
      ),
    );
  }

  for (var i = 0; i < lesson.cards.length; i++) {
    issues.addAll(_scanTextFields(contentId, {'cards[$i].text': lesson.cards[i].text}));
  }
  for (var i = 0; i < lesson.quiz.length; i++) {
    final q = lesson.quiz[i];
    issues.addAll(
      _scanTextFields(contentId, {'quiz[$i].stem': q.stem, 'quiz[$i].explain': q.explain}),
    );
  }
  if (lesson.action != null) {
    issues.addAll(_scanTextFields(contentId, {'action.text': lesson.action!.text}));
  }

  if (lesson.kind == LessonKind.boundary || lesson.kind == LessonKind.predict) {
    final hasMiyasuNote = lesson.cards.any((c) => c.text.contains('目安')) ||
        lesson.quiz.any((q) => q.explain.contains('目安'));
    if (!hasMiyasuNote) {
      issues.add(
        ValidationIssue(
          level: IssueLevel.error,
          contentId: contentId,
          message: '境界線・予測→実行のレッスンには「目安」表示が必要です',
        ),
      );
    }
  }

  final status = lesson.freshnessStatusAt(now);
  if (status == FreshnessStatus.stopped) {
    issues.add(
      ValidationIssue(
        level: IssueLevel.error,
        contentId: contentId,
        message: '鮮度が期限（${lesson.freshnessPolicy.stopAfterDays}日）を超えており配信できません'
            '（reviewedAt: ${lesson.reviewedAt.toIso8601String()}）',
      ),
    );
  } else if (status == FreshnessStatus.notice) {
    issues.add(
      ValidationIssue(
        level: IssueLevel.warn,
        contentId: contentId,
        message: '「情報が古い可能性があります」表示の対象です',
      ),
    );
  } else if (status == FreshnessStatus.warn) {
    issues.add(
      ValidationIssue(level: IssueLevel.warn, contentId: contentId, message: '鮮度の見直し時期が近づいています'),
    );
  }

  return issues;
}

/// [BoundaryRule] 1件の検証。
List<ValidationIssue> validateBoundaryRule(BoundaryRule rule, DateTime now) {
  final issues = <ValidationIssue>[];
  final contentId = rule.ruleId;

  if (rule.sources.isEmpty) {
    issues.add(
      ValidationIssue(level: IssueLevel.error, contentId: contentId, message: '出典が必須です'),
    );
  }
  if (rule.lawVersion.trim().isEmpty) {
    issues.add(
      ValidationIssue(
        level: IssueLevel.error,
        contentId: contentId,
        message: '施行日（lawVersion）が必須です',
      ),
    );
  }
  if (!rule.note.contains('目安')) {
    issues.add(
      ValidationIssue(
        level: IssueLevel.error,
        contentId: contentId,
        message: '結論には「目安」の注記が必要です',
      ),
    );
  }

  for (var i = 0; i < rule.outcomes.length; i++) {
    final o = rule.outcomes[i];
    issues.addAll(
      _scanTextFields(contentId, {'outcomes[$i].conclusion': o.conclusion, 'outcomes[$i].basis': o.basis}),
    );
  }

  final status = rule.freshnessStatusAt(now);
  if (status == FreshnessStatus.stopped) {
    issues.add(
      ValidationIssue(
        level: IssueLevel.error,
        contentId: contentId,
        message: '鮮度が期限を超えており配信できません（reviewedAt: ${rule.reviewedAt.toIso8601String()}）',
      ),
    );
  } else if (status == FreshnessStatus.notice || status == FreshnessStatus.warn) {
    issues.add(
      ValidationIssue(level: IssueLevel.warn, contentId: contentId, message: '鮮度の見直し時期が近づいています'),
    );
  }

  return issues;
}
