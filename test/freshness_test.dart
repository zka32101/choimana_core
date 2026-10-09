import 'package:choimana_core/freshness.dart';
import 'package:test/test.dart';

void main() {
  group('FreshnessPolicy', () {
    test('lessonLowMid: 90日以内はok', () {
      final reviewedAt = DateTime(2026, 1, 1);
      final now = DateTime(2026, 1, 1).add(const Duration(days: 90));
      expect(
        FreshnessPolicy.lessonLowMid.statusFor(reviewedAt, now),
        FreshnessStatus.ok,
      );
    });

    test('lessonLowMid: 181日超で停止', () {
      final reviewedAt = DateTime(2026, 1, 1);
      final now = reviewedAt.add(const Duration(days: 181));
      expect(
        FreshnessPolicy.lessonLowMid.statusFor(reviewedAt, now),
        FreshnessStatus.stopped,
      );
    });

    test('lessonLowMid: 150日でnotice（利用者表示）', () {
      final reviewedAt = DateTime(2026, 1, 1);
      final now = reviewedAt.add(const Duration(days: 150));
      expect(
        FreshnessPolicy.lessonLowMid.statusFor(reviewedAt, now),
        FreshnessStatus.notice,
      );
    });

    test('lessonHigh: 61日超で停止（法令系は厳しい）', () {
      final reviewedAt = DateTime(2026, 1, 1);
      final now = reviewedAt.add(const Duration(days: 61));
      expect(
        FreshnessPolicy.lessonHigh.statusFor(reviewedAt, now),
        FreshnessStatus.stopped,
      );
    });

    test('info: 7日超でwarn、31日超で非表示', () {
      final reviewedAt = DateTime(2026, 1, 1);
      expect(
        FreshnessPolicy.info.statusFor(reviewedAt, reviewedAt.add(const Duration(days: 8))),
        FreshnessStatus.warn,
      );
      expect(
        FreshnessPolicy.info.statusFor(reviewedAt, reviewedAt.add(const Duration(days: 31))),
        FreshnessStatus.stopped,
      );
    });
  });
}
