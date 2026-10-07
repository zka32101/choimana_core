import 'package:choimana_kit/experience/boundary_rule.dart';
import 'package:choimana_kit/src/source.dart';
import 'package:test/test.dart';

void main() {
  test('境界線ルール: 条件に応じて結論が切り替わる', () {
    final rule = BoundaryRule(
      ruleId: 'fuyou-1',
      title: '扶養の境目',
      conditions: const [
        BoundaryCondition(
          conditionId: 'overIncome',
          label: '年収が基準を超えるか',
          trueLabel: '超える',
          falseLabel: '超えない',
        ),
      ],
      outcomes: const [
        BoundaryOutcome(
          conditionValues: {'overIncome': true},
          conclusion: '扶養から外れる（目安）',
          basis: '所得税法の扶養親族の規定',
        ),
        BoundaryOutcome(
          conditionValues: {'overIncome': false},
          conclusion: '扶養に入れる（目安）',
          basis: '所得税法の扶養親族の規定',
        ),
      ],
      sources: [
        Source(
          title: '国税庁 扶養の説明',
          url: 'https://example.com/fuyou',
          publisher: '国税庁',
          retrievedAt: DateTime(2026, 1, 1),
        ),
      ],
      lawVersion: '令和6年分',
      reviewedAt: DateTime(2026, 1, 1),
      contentVer: '1',
    );

    expect(rule.evaluate({'overIncome': true})!.conclusion, '扶養から外れる（目安）');
    expect(rule.evaluate({'overIncome': false})!.conclusion, '扶養に入れる（目安）');
    expect(rule.note, '目安');
  });

  test('出典が空だとassertで失敗する', () {
    expect(
      () => BoundaryRule(
        ruleId: 'x',
        title: 'x',
        conditions: const [
          BoundaryCondition(
            conditionId: 'c',
            label: 'l',
            trueLabel: 't',
            falseLabel: 'f',
          ),
        ],
        outcomes: const [
          BoundaryOutcome(conditionValues: {'c': true}, conclusion: 'r', basis: 'b'),
        ],
        sources: const [],
        lawVersion: 'v1',
        reviewedAt: DateTime(2026, 1, 1),
        contentVer: '1',
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}
