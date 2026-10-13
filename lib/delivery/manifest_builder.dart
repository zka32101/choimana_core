import 'package:crypto/crypto.dart';

import 'manifest.dart';

/// manifest 本体への署名（鍵管理はアプリ側・制作側の実装に委ねる）。
/// [DeliveryClient] 側の [ManifestSignatureVerifier] と対になる。
abstract class ManifestSigner {
  String sign(Map<String, dynamic> signedPayload);
}

/// `content/` 配下のファイル群から配信用 [Manifest] を組み立てる
/// （共通基盤設計 v0.5 §5・§9）。
///
/// アプリ側（choimana_okane等）のビルドスクリプトが、検証済みの
/// `content/lessons`・`content/boundary_rules`・`content/glossary` 等を
/// まとめてこれに渡し、配信サーバーに置く manifest.json と各ファイルを生成する
/// 想定。ファイルのバイト列そのものは呼び出し側が読み込んで渡す
/// （choimana_core はファイルシステムに依存しない）。
class ManifestBuilder {
  ManifestBuilder._();

  /// [files] はキーが配信パス（例: `lessons/take-home-pay-001.json`）、
  /// 値がそのファイルのバイト列。
  static Manifest build({
    required Map<String, List<int>> files,
    required String minAppVersion,
    required ManifestSigner signer,
    List<String> killList = const [],
    DateTime? generatedAt,
    int schemaVer = 1,
  }) {
    final generated = generatedAt ?? DateTime.now();
    final manifestFiles = [
      for (final entry in files.entries)
        ManifestFile(
          path: entry.key,
          sha256: sha256.convert(entry.value).toString(),
          bytes: entry.value.length,
        ),
    ]..sort((a, b) => a.path.compareTo(b.path));

    final unsigned = Manifest(
      schemaVer: schemaVer,
      generatedAt: generated,
      files: manifestFiles,
      minAppVersion: minAppVersion,
      signature: '',
      killList: killList,
    );

    final signature = signer.sign(unsigned.signedPayload());

    return Manifest(
      schemaVer: schemaVer,
      generatedAt: generated,
      files: manifestFiles,
      minAppVersion: minAppVersion,
      signature: signature,
      killList: killList,
    );
  }
}
