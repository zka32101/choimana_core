import '../src/json_util.dart';

/// 配信ファイル1件（manifest.files の要素）。
class ManifestFile {
  const ManifestFile({required this.path, required this.sha256, required this.bytes});

  final String path;
  final String sha256;
  final int bytes;

  factory ManifestFile.fromJson(Map<String, dynamic> j, String where) {
    return ManifestFile(
      path: reqString(j, 'path', where),
      sha256: reqString(j, 'sha256', where),
      bytes: reqInt(j, 'bytes', where),
    );
  }

  Map<String, dynamic> toJson() => {'path': path, 'sha256': sha256, 'bytes': bytes};
}

/// 配信基盤の manifest（共通基盤設計 v0.5 §5・§9）。
///
/// 制作側の鍵で署名された静的JSON。アプリは公開鍵で [signature] を検証し、
/// 各ファイルを [files] の sha256 で検証してから端末に保存する。
/// [killList] に挙がった itemId は即非表示にする（キルスイッチ）。
class Manifest {
  const Manifest({
    required this.schemaVer,
    required this.generatedAt,
    required this.files,
    required this.minAppVersion,
    required this.signature,
    this.killList = const [],
  });

  final int schemaVer;
  final DateTime generatedAt;
  final List<ManifestFile> files;
  final String minAppVersion;

  /// manifest 本体（signature を除く）に対する署名（base64等。検証方式は
  /// [ManifestVerifier] の実装側で決める）。
  final String signature;
  final List<String> killList;

  factory Manifest.fromJson(Map<String, dynamic> j) {
    const where = 'manifest';
    return Manifest(
      schemaVer: reqInt(j, 'schemaVer', where),
      generatedAt: reqDate(j, 'generatedAt', where),
      files: reqObjectList(j, 'files', where)
          .map((f) => ManifestFile.fromJson(f, where))
          .toList(),
      minAppVersion: reqString(j, 'minAppVersion', where),
      signature: reqString(j, 'signature', where),
      killList: optStringList(j, 'killList', where),
    );
  }

  /// 署名検証の対象になる本体部分（signature を除いた JSON）。
  Map<String, dynamic> signedPayload() => {
        'schemaVer': schemaVer,
        'generatedAt': generatedAt.toIso8601String(),
        'files': files.map((f) => f.toJson()).toList(),
        'minAppVersion': minAppVersion,
        'killList': killList,
      };

  Map<String, dynamic> toJson() => {...signedPayload(), 'signature': signature};
}
