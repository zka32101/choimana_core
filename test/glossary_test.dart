import 'package:choimana_core/glossary.dart';
import 'package:choimana_core/validation/content_validator.dart';
import 'package:test/test.dart';

void main() {
  group('GlossaryTerm', () {
    test('JSON相互変換', () {
      const term = GlossaryTerm(
        id: 'g_compound',
        term: '複利',
        reading: 'ふくり',
        category: GlossaryCategory.general,
        definition: '利子が元本に組み込まれ、その利子にもさらに利子がつく仕組み。',
        example: '100万円を年5%複利で運用すると、10年後は約163万円になる。',
      );
      final roundTripped = GlossaryTerm.fromJson(term.toJson());
      expect(roundTripped.id, term.id);
      expect(roundTripped.category, term.category);
      expect(roundTripped.example, term.example);
    });

    test('exampleなしでもJSON化できる', () {
      const term = GlossaryTerm(
        id: 'g_deflation',
        term: 'デフレ',
        reading: 'でふれ',
        category: GlossaryCategory.general,
        definition: '物価が継続的に下落し、お金の価値が上がること。',
      );
      final json = term.toJson();
      expect(json.containsKey('example'), isFalse);
      expect(GlossaryTerm.fromJson(json).example, isNull);
    });

    test('不正なcategoryはエラーになる', () {
      expect(
        () => GlossaryTerm.fromJson({
          'id': 'bad',
          'term': 'x',
          'reading': 'x',
          'category': 'invalid',
          'definition': 'x',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('validateGlossaryTerm', () {
    test('断定・勧誘表現がなければエラーなし', () {
      const term = GlossaryTerm(
        id: 'g_nisa',
        term: 'NISA',
        reading: 'にーさ',
        category: GlossaryCategory.invest,
        definition: '投資で得た利益が非課税になる制度。',
      );
      expect(validateGlossaryTerm(term), isEmpty);
    });

    test('定義文に禁止語があればエラー', () {
      const term = GlossaryTerm(
        id: 'g_bad',
        term: 'x',
        reading: 'x',
        category: GlossaryCategory.invest,
        definition: 'このファンドは絶対に儲かる。',
      );
      final issues = validateGlossaryTerm(term);
      expect(issues, isNotEmpty);
      expect(issues.any((i) => i.message.contains('絶対')), isTrue);
      expect(issues.any((i) => i.message.contains('儲かる')), isTrue);
    });

    test('例文に禁止語があればエラー', () {
      const term = GlossaryTerm(
        id: 'g_bad2',
        term: 'x',
        reading: 'x',
        category: GlossaryCategory.general,
        definition: '普通の定義文。',
        example: 'これはおすすめの方法。',
      );
      final issues = validateGlossaryTerm(term);
      expect(issues.any((i) => i.message.contains('example')), isTrue);
    });
  });
}
