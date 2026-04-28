# shell-scripts

Shell スクリプト群の作成・整理・見直しを行うリポジトリ。

## ディレクトリ構成

```
bin/        実行スクリプト
com/        共通シェルスクリプト（source して使用）
etc/        設定ファイル
rep/        レポート出力先
tmp/        一時ファイル・ロックファイル
templates/  新規スクリプト作成用雛形
rules/      コーディング規約ドキュメント
```

## スクリプト一覧

### bin/

| スクリプト | 用途 | root |
|---|---|:---:|
| `backupFiles.sh` | 指定ディレクトリ配下をアーカイブしてバックアップする | 必須 |
| `compress.sh` | ファイル／ディレクトリを zstd 形式で圧縮する | 必須 |
| `dirTransfer.sh` | rsync を使ったアトミックなディレクトリ転送（コピー／移動） | 必須 |
| `fileTransfer.sh` | .end/.fin による状態管理付きファイル送受信 | 必須 |
| `resourceAlert.sh` | CPU／メモリ使用率を監視してしきい値超過をアラートする | 必須 |
| `countStepLines.sh` | ファイルの実ステップ数（空行・コメント行を除く行数）を計測する | 不要 |
| `extractFunctionList.sh` | Shell スクリプトから関数名一覧を抽出する | 不要 |
| `listShellDependencies.sh` | Shell スクリプトから source / . による依存ファイル一覧を抽出する | 不要 |

### com/

| ファイル | 用途 |
|---|---|
| `logger.shrc` | ログ制御関数（`logOut` / `startLog` / `exitLog`）を提供する |
| `utils.shrc` | ロック制御・プロセス管理・文字列操作などの共通ユーティリティを提供する |

### templates/

| ファイル | 用途 |
|---|---|
| `basicTemplate.sh` | 新規スクリプト作成時の骨格雛形 |

## 共通仕様

### 終了コード

| 変数 | 値 | 意味 |
|---|---|---|
| `JOB_OK` | 0 | 正常終了 |
| `JOB_WR` | 1 | 警告終了 |
| `JOB_ER` | 2 | 異常終了 |

### ログ出力

```bash
logOut "INFO"  "message"
logOut "WARN"  "message"
logOut "ERROR" "message"
logOut "DEBUG" "message"
```

デフォルトのログ出力先は CONSOLE（標準出力）。`DEFAULT_LOG_MODE="FILE"` に変更するとログファイル（`log/<script_name>.log`）へ書き出す。

### 共通ファイルの読み込み

```bash
. "$(dirname "$0")/../com/logger.shrc"
. "$(dirname "$0")/../com/utils.shrc"
```

読み込み順は必ず `logger.shrc` → `utils.shrc`。

### 環境変数

| 変数 | デフォルト値 | 用途 |
|---|---|---|
| `BASE_PATH` | `/home/bepro/projects/shell-scripts` | プロジェクトルート |
| `LOG_PATH` | `${BASE_PATH}/log` | ログ出力先 |
| `TMP_PATH` | `${BASE_PATH}/tmp` | 一時ファイル・ロックファイル |
| `ETC_PATH` | `${BASE_PATH}/etc` | 設定ファイル |

## 実行例

### 非 root スクリプト

```bash
# 実ステップ数を計測する
bash bin/countStepLines.sh bin/countStepLines.sh

# 関数名一覧を抽出する
bash bin/extractFunctionList.sh bin/someScript.sh

# source 依存ファイル一覧を抽出する
bash bin/listShellDependencies.sh bin/someScript.sh
```

### root 必須スクリプト

```bash
# バックアップを実行する
sudo bash bin/backupFiles.sh -b /path/to/backup

# zstd で圧縮する（元データ保持）
sudo bash bin/compress.sh -s /path/to/src -d /path/to/output.zst -m 0

# ディレクトリをコピー転送する
sudo bash bin/dirTransfer.sh -d /path/srcDir -t /path/targetBaseDir -m 0

# CPU 使用率を監視する
sudo bash bin/resourceAlert.sh -m cpu
```

### ヘルプ表示

```bash
bash bin/countStepLines.sh -h
bash bin/extractFunctionList.sh --help
bash bin/listShellDependencies.sh -h
```
