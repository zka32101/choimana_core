import 'freshness.dart';
import 'src/json_util.dart';
import 'src/source.dart';

/// 計算に使う定数（税率・控除額・単価など）。コードに直書きせず、
/// 出典・施行日つきでここに集約する（共通基盤設計 v0.5 §3c・§4-7）。
class Parameter {
  const Parameter({
    required this.paramId,
    required this.value,
    required this.unit,
    required this.basis,
    required this.lawVersion,
    required this.retrievedAt,
    required this.expiresAt,
  });

  final String paramId;
  final double value;
  final String unit;

  /// 根拠資料（例: "所得税速算表"）。
  final String basis;
  final String lawVersion;
  final DateTime retrievedAt;
  final DateTime expiresAt;

  /// 期限切れなら、この定数を使う計算機は配信してはならない。
  bool isValidAt(DateTime now) => now.isBefore(expiresAt);

  factory Parameter.fromJson(Map<String, dynamic> j) {
    final paramId = reqString(j, 'paramId', 'parameter');
    final where = 'parameter[$paramId]';
    return Parameter(
      paramId: paramId,
      value: reqNum(j, 'value', where),
      unit: reqString(j, 'unit', where),
      basis: reqString(j, 'basis', where),
      lawVersion: reqString(j, 'lawVersion', where),
      retrievedAt: reqDate(j, 'retrievedAt', where),
      expiresAt: reqDate(j, 'expiresAt', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'paramId': paramId,
        'value': value,
        'unit': unit,
        'basis': basis,
        'lawVersion': lawVersion,
        'retrievedAt': retrievedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };
}

/// 計算結果。[note] は常に「目安」等の非断定表示を伴う（CIで表示漏れを検出）。
class CalculatorResult {
  const CalculatorResult({required this.value, this.note = '目安'});

  final double value;
  final String note;
}

/// 目安の計算（型②「予測→実行」の土台。共通基盤設計 v0.5 §4-7）。
///
/// 定数は [parameters]（出典・施行日つき）から取り、式自体は
/// サブクラスで実装する。入力値（[compute] の引数）は呼び出し側が保存
/// してはならない（端末内メモリのみで扱う方針。§8）。
abstract class Calculator with FreshnessAware {
  Calculator({
    required this.calcId,
    required this.title,
    required this.parameters,
    required this.sources,
    required this.reviewedAt,
    this.freshnessPolicy = FreshnessPolicy.lessonLowMid,
  });

  final String calcId;
  final String title;
  final List<Parameter> parameters;
  final List<Source> sources;

  @override
  final DateTime reviewedAt;

  @override
  final FreshnessPolicy freshnessPolicy;

  /// すべての [parameters] が [now] 時点で有効か。
  bool parametersValidAt(DateTime now) =>
      parameters.every((p) => p.isValidAt(now));

  /// 入力値から目安の計算結果を返す。実装は純粋関数にし、
  /// 入力値を保存・送信してはならない。
  CalculatorResult compute(Map<String, double> inputs);
}
