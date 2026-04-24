# Usage ルール

## 目的

このファイルは、実行時 Usage と Usage 実装に関する規約を定義する。

## 実行時 Usage ルール

新規作成する実行 Shell には、実行時の Usage を必ず実装すること。

### 表示フォーマット

- 先頭行と最終行は正確に `--------------------------------------` を出力する（38文字）
- 区切りラインの文字数や記号を勝手に変更しない
- `Usage:` 見出しを必ず入れる
- 実行時 Usage には必ず `Options:` を含める
- 実行時 Usage には必ず `Example:` を含める
- 各行は期待する表示例と1行単位で一致させる
- 実行時に表示する内容は実装仕様と一致させる
- 先頭が `-` の文字列や区切りラインを `printf` の format 文字列にしない
- ハイフン始まりの行は `printf '%s\n' '文字列'` の形式で出力する
- `Example:` は省略しない
- `Example:` には実際の実装仕様に一致する実行例を1つ以上記載する
- `Example:` に存在しないオプションや未実装の引数を書かない

Usage 見本:

```text
--------------------------------------
Usage:
  bash listShellDependencies.sh <file_path>

Options:
  -h, --help : Usage を表示

Example:
  bash listShellDependencies.sh /path/to/target.sh
--------------------------------------
```

## Usage実装ルール

- Usage はヘッダコメントだけで終わらせない
- Usage 表示用の関数は表示専用にする
- Usage 表示用の関数の中で `abort` を呼ばない
- Usage 表示用の関数の中で `exitLog` を呼ばない
- Usage 表示用の関数の中で終了制御をしない
- Usage 表示用の関数は必ずヒアドキュメントで実装する
- Usage 表示で `echo` を並べる実装は禁止する
- Usage 表示で `printf` を並べる実装は禁止する
- Usage 表示は `cat <<'EOF'` または `cat >&2 <<'EOF'` の形式に統一する
- Usage の文面・空行・区切りラインはヒアドキュメント内に固定で記載する
- オプションは、実装上の制約がない限り `-` 1つの短縮形を基本とする
- `--help` のような長い形式は、明示的に必要な場合だけ追加する

`usage()` 見本

```sh
usage() {
    cat >&2 <<'EOF'
--------------------------------------
Usage:
  bash backupFiles.sh -b <backup_directory>

Options:
  -b backup_directory : バックアップ保存先ディレクトリ

Example:
  bash backupFiles.sh -b /path/to/backup
--------------------------------------
EOF
}
```
