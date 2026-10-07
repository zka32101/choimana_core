import 'package:choimana_kit/calculator.dart';
import 'package:choimana_kit/src/source.dart';
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
}
