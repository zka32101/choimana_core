# choimana_core

「ちょいまな」（資格以外の大人の学び。お金→AI活用→仕事スキル→暮らしの法律・制度→語学・教養）の共通基盤。

## 依存の向き

```
アプリ（ちょいまな お金 / AI活用 など）
 → choimana_core（このリポジトリ）
 → yourwish_learn（学習の共通部分。未切り出し。切り出すまでは choimana_core 内に型部品を先行実装）
 → app_common_kit（フィードバック・権利・広告ゲート・テーマ・UI・推し・コイン）
```

## v0.1 で実装したもの（段階2）

- `Lesson` / `Track` / `LessonCard` / `Quiz` / `LessonAction`: 3分レッスン（導入の1問→要点カード3枚以内→確認問題2〜3問→今日の一歩）
- `Freshness`: コンテンツ種別・ランクごとの鮮度判定（レッスン低中90/120/180日、高ランク30/45/60日、情報7/14/30日）
- `BoundaryRule`（型①境界線スライダーの土台）: 条件→結論＋根拠＋施行日。出典・施行日必須
- `Calculator` / `Parameter`（型②予測→実行の土台）: 目安の計算。定数は出典・施行日つきの Parameter 表から
- `DailyPick` / `Srs`: 今日の1レッスン＋復習1問の選定
- `DeliveryClient` / `Manifest`: 署名付き配信データの取得・検証・保存（失敗時は前回分を維持）

CaseCard・Digest・Lab・Recipe は AI活用ジャンルの着手時（段階3）に追加する。

## 検討したが choimana_core には実装しない設計判断

うかラボ（yourwish_kentei）・小これ（shogaku_kore）を参考に調査した機能案のうち、
以下は choimana_core の範囲外と判断した（2026-10-13）。

- **UsageQuota/KeyValueStore（回数制限の共通基盤）**: うかラボの `policy/usage_quota.dart`
  は無料枠の回数制限（模擬試験月1回・復習日10問等）を Flutter非依存で計算する部品。
  choimana でも「復習は1日何問まで」等の無料枠は将来必要になりうるが、依存の向き図の通り
  **権利・広告ゲートは `app_common_kit` の役割**と既に位置づけられている。`app_common_kit`
  が切り出されるまでは choimana_core に先行実装せず待つ（`yourwish_learn` の型部品を
  choimana_core に先行実装したのとは異なり、こちらは責務の境界がはっきり決まっているため）。
- **ProgressRecord/reviewPriorityQids（軽量版の復習優先度）**: 永続化状態を持たず解答履歴
  だけから復習優先度を計算する、フルSRSより前段の軽量版。choimana_core は既に
  `Srs`（Leitner方式）を持っており、追加の必要性は薄いため見送り。

## 開発

```
dart pub get
dart analyze
dart test
```
