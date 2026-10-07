import 'freshness.dart';
import 'src/json_util.dart';
import 'src/source.dart';

/// レッスンの型（共通基盤設計 v0.5 §3b・§5）。
enum LessonKind {
  basic,
  predict,
  boundary,
  timeline,
  reason,
  reverse,
  fix,
  order,
  caseStudy,
  lab,
}

/// 変わりやすさ・法令への近さによる鮮度ランク（v0.5 §6-2 の停止ルール表）。
enum LessonRank { high, mid, low }

extension LessonRankFreshness on LessonRank {
  FreshnessPolicy get freshnessPolicy => switch (this) {
        LessonRank.high => FreshnessPolicy.lessonHigh,
        LessonRank.mid || LessonRank.low => FreshnessPolicy.lessonLowMid,
      };
}

/// 要点カード（1レッスンにつき3枚以内。目安60字）。
class LessonCard {
  const LessonCard({required this.cardId, required this.text, this.figureRef});

  final String cardId;
  final String text;

  /// SVG等の図の参照キー（任意）。
  final String? figureRef;

  factory LessonCard.fromJson(Map<String, dynamic> j, String where) {
    return LessonCard(
      cardId: reqString(j, 'cardId', where),
      text: reqString(j, 'text', where),
      figureRef: optString(j, 'figureRef', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'cardId': cardId,
        'text': text,
        if (figureRef != null) 'figureRef': figureRef,
      };
}

enum QuizType { choice, truefalse, fill, numeric, sort }

/// 確認問題1問。
class Quiz {
  const Quiz({
    required this.qid,
    required this.type,
    required this.stem,
    required this.answer,
    required this.explain,
    this.choices = const [],
    this.topicTag,
  });

  final String qid;
  final QuizType type;
  final String stem;
  final List<String> choices;

  /// 正解。choice/sort は選択肢のインデックス（文字列化）または並び順、
  /// truefalse は "true"/"false"、fill/numeric は値そのもの。
  final String answer;
  final String explain;
  final String? topicTag;

  factory Quiz.fromJson(Map<String, dynamic> j, String where) {
    final typeName = reqString(j, 'type', where);
    final type = QuizType.values.where((t) => t.name == typeName);
    if (type.isEmpty) {
      fail(where, '"type" は choice / truefalse / fill / numeric / sort のいずれか');
    }
    return Quiz(
      qid: reqString(j, 'qid', where),
      type: type.first,
      stem: reqString(j, 'stem', where),
      choices: optStringList(j, 'choices', where),
      answer: reqString(j, 'answer', where),
      explain: reqString(j, 'explain', where),
      topicTag: optString(j, 'topicTag', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'qid': qid,
        'type': type.name,
        'stem': stem,
        if (choices.isNotEmpty) 'choices': choices,
        'answer': answer,
        'explain': explain,
        if (topicTag != null) 'topicTag': topicTag,
      };
}

/// 今日の一歩（任意。端末内保存のみ・個人情報を入力させない）。
class LessonAction {
  const LessonAction({required this.actionId, required this.text, this.checklist = const []});

  final String actionId;
  final String text;
  final List<String> checklist;

  factory LessonAction.fromJson(Map<String, dynamic> j, String where) {
    return LessonAction(
      actionId: reqString(j, 'actionId', where),
      text: reqString(j, 'text', where),
      checklist: optStringList(j, 'checklist', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'actionId': actionId,
        'text': text,
        if (checklist.isNotEmpty) 'checklist': checklist,
      };
}

/// 3分レッスン（共通基盤設計 v0.5 §4-1）。
///
/// 構成: 導入の1問 → 要点カード（3枚以内）→ 確認問題2〜3問 → 今日の一歩（任意）。
/// 出典・鮮度（[reviewedAt]・[freshnessPolicy]）を必須にし、
/// [isDeliverableAt] が false のレッスンは配信してはならない。
class Lesson with FreshnessAware {
  Lesson({
    required this.lessonId,
    required this.trackId,
    required this.title,
    required this.minutes,
    required this.kind,
    required this.rank,
    required this.cards,
    required this.quiz,
    required this.sources,
    required this.reviewedAt,
    required this.contentVer,
    this.action,
    this.ruleId,
    this.calcId,
    this.caseId,
    this.labId,
    this.lawVersion,
    this.nextReviewAt,
  }) : assert(minutes <= 3, 'レッスンは3分以内にする'),
       assert(cards.length <= 3, '要点カードは3枚以内にする'),
       assert(quiz.length >= 2 && quiz.length <= 3, '確認問題は2〜3問にする'),
       assert(sources.isNotEmpty, '出典は必須');

  final String lessonId;
  final String trackId;
  final String title;
  final int minutes;
  final LessonKind kind;
  final LessonRank rank;
  final List<LessonCard> cards;
  final List<Quiz> quiz;
  final LessonAction? action;

  /// 境界線ルール（BoundaryScenario）への参照。kind == boundary のとき使う。
  final String? ruleId;

  /// 計算機（Calculator）への参照。kind == predict のとき使う。
  final String? calcId;
  final String? caseId;
  final String? labId;
  final List<Source> sources;
  final String? lawVersion;

  @override
  final DateTime reviewedAt;
  final DateTime? nextReviewAt;
  final String contentVer;

  @override
  FreshnessPolicy get freshnessPolicy => rank.freshnessPolicy;

  factory Lesson.fromJson(Map<String, dynamic> j) {
    final lessonId = reqString(j, 'lessonId', 'lesson');
    final where = 'lesson[$lessonId]';

    final kindName = reqString(j, 'kind', where);
    final kind = LessonKind.values.where(
      (k) => k.name == kindName || (kindName == 'case' && k == LessonKind.caseStudy),
    );
    if (kind.isEmpty) fail(where, '"kind" が不正です: $kindName');

    final rankName = reqString(j, 'rank', where);
    final rank = LessonRank.values.where((r) => r.name == rankName);
    if (rank.isEmpty) fail(where, '"rank" は high / mid / low のいずれか');

    return Lesson(
      lessonId: lessonId,
      trackId: reqString(j, 'trackId', where),
      title: reqString(j, 'title', where),
      minutes: reqInt(j, 'minutes', where),
      kind: kind.first,
      rank: rank.first,
      cards: reqObjectList(j, 'cards', where)
          .map((c) => LessonCard.fromJson(c, where))
          .toList(),
      quiz: reqObjectList(j, 'quiz', where).map((q) => Quiz.fromJson(q, where)).toList(),
      action: j['action'] == null
          ? null
          : LessonAction.fromJson(j['action'] as Map<String, dynamic>, where),
      ruleId: optString(j, 'ruleId', where),
      calcId: optString(j, 'calcId', where),
      caseId: optString(j, 'caseId', where),
      labId: optString(j, 'labId', where),
      sources: reqObjectList(j, 'sources', where)
          .map((s) => Source.fromJson(s, where))
          .toList(),
      lawVersion: optString(j, 'lawVersion', where),
      reviewedAt: reqDate(j, 'reviewedAt', where),
      nextReviewAt: optDate(j, 'nextReviewAt', where),
      contentVer: reqString(j, 'contentVer', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'trackId': trackId,
        'title': title,
        'minutes': minutes,
        'kind': kind == LessonKind.caseStudy ? 'case' : kind.name,
        'rank': rank.name,
        'cards': cards.map((c) => c.toJson()).toList(),
        'quiz': quiz.map((q) => q.toJson()).toList(),
        if (action != null) 'action': action!.toJson(),
        if (ruleId != null) 'ruleId': ruleId,
        if (calcId != null) 'calcId': calcId,
        if (caseId != null) 'caseId': caseId,
        if (labId != null) 'labId': labId,
        'sources': sources.map((s) => s.toJson()).toList(),
        if (lawVersion != null) 'lawVersion': lawVersion,
        'reviewedAt': reviewedAt.toIso8601String(),
        if (nextReviewAt != null) 'nextReviewAt': nextReviewAt!.toIso8601String(),
        'contentVer': contentVer,
      };
}
