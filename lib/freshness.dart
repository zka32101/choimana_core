/// 鮮度管理（共通基盤設計 v0.5 §7）。
///
/// コンテンツ種別ごとに、最終確認日([reviewedAt])からの経過日数で
/// 配信可否の段階を判定する。数値はすべて設計書の既定値。
library;

enum FreshnessStatus {
  /// 通常。
  ok,

  /// 社内向けの警告（CIで検出。利用者には見えない）。
  warn,

  /// 利用者に「情報が古い可能性があります」を表示する段階。
  notice,

  /// 配信停止（非表示）。
  stopped,
}

/// 種別ごとの閾値（日数）。[warnAfterDays] を超えたら warn、
/// [noticeAfterDays] を超えたら notice、[stopAfterDays] を超えたら stopped。
class FreshnessPolicy {
  const FreshnessPolicy({
    required this.warnAfterDays,
    required this.noticeAfterDays,
    required this.stopAfterDays,
  }) : assert(warnAfterDays <= noticeAfterDays),
       assert(noticeAfterDays <= stopAfterDays);

  final int warnAfterDays;
  final int noticeAfterDays;
  final int stopAfterDays;

  /// レッスン（低・中ランク）: 90日/120日/180日。
  static const lessonLowMid = FreshnessPolicy(
    warnAfterDays: 90,
    noticeAfterDays: 120,
    stopAfterDays: 180,
  );

  /// レッスン（高ランク・法令に触れるもの）: 30日/45日/60日。
  static const lessonHigh = FreshnessPolicy(
    warnAfterDays: 30,
    noticeAfterDays: 45,
    stopAfterDays: 60,
  );

  /// 情報・コツ・アラート（今週のAI等）: 7日/14日/30日。31日超で非表示。
  static const info = FreshnessPolicy(
    warnAfterDays: 7,
    noticeAfterDays: 14,
    stopAfterDays: 30,
  );

  /// 価格表・回答比べ（Lab系データ）: 既定30日。ジャンル・用途で短縮可。
  static const priceTable = FreshnessPolicy(
    warnAfterDays: 7,
    noticeAfterDays: 14,
    stopAfterDays: 30,
  );

  FreshnessStatus statusFor(DateTime reviewedAt, DateTime now) {
    final ageDays = now.difference(reviewedAt).inDays;
    if (ageDays > stopAfterDays) return FreshnessStatus.stopped;
    if (ageDays > noticeAfterDays) return FreshnessStatus.notice;
    if (ageDays > warnAfterDays) return FreshnessStatus.warn;
    return FreshnessStatus.ok;
  }
}

/// [reviewedAt]・[nextReviewAt]・鮮度ポリシーを持つコンテンツの共通判定。
mixin FreshnessAware {
  DateTime get reviewedAt;
  FreshnessPolicy get freshnessPolicy;

  FreshnessStatus freshnessStatusAt(DateTime now) =>
      freshnessPolicy.statusFor(reviewedAt, now);

  /// 配信してよいか（stopped でなければ配信可）。
  bool isDeliverableAt(DateTime now) =>
      freshnessStatusAt(now) != FreshnessStatus.stopped;

  /// 利用者に「情報が古い可能性があります」を出すべきか。
  bool needsStaleNoticeAt(DateTime now) =>
      freshnessStatusAt(now) == FreshnessStatus.notice;
}
