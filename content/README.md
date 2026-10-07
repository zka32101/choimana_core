# content/

配信データ（JSON）の置き場。`tool/validate_content.dart` がここを検証する。

- `lessons/*.json` — `Lesson.toJson()` の形式
- `boundary_rules/*.json` — `BoundaryRule.toJson()` の形式

v0.1時点ではまだ実データがない（kinnyuからの移植待ち）。ディレクトリが
空でもCIは正常終了する。
