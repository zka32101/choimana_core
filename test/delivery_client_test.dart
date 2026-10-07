import 'dart:convert';

import 'package:choimana_kit/delivery/delivery_client.dart';
import 'package:choimana_kit/delivery/manifest.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

class _FakeTransport implements DeliveryTransport {
  _FakeTransport({required this.manifestBytes, required this.files, this.throwOnManifest = false});

  List<int>? manifestBytes;
  Map<String, List<int>> files;
  bool throwOnManifest;

  @override
  Future<ManifestFetchResult> fetchManifest({String? ifNoneMatchEtag}) async {
    if (throwOnManifest) throw Exception('network down');
    if (manifestBytes == null) return const ManifestFetchResult(notModified: true);
    return ManifestFetchResult(bodyBytes: manifestBytes, etag: 'etag-1');
  }

  @override
  Future<List<int>> fetchFile(String path) async {
    final bytes = files[path];
    if (bytes == null) throw Exception('404: $path');
    return bytes;
  }
}

class _AlwaysValidVerifier implements ManifestSignatureVerifier {
  @override
  bool verify(Map<String, dynamic> signedPayload, String signature) => signature == 'valid';
}

class _InMemoryStore implements DeliveryStore {
  Manifest? manifest;
  String? etag;
  final Map<String, List<int>> savedFiles = {};

  @override
  Future<Manifest?> loadManifest() async => manifest;

  @override
  Future<String?> loadEtag() async => etag;

  @override
  Future<void> save(Manifest m, String? newEtag, Map<String, List<int>> files) async {
    manifest = m;
    etag = newEtag;
    savedFiles.addAll(files);
  }

  @override
  Future<List<int>?> loadFile(String path) async => savedFiles[path];
}

Map<String, dynamic> _manifestJson(List<int> fileBytes, {String signature = 'valid'}) {
  final digest = sha256.convert(fileBytes).toString();
  return {
    'schemaVer': 1,
    'generatedAt': DateTime(2026, 1, 1).toIso8601String(),
    'files': [
      {'path': 'weekly/2026-W01.json', 'sha256': digest, 'bytes': fileBytes.length},
    ],
    'minAppVersion': '0.1.0',
    'signature': signature,
    'killList': <String>[],
  };
}

void main() {
  test('検証に通れば保存される', () async {
    final fileBytes = utf8.encode('{"hello":"world"}');
    final manifestJson = _manifestJson(fileBytes);
    final transport = _FakeTransport(
      manifestBytes: utf8.encode(jsonEncode(manifestJson)),
      files: {'weekly/2026-W01.json': fileBytes},
    );
    final store = _InMemoryStore();
    final client = DeliveryClient(
      transport: transport,
      verifier: _AlwaysValidVerifier(),
      store: store,
    );

    final result = await client.sync();

    expect(result, isNotNull);
    expect(store.savedFiles['weekly/2026-W01.json'], fileBytes);
    expect(store.etag, 'etag-1');
  });

  test('署名が不正なら前回分を維持する', () async {
    final fileBytes = utf8.encode('{"hello":"world"}');
    final manifestJson = _manifestJson(fileBytes, signature: 'invalid');
    final transport = _FakeTransport(
      manifestBytes: utf8.encode(jsonEncode(manifestJson)),
      files: {'weekly/2026-W01.json': fileBytes},
    );
    final store = _InMemoryStore();
    final client = DeliveryClient(
      transport: transport,
      verifier: _AlwaysValidVerifier(),
      store: store,
    );

    final result = await client.sync();

    expect(result, isNull);
    expect(store.savedFiles, isEmpty);
  });

  test('ファイルのsha256が一致しなければ前回分を維持する', () async {
    final fileBytes = utf8.encode('{"hello":"world"}');
    final tamperedBytes = utf8.encode('{"hello":"tampered"}');
    final manifestJson = _manifestJson(fileBytes);
    final transport = _FakeTransport(
      manifestBytes: utf8.encode(jsonEncode(manifestJson)),
      files: {'weekly/2026-W01.json': tamperedBytes},
    );
    final store = _InMemoryStore();
    final client = DeliveryClient(
      transport: transport,
      verifier: _AlwaysValidVerifier(),
      store: store,
    );

    final result = await client.sync();

    expect(result, isNull);
    expect(store.savedFiles, isEmpty);
  });

  test('通信失敗時は前回分を返す（オフライン対応）', () async {
    final store = _InMemoryStore();
    final transport = _FakeTransport(manifestBytes: null, files: const {}, throwOnManifest: true);
    final client = DeliveryClient(
      transport: transport,
      verifier: _AlwaysValidVerifier(),
      store: store,
    );

    final result = await client.sync();

    expect(result, store.manifest);
  });
}
