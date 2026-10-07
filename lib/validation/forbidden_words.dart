/// 表現チェック（共通基盤設計 v0.5 §7・ちょいまな規約・プライバシー・法務
/// セルフチェック v0.1 §1-2）。
///
/// 断定・勧誘・優劣表現などを禁止語として検出する。コンテンツの該当箇所
/// （カード・確認問題・結論文など）の文字列をCIで突き合わせる。
library;

/// 禁止語とその理由。理由は検出結果の説明に使う。
class ForbiddenWord {
  const ForbiddenWord(this.word, this.reason);

  final String word;
  final String reason;
}

const List<ForbiddenWord> forbiddenWords = [
  ForbiddenWord('必ず', '断定表現（結果を保証できない）'),
  ForbiddenWord('確実に', '断定表現（結果を保証できない）'),
  ForbiddenWord('絶対', '断定表現（結果を保証できない）'),
  ForbiddenWord('儲かる', '金融商品の勧誘・助言に当たるおそれ'),
  ForbiddenWord('おすすめ', '推奨・勧誘と受け取られる表現'),
  ForbiddenWord('一番良い', '優劣・ランキング表現'),
  ForbiddenWord('最も優れている', '優劣・ランキング表現'),
  ForbiddenWord('すべき', '個別の助言と受け取られる表現'),
  ForbiddenWord('違法ではない', '法的判断の断定（個別事案に当てはまらない場合がある）'),
  ForbiddenWord('問題ない', '法的・安全上の判断の断定'),
  ForbiddenWord('公式', '誤認を招く表現（運営者が公式機関であるかのように読める）'),
  ForbiddenWord('認定', '誤認を招く表現'),
];

/// 必須表示（CIで有無のみ確認する簡易チェック）。
const List<String> requiredDisclaimerPhrases = [
  '一般的な情報',
];

/// 1件の検出結果。
class ForbiddenWordHit {
  const ForbiddenWordHit({required this.word, required this.reason, required this.context});

  final String word;
  final String reason;

  /// 検出元の文字列（どのフィールドかはCaller側で付与する）。
  final String context;
}

/// [text] 内の禁止語をすべて検出する。
List<ForbiddenWordHit> scanForbiddenWords(String text) {
  final hits = <ForbiddenWordHit>[];
  for (final fw in forbiddenWords) {
    if (text.contains(fw.word)) {
      hits.add(ForbiddenWordHit(word: fw.word, reason: fw.reason, context: text));
    }
  }
  return hits;
}
