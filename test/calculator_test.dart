import 'package:choimana_core/calculator.dart';
import 'package:choimana_core/src/source.dart';
import 'package:test/test.dart';

class _TakeHomePayCalculator extends Calculator {
  _TakeHomePayCalculator({required super.reviewedAt})
      : super(
          calcId: 'take-home-pay',
          title: '手取りの目安',
          parameters: [
            Parameter(
              paramId: 'incomeTaxRate',
              value: 0.1,
              unit: '割合',
              basis: '所得税速算表（例）',
              lawVersion: '令和6年分',
              retrievedAt: DateTime(2026, 1, 1),
              expiresAt: DateTime(2027, 1, 1),
            ),
          ],
          sources: [
            Source(
              title: '国税庁 所得税速算表',
              url: 'https://example.com/tax',
              publisher: '国税庁',
              retrievedAt: DateTime(2026, 1, 1),
            ),
          ],
        );

  @override
  CalculatorResult compute(Map<String, double> inputs) {
    final gross = inputs['gross']!;
    final rate = parameters.single.value;
    return CalculatorResult(value: gross * (1 - rate));
  }
}

class _ExpiredParamCalculator extends Calculator {
  _ExpiredParamCalculator({required super.reviewedAt})
      : super(
          calcId: 'expired-param-example',
          title: '期限切れパラメータの例',
          parameters: [
            Parameter(
              paramId: 'rate',
              value: 0.1,
              unit: '割合',
              basis: '出典未確認',
              lawVersion: '出典未確認',
              retrievedAt: DateTime(2026, 1, 1),
              expiresAt: DateTime(2026, 1, 1),
            ),
          ],
          sources: [
            Source(
              title: '出典未確認',
              url: 'https://example.com',
              publisher: 'N/A',
              retrievedAt: DateTime(2026, 1, 1),
            ),
          ],
        );

  @override
  CalculatorResult compute(Map<String, double> inputs) => const CalculatorResult(value: 0);
}

void main() {
  test('定数はParameter表から取り、結果は目安表示', () {
    final calc = _TakeHomePayCalculator(reviewedAt: DateTime(2026, 1, 1));
    final result = calc.compute({'gross': 300000});
    expect(result.value, closeTo(270000, 0.001));
    expect(result.note, '目安');
  });

  test('定数の期限切れを検出する', () {
    final calc = _TakeHomePayCalculator(reviewedAt: DateTime(2026, 1, 1));
    expect(calc.parametersValidAt(DateTime(2026, 6, 1)), isTrue);
    expect(calc.parametersValidAt(DateTime(2027, 6, 1)), isFalse);
  });

  group('isFullyDeliverableAt', () {
    test('鮮度OK・定数も有効なら true', () {
      final calc = _TakeHomePayCalculator(reviewedAt: DateTime(2026, 1, 1));
      expect(calc.isFullyDeliverableAt(DateTime(2026, 6, 1)), isTrue);
    });

    test('鮮度はOKでも定数が期限切れなら false（isDeliverableAtだけでは検出できない）', () {
      // reviewedAtは2026-1-1のまま（鮮度は十分新しい）だが、定数自体の
      // expiresAtが過去になるケース（意図的に期限切れにした未検証パラメータ等）。
      final calc = _TakeHomePayCalculator(reviewedAt: DateTime(2026, 1, 1));
      final now = DateTime(2026, 2, 1); // reviewedAtから31日・鮮度はまだok
      expect(calc.isDeliverableAt(now), isTrue);
      // 定数の expiresAt(2027-1-1) はまだ有効なので、代わりに期限切れの
      // 計算機で確認する。
      final expiredCalc = _ExpiredParamCalculator(reviewedAt: DateTime(2026, 1, 1));
      expect(expiredCalc.isDeliverableAt(now), isTrue);
      expect(expiredCalc.parametersValidAt(now), isFalse);
      expect(expiredCalc.isFullyDeliverableAt(now), isFalse);
    });

    test('定数は有効でも鮮度がstoppedなら false', () {
      final calc = _TakeHomePayCalculator(reviewedAt: DateTime(2026, 1, 1));
      final now = DateTime(2026, 7, 31); // reviewedAtから180日超
      expect(calc.parametersValidAt(now), isTrue);
      expect(calc.isDeliverableAt(now), isFalse);
      expect(calc.isFullyDeliverableAt(now), isFalse);
    });
  });
}
