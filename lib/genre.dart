import 'src/json_util.dart';

/// ジャンル（お金／AI活用／仕事スキル／暮らしの法律・制度／語学・教養）。
///
/// [color] はアプリ側のテーマ色キー（例: "gold"）。実際の色値は
/// app_common_kit のテーマ部品側で解決する。うかラボの資格別カラーとは
/// 同じ画面に出さない方針（共通基盤設計 v0.5 §5）。
class Genre {
  const Genre({
    required this.genreId,
    required this.name,
    required this.colorKey,
    required this.order,
  });

  final String genreId;
  final String name;
  final String colorKey;
  final int order;

  factory Genre.fromJson(Map<String, dynamic> j) {
    final genreId = reqString(j, 'genreId', 'genre');
    final where = 'genre[$genreId]';
    return Genre(
      genreId: genreId,
      name: reqString(j, 'name', where),
      colorKey: reqString(j, 'color', where),
      order: reqInt(j, 'order', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'genreId': genreId,
        'name': name,
        'color': colorKey,
        'order': order,
      };
}

/// ジャンル内の学習の道筋。順序は目安でスキップ可（共通基盤設計 v0.5 §4）。
class Track {
  const Track({
    required this.trackId,
    required this.genreId,
    required this.name,
    required this.order,
    required this.lessonIds,
  });

  final String trackId;
  final String genreId;
  final String name;
  final int order;
  final List<String> lessonIds;

  factory Track.fromJson(Map<String, dynamic> j) {
    final trackId = reqString(j, 'trackId', 'track');
    final where = 'track[$trackId]';
    return Track(
      trackId: trackId,
      genreId: reqString(j, 'genreId', where),
      name: reqString(j, 'name', where),
      order: reqInt(j, 'order', where),
      lessonIds: reqStringList(j, 'lessonIds', where),
    );
  }

  Map<String, dynamic> toJson() => {
        'trackId': trackId,
        'genreId': genreId,
        'name': name,
        'order': order,
        'lessonIds': lessonIds,
      };
}
