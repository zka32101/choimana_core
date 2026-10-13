import 'package:choimana_core/srs.dart';
import 'package:test/test.dart';

void main() {
  group('Srs.review', () {
    test('正解すると箱が1つ上がり、次のdueAtは新しい箱の間隔分先になる', () {
      final now = DateTime(2026, 1, 1);
      final item = Srs.review(null, qid: 'q1', correct: true, now: now);
      expect(item.box, 1);
      expect(item.dueAt, now.add(Srs.intervals[1]));
    });

    test('不正解だと箱は0に戻り、すぐに再出題される', () {
      final now = DateTime(2026, 1, 1);
      final advanced = SrsItem(qid: 'q1', box: 3, dueAt: now);
      final item = Srs.review(advanced, qid: 'q1', correct: false, now: now);
      expect(item.box, 0);
      expect(item.dueAt, now);
    });

    test('最大の箱を超えて上がらない', () {
      final now = DateTime(2026, 1, 1);
      final maxed = SrsItem(qid: 'q1', box: Srs.maxBox, dueAt: now);
      final item = Srs.review(maxed, qid: 'q1', correct: true, now: now);
      expect(item.box, Srs.maxBox);
    });
  });

  group('Srs.due', () {
    final now = DateTime(2026, 1, 10);

    test('dueAtがnow以前の項目のみを返す', () {
      final items = [
        SrsItem(qid: 'past', box: 1, dueAt: now.subtract(const Duration(days: 1))),
        SrsItem(qid: 'exactly-now', box: 1, dueAt: now),
        SrsItem(qid: 'future', box: 1, dueAt: now.add(const Duration(days: 1))),
      ];

      final due = Srs.due(items, now);

      expect(due.map((i) => i.qid), containsAll(['past', 'exactly-now']));
      expect(due.map((i) => i.qid), isNot(contains('future')));
    });

    test('dueAtが古い順に並ぶ', () {
      final items = [
        SrsItem(qid: 'newer', box: 1, dueAt: now.subtract(const Duration(days: 1))),
        SrsItem(qid: 'oldest', box: 1, dueAt: now.subtract(const Duration(days: 5))),
        SrsItem(qid: 'middle', box: 1, dueAt: now.subtract(const Duration(days: 3))),
      ];

      final due = Srs.due(items, now);

      expect(due.map((i) => i.qid).toList(), ['oldest', 'middle', 'newer']);
    });

    test('dueAtが同時刻なら、定着度（box）が低い項目を先に出す', () {
      final sameDueAt = now.subtract(const Duration(days: 1));
      final items = [
        SrsItem(qid: 'well-retained', box: 4, dueAt: sameDueAt),
        SrsItem(qid: 'struggling', box: 0, dueAt: sameDueAt),
        SrsItem(qid: 'mid-retained', box: 2, dueAt: sameDueAt),
      ];

      final due = Srs.due(items, now);

      expect(due.map((i) => i.qid).toList(), ['struggling', 'mid-retained', 'well-retained']);
    });

    test('dueAt優先・box劣後のソートが正しく組み合わされる', () {
      final older = now.subtract(const Duration(days: 5));
      final newer = now.subtract(const Duration(days: 1));
      final items = [
        SrsItem(qid: 'newer-low-box', box: 0, dueAt: newer),
        SrsItem(qid: 'older-high-box', box: 4, dueAt: older),
        SrsItem(qid: 'older-low-box', box: 0, dueAt: older),
      ];

      final due = Srs.due(items, now);

      // dueAtが古い2件（box順）が先、newerは最後。
      expect(due.map((i) => i.qid).toList(), ['older-low-box', 'older-high-box', 'newer-low-box']);
    });

    test('limitを指定すると先頭からその件数に切り詰める', () {
      final items = [
        SrsItem(qid: 'a', box: 0, dueAt: now.subtract(const Duration(days: 3))),
        SrsItem(qid: 'b', box: 0, dueAt: now.subtract(const Duration(days: 2))),
        SrsItem(qid: 'c', box: 0, dueAt: now.subtract(const Duration(days: 1))),
      ];

      final due = Srs.due(items, now, limit: 2);

      expect(due.map((i) => i.qid).toList(), ['a', 'b']);
    });

    test('limitが対象件数以上なら全件返す', () {
      final items = [
        SrsItem(qid: 'a', box: 0, dueAt: now.subtract(const Duration(days: 1))),
      ];

      final due = Srs.due(items, now, limit: 10);

      expect(due.length, 1);
    });
  });
}
