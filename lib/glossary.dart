import 'src/json_util.dart';

/// 用語集のカテゴリ（kinnyu の GlossaryCategory を踏襲）。
enum GlossaryCategory { savings, tax, invest, insurance, general }

/// 用語集1件（共通基盤設計 v0.5 §4-?。レッスンの要点カードから
/// [GlossaryTerm.id] を参照して用語解説にリンクする想定）。
///
/// 数値や制度の施行日を持たないため [Calculator]/[BoundaryRule] と違って
/// 出典・鮮度は必須にしていない。ただし定義文に断定・勧誘表現が混じらない
/// ことは [validateGlossaryTerm] で検証する。
class GlossaryTerm {
  const GlossaryTerm({
    required this.id,
    required this.term,
    required this.reading,
    required this.category,
    required this.definition,
    this.example,
  });

  final String id;
  final String term;
  final String reading;
  final GlossaryCategory category;
  final String definition;
  final String? example;

  factory GlossaryTerm.fromJson(Map<String, dynamic> j) {
    final id = reqString(j, 'id', 'glossaryTerm');
    final where = 'glossaryTerm[$id]';
    final categoryName = reqString(j, 'category', where);
    final category = GlossaryCategory.values.where((c) => c.name == categoryName);
    if (category.isEmpty) {
      fail(where, '"category" は savings / tax / invest / insurance / general のいずれか');
    }
    return GlossaryTerm(
      id: id,
      term: reqString(j, 'term', where),
      reading: reqString(j, 'reading', where),
      category: category.first,
      definition: reqString(j, 'definition', where),
      example: optString(j, 'example', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'term': term,
        'reading': reading,
        'category': category.name,
        'definition': definition,
        if (example != null) 'example': example,
      };
}
