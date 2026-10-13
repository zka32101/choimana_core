import 'dart:convert';

import 'package:choimana_core/delivery/manifest.dart';
import 'package:choimana_core/delivery/manifest_builder.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

class _FakeSigner implements ManifestSigner {
  String? lastPayloadJson;

  @override
  String sign(Map<String, dynamic> signedPayload) {
    lastPayloadJson = jsonEncode(signedPayload);
    return 'signed:${signedPayload['schemaVer']}';
  }
}

void main() {
  group('ManifestBuilder', () {
    test('各ファイルのsha256・bytesを正しく計算する', () {
      final a = utf8.encode('{"a":1}');
      final b = utf8.encode('{"b":2}');
      final signer = _FakeSigner();

      final manifest = ManifestBuilder.build(
        files: {'lessons/a.json': a, 'lessons/b.json': b},
        minAppVersion: '0.1.0',
        signer: signer,
        generatedAt: DateTime(2026, 10, 13),
      );

      final fileA = manifest.files.firstWhere((f) => f.path == 'lessons/a.json');
      expect(fileA.sha256, sha256.convert(a).toString());
      expect(fileA.bytes, a.length);
    });

    test('ファイルはpath順にソートされる（manifestの決定性）', () {
      final signer = _FakeSigner();
      final manifest = ManifestBuilder.build(
        files: {
          'lessons/z.json': utf8.encode('{}'),
          'lessons/a.json': utf8.encode('{}'),
        },
        minAppVersion: '0.1.0',
        signer: signer,
      );

      expect(manifest.files.map((f) => f.path).toList(), ['lessons/a.json', 'lessons/z.json']);
    });

    test('signerが呼ばれ、署名未設定のpayloadに対して署名する', () {
      final signer = _FakeSigner();
      final manifest = ManifestBuilder.build(
        files: {'lessons/a.json': utf8.encode('{}')},
        minAppVersion: '0.1.0',
        signer: signer,
        schemaVer: 2,
      );

      expect(manifest.signature, 'signed:2');
      expect(signer.lastPayloadJson, isNotNull);
      expect(jsonDecode(signer.lastPayloadJson!)['schemaVer'], 2);
    });

    test('killListとminAppVersionがmanifestに反映される', () {
      final signer = _FakeSigner();
      final manifest = ManifestBuilder.build(
        files: {'lessons/a.json': utf8.encode('{}')},
        minAppVersion: '0.2.0',
        signer: signer,
        killList: ['take-home-pay-001'],
      );

      expect(manifest.minAppVersion, '0.2.0');
      expect(manifest.killList, ['take-home-pay-001']);
    });

    test('生成したmanifestはDeliveryClient側のManifest.fromJson/toJsonと往復する', () {
      final signer = _FakeSigner();
      final manifest = ManifestBuilder.build(
        files: {'lessons/a.json': utf8.encode('{}')},
        minAppVersion: '0.1.0',
        signer: signer,
        generatedAt: DateTime(2026, 10, 13),
      );

      final restored = Manifest.fromJson(manifest.toJson());
      expect(restored.files.single.sha256, manifest.files.single.sha256);
      expect(restored.signature, manifest.signature);
    });
  });
}
