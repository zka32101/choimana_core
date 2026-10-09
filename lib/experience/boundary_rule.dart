import '../freshness.dart';
import '../src/json_util.dart';
import '../src/source.dart';

/// 境界線スライダー（型①、決定76）の二値条件。
///
/// ukalab_core の BoundaryCondition と同じ構造だが、examId を持たない
/// （ちょいまなには試験の概念がないため）。将来 yourwish_learn が切り出され
/// たら、そちらの型部品への依存に切り替える前提。
class BoundaryCondition {
  const BoundaryCondition({
    required this.conditionId,
    required this.label,
    required this.trueLabel,
    required this.falseLabel,
  });

  final String conditionId;

  /// 条件の説明（例: "年収が基準を超えるか"）。
  final String label;
  final String trueLabel;
  final String falseLabel;

  factory BoundaryCondition.fromJson(Map<String, dynamic> j, String where) {
    return BoundaryCondition(
      conditionId: reqString(j, 'conditionId', where),
      label: reqString(j, 'label', where),
      trueLabel: reqString(j, 'trueLabel', where),
      falseLabel: reqString(j, 'falseLabel', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'conditionId': conditionId,
        'label': label,
        'trueLabel': trueLabel,
        'falseLabel': falseLabel,
      };
}

/// 条件の組み合わせ1つに対する結論（決定木の1枝）。
///
/// [conditionValues] は条件の一部だけを指定してよい。評価は配列の先頭から
/// 順に調べ、指定された条件がすべて一致した最初のルールを使う。
class BoundaryOutcome {
  const BoundaryOutcome({
    required this.conditionValues,
    required this.conclusion,
    required this.basis,
  });

  final Map<String, bool> conditionValues;

  /// 判定結果（例: "扶養に入れる（目安）"）。断定を避け「目安」を明示する。
  final String conclusion;

  /// 根拠条文・資料（例: "所得税法○条"）。
  final String basis;

  bool matches(Map<String, bool> values) {
    for (final entry in conditionValues.entries) {
      if (values[entry.key] != entry.value) return false;
    }
    return true;
  }

  factory BoundaryOutcome.fromJson(Map<String, dynamic> j, String where) {
    final rawValues = j['conditionValues'];
    if (rawValues is! Map || rawValues.isEmpty) {
      fail(where, '"conditionValues" は空でないオブジェクトが必要です');
    }
    final conditionValues = <String, bool>{};
    rawValues.forEach((k, v) {
      if (v is! bool) fail(where, '"conditionValues.$k" は真偽値が必要です');
      conditionValues[k as String] = v;
    });
    return BoundaryOutcome(
      conditionValues: conditionValues,
      conclusion: reqString(j, 'conclusion', where),
      basis: reqString(j, 'basis', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'conditionValues': conditionValues,
        'conclusion': conclusion,
        'basis': basis,
      };
}

/// 境界線ルール表（BoundaryRule、共通基盤設計 v0.5 §4-8）。
///
/// 条件→結論＋根拠条文＋施行日。出典と施行日がないルールは配信しない
/// （[sources] が空、または [lawVersion] が未設定なら [isDeliverableAt] は常に
/// false として扱うべきで、呼び出し側で検証する）。
class BoundaryRule with FreshnessAware {
  BoundaryRule({
    required this.ruleId,
    required this.title,
    required this.conditions,
    required this.outcomes,
    required this.sources,
    required this.lawVersion,
    required this.reviewedAt,
    required this.contentVer,
    this.freshnessPolicy = FreshnessPolicy.lessonLowMid,
    this.note = '目安',
  }) : assert(conditions.isNotEmpty, '条件は1つ以上必要'),
       assert(outcomes.isNotEmpty, '結論は1つ以上必要'),
       assert(sources.isNotEmpty, '出典は必須'),
       assert(lawVersion != '', '施行日（lawVersion）は必須');

  final String ruleId;
  final String title;
  final List<BoundaryCondition> conditions;

  /// 評価順。最初にマッチしたものを使う。
  final List<BoundaryOutcome> outcomes;
  final List<Source> sources;

  /// 施行日・法令の版（例: "令和6年分"）。
  final String lawVersion;

  @override
  final DateTime reviewedAt;
  final String contentVer;

  @override
  final FreshnessPolicy freshnessPolicy;

  /// 結果表示に必須の注記（既定「目安」）。
  final String note;

  /// [values] は全ての [conditions] の conditionId をキーに持つ必要がある。
  /// マッチする結論がなければ null（ルール表の不備）。
  BoundaryOutcome? evaluate(Map<String, bool> values) {
    for (final outcome in outcomes) {
      if (outcome.matches(values)) return outcome;
    }
    return null;
  }

  factory BoundaryRule.fromJson(Map<String, dynamic> j) {
    final ruleId = reqString(j, 'ruleId', 'boundaryRule');
    final where = 'boundaryRule[$ruleId]';
    return BoundaryRule(
      ruleId: ruleId,
      title: reqString(j, 'title', where),
      conditions: reqObjectList(j, 'conditions', where)
          .map((c) => BoundaryCondition.fromJson(c, where))
          .toList(),
      outcomes: reqObjectList(j, 'outcomes', where)
          .map((o) => BoundaryOutcome.fromJson(o, where))
          .toList(),
      sources:
          reqObjectList(j, 'sources', where).map((s) => Source.fromJson(s, where)).toList(),
      lawVersion: reqString(j, 'lawVersion', where),
      reviewedAt: reqDate(j, 'reviewedAt', where),
      contentVer: reqString(j, 'contentVer', where),
      note: optString(j, 'note', where) ?? '目安',
    );
  }

  Map<String, dynamic> toJson() => {
        'ruleId': ruleId,
        'title': title,
        'conditions': conditions.map((c) => c.toJson()).toList(),
        'outcomes': outcomes.map((o) => o.toJson()).toList(),
        'sources': sources.map((s) => s.toJson()).toList(),
        'lawVersion': lawVersion,
        'reviewedAt': reviewedAt.toIso8601String(),
        'contentVer': contentVer,
        'note': note,
      };
}
