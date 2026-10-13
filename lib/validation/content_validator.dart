/// コンテンツ検証（共通基盤設計 v0.5 §7「データ検証」「表現チェック」）。
///
/// 配信前のCIで実行する。Dartの `assert` はリリースビルドで無効になるため、
/// モデルのコンストラクタ制約とは別に、配信データそのものを独立して検証する。
library;

import '../experience/boundary_rule.dart';
import '../freshness.dart';
import '../genre.dart';
import '../glossary.dart';
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

/// [GlossaryTerm] 1件の検証。数値・施行日を持たないため出典・鮮度は必須に
/// していないが、定義文・例文に断定・勧誘表現が混じらないことを検証する。
List<ValidationIssue> validateGlossaryTerm(GlossaryTerm term) {
  final issues = <ValidationIssue>[];
  final contentId = term.id;

  issues.addAll(_scanTextFields(contentId, {'definition': term.definition}));
  if (term.example != null) {
    issues.addAll(_scanTextFields(contentId, {'example': term.example!}));
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

/// 同じIDを持つコンテンツが複数ないかを検出する（[idOf] でIDを取り出す）。
/// ファイル分割されたコンテンツを1件ずつ検証する [validateLesson] 等では
/// 検出できない、別ファイル間でのID重複（コピペ時のID変更漏れ等）を防ぐ。
List<ValidationIssue> _detectDuplicateIds<T>(
  List<T> items,
  String Function(T item) idOf,
  String label,
) {
  final issues = <ValidationIssue>[];
  final seen = <String>{};
  for (final item in items) {
    final id = idOf(item);
    if (!seen.add(id)) {
      issues.add(
        ValidationIssue(
          level: IssueLevel.error,
          contentId: id,
          message: '$labelのID「$id」が重複しています',
        ),
      );
    }
  }
  return issues;
}

/// コンテンツ全体の参照整合性チェック（[Lesson.ruleId]/[Lesson.calcId]/
/// [LessonCard.termRefs]・[Track.lessonIds] が実在するIDを指しているか、
/// および各コンテンツのIDが重複していないか）。
///
/// [validateLesson]/[validateBoundaryRule]/[validateGlossaryTerm] は1件単位の
/// 検証のため、他のコンテンツを参照する壊れたID（削除・リネーム漏れ等）や、
/// 別ファイル間でのID重複（コピペ時のID変更漏れ等）は検出できない。
/// 配信前CIでは必ずこちらも併せて実行すること。
///
/// [knownCalcIds] は choimana_core が知らない Calculator の `calcId` 一覧を
/// アプリ側（例: choimana_okane）から渡す。省略した場合、`calcId` のチェックは
/// 行わない（空集合を「存在しない」と区別できないため）。
///
/// [tracks] は省略可。渡した場合、各 [Track.lessonIds] が実在する
/// [Lesson.lessonId] を指しているかを検証する（[DailyPickSelector] が
/// 存在しない lessonId を静かに無視してしまうのを防ぐ）。
List<ValidationIssue> validateCrossReferences({
  required List<Lesson> lessons,
  required List<BoundaryRule> boundaryRules,
  required List<GlossaryTerm> glossaryTerms,
  Set<String>? knownCalcIds,
  List<Track> tracks = const [],
}) {
  final issues = <ValidationIssue>[];
  final ruleIds = boundaryRules.map((r) => r.ruleId).toSet();
  final termIds = glossaryTerms.map((t) => t.id).toSet();
  final lessonIds = lessons.map((l) => l.lessonId).toSet();

  issues.addAll(_detectDuplicateIds(lessons, (l) => l.lessonId, 'Lesson'));
  issues.addAll(_detectDuplicateIds(boundaryRules, (r) => r.ruleId, 'BoundaryRule'));
  issues.addAll(_detectDuplicateIds(glossaryTerms, (t) => t.id, 'GlossaryTerm'));
  issues.addAll(_detectDuplicateIds(tracks, (t) => t.trackId, 'Track'));

  for (final track in tracks) {
    for (final lessonId in track.lessonIds) {
      if (!lessonIds.contains(lessonId)) {
        issues.add(
          ValidationIssue(
            level: IssueLevel.error,
            contentId: track.trackId,
            message: 'lessonIds「$lessonId」に対応する Lesson が見つかりません',
          ),
        );
      }
    }
  }

  for (final lesson in lessons) {
    final contentId = lesson.lessonId;

    if (lesson.ruleId != null && !ruleIds.contains(lesson.ruleId)) {
      issues.add(
        ValidationIssue(
          level: IssueLevel.error,
          contentId: contentId,
          message: 'ruleId「${lesson.ruleId}」に対応する BoundaryRule が見つかりません',
        ),
      );
    }

    if (knownCalcIds != null &&
        lesson.calcId != null &&
        !knownCalcIds.contains(lesson.calcId)) {
      issues.add(
        ValidationIssue(
          level: IssueLevel.error,
          contentId: contentId,
          message: 'calcId「${lesson.calcId}」に対応する Calculator が見つかりません',
        ),
      );
    }

    for (final card in lesson.cards) {
      for (final termId in card.termRefs) {
        if (!termIds.contains(termId)) {
          issues.add(
            ValidationIssue(
              level: IssueLevel.warn,
              contentId: contentId,
              message:
                  'cards[${card.cardId}].termRefs「$termId」に対応する GlossaryTerm が見つかりません',
            ),
          );
        }
      }
    }
  }

  return issues;
}
