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

## 開発

```
dart pub get
dart analyze
dart test
```
