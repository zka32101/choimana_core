import 'json_util.dart';

/// 出典の分類。公開情報のみを扱う方針（共通基盤設計 v0.5 §8）に沿う。
enum SourceCategory {
  /// 公的機関・公式発表。
  official,

  /// 一般公開情報（報道・公式ブログ等）。
  public,

  /// 補助的な出典（確認用の二次情報）。
  aux,
}

/// 1件の出典（公式資料・URL等）。[retrievedAt] は取得日で、鮮度判定の基準にする。
class Source {
  const Source({
    required this.title,
    required this.url,
    required this.publisher,
    required this.retrievedAt,
    this.license,
    this.category = SourceCategory.official,
  });

  final String title;
  final String url;
  final String publisher;
  final DateTime retrievedAt;
  final String? license;
  final SourceCategory category;

  factory Source.fromJson(Map<String, dynamic> j, String where) {
    final categoryName = optString(j, 'category', where) ?? 'official';
    final category =
        SourceCategory.values.where((c) => c.name == categoryName);
    if (category.isEmpty) {
      fail(where, '"category" は official / public / aux のいずれかです');
    }
    return Source(
      title: reqString(j, 'title', where),
      url: reqString(j, 'url', where),
      publisher: reqString(j, 'publisher', where),
      retrievedAt: reqDate(j, 'retrievedAt', where),
      license: optString(j, 'license', where),
      category: category.first,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'publisher': publisher,
        'retrievedAt': retrievedAt.toIso8601String(),
        if (license != null) 'license': license,
        'category': category.name,
      };
}
