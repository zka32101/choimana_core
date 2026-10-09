import 'package:choimana_core/validation/forbidden_words.dart';
import 'package:test/test.dart';

void main() {
  test('禁止語を検出する', () {
    final hits = scanForbiddenWords('これを買えば必ず儲かる方法');
    expect(hits.map((h) => h.word), containsAll(['必ず', '儲かる']));
  });

  test('禁止語がなければ空', () {
    expect(scanForbiddenWords('複利で資産が増える仕組みを学ぶ'), isEmpty);
  });
}
