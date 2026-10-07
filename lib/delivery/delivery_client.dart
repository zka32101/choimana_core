import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'manifest.dart';

/// manifest 取得結果。[notModified] なら [bodyBytes] は null でよい。
class ManifestFetchResult {
  const ManifestFetchResult({this.bodyBytes, this.etag, this.notModified = false});

  final List<int>? bodyBytes;
  final String? etag;
  final bool notModified;
}

/// 配信サーバーとの通信（アプリ側の実装に委ねる。テストでは差し替える）。
abstract class DeliveryTransport {
  Future<ManifestFetchResult> fetchManifest({String? ifNoneMatchEtag});
  Future<List<int>> fetchFile(String path);
}

/// manifest の署名検証（公開鍵の方式はアプリ側実装に委ねる）。
abstract class ManifestSignatureVerifier {
  bool verify(Map<String, dynamic> signedPayload, String signature);
}

/// 端末内の保存先（失敗時は前回分を維持するため、保存は全件検証後に行う）。
abstract class DeliveryStore {
  Future<Manifest?> loadManifest();
  Future<String?> loadEtag();
  Future<void> save(Manifest manifest, String? etag, Map<String, List<int>> files);
  Future<List<int>?> loadFile(String path);
}

/// 配信クライアント（共通基盤設計 v0.5 §4-13・§9）。
///
/// manifest取得(ETag) → sha256・署名検証 → スキーマ検証 → 端末保存 →
/// killList反映。どこかで失敗したら前回分を維持し、オフラインでも動く。
class DeliveryClient {
  DeliveryClient({
    required this.transport,
    required this.verifier,
    required this.store,
  });

  final DeliveryTransport transport;
  final ManifestSignatureVerifier verifier;
  final DeliveryStore store;

  /// 新しい配信データを取得・検証して保存する。検証に失敗した場合は
  /// 例外にせず、前回保存済みの manifest を返す（オフライン・改ざん時の安全側）。
  Future<Manifest?> sync() async {
    final previous = await store.loadManifest();
    final etag = await store.loadEtag();

    final ManifestFetchResult result;
    try {
      result = await transport.fetchManifest(ifNoneMatchEtag: etag);
    } catch (_) {
      return previous;
    }
    if (result.notModified || result.bodyBytes == null) {
      return previous;
    }

    Manifest manifest;
    try {
      final decoded = jsonDecode(utf8.decode(result.bodyBytes!));
      if (decoded is! Map<String, dynamic>) return previous;
      manifest = Manifest.fromJson(decoded);
    } catch (_) {
      return previous;
    }

    if (!verifier.verify(manifest.signedPayload(), manifest.signature)) {
      return previous;
    }

    final fetchedFiles = <String, List<int>>{};
    for (final file in manifest.files) {
      List<int> bytes;
      try {
        bytes = await transport.fetchFile(file.path);
      } catch (_) {
        return previous;
      }
      final digest = sha256.convert(bytes).toString();
      if (digest != file.sha256) {
        // 改ざん・取得失敗の疑い。このファイルだけでなく全体を不採用にする。
        return previous;
      }
      fetchedFiles[file.path] = bytes;
    }

    await store.save(manifest, result.etag, fetchedFiles);
    return manifest;
  }

  /// [itemId] が killList に含まれるか（即非表示判定）。
  static bool isKilled(Manifest manifest, String itemId) =>
      manifest.killList.contains(itemId);
}
