# resource-check サンプル一式

## このディレクトリの位置づけ

本ディレクトリのスクリプトは **本番用ではない**。  
客先環境で「どの情報が取得できるか」を確認してもらうための、取得観点確認用サンプルである。

客先と取得観点を合意した後、必要な観点だけを `bin/` 側で正式なスクリプトとして実装する。

- `sar` は取得観点の候補の一つであり、sar 専用のサンプルではない
- Oracle Statspack は OS リソース取得とは別レイヤーの、Oracle DB 側性能情報取得候補として位置づける

## 実行場所の例

```bash
cd /home/bepro/projects/shell-scripts
```

## 注意事項

- root 権限前提ではない
- 外部パッケージの導入は行わない
- `command not found` は、その環境で該当コマンドが使えないことを示す
- 取得可否はサーバー環境に依存する（コマンドが存在しない場合はスキップされる）
- 顧客名・会社名・案件名・実 IP・実ホスト名・環境名・認証情報は書かない
- 実行結果は環境に依存する

## ファイル一覧

| ファイル名 | 役割 |
|------------|------|
| resourceBasicSample.sh | 基本情報確認用。date / hostname / OS / kernel / uptime / CPU数 / load average など |
| resourceCurrentSample.sh | 現在値確認用。CPU / memory / swap / disk / inode など |
| resourceSarSample.sh | sar 利用可否と sar による性能情報取得例 |
| resourceVmstatSample.sh | vmstat による負荷傾向確認例 |
| resourceIoSample.sh | iostat / df / inode などI/O系確認例 |
| resourceNetworkSample.sh | IP / NIC / routing / LISTENポート確認例 |
| resourceProcessSample.sh | CPU上位 / メモリ上位プロセス確認例 |
| resourceOracleStatspackSample.sh | Oracle Statspack の前提確認用。sqlplus / ORACLE_HOME / ORACLE_SID / Statspack関連SQLファイルなど |

### Oracle Statspack サンプルについて

`resourceOracleStatspackSample.sh` は OS リソース取得とは別レイヤーの、**Oracle DB 側の性能情報取得候補**として位置づける。

**実行例**

```bash
bash samples/resource-check/resourceOracleStatspackSample.sh
```

**目的**

Oracle Statspack の取得可否を確認するための前提情報を表示する。

**確認する内容**

- sqlplus が使えるか
- ORACLE_HOME が設定されているか
- ORACLE_SID が設定されているか
- spreport.sql / spauto.sql など Statspack 関連 SQL ファイルが存在するか

**注意事項**

- このShellはDBへ自動ログインしない
- ユーザー名、パスワード、接続文字列は扱わない
- Statspackレポートを自動取得する本番Shellではない
- 本番DBへ問い合わせを投げない
- 客先確認後に、必要な取得範囲だけ正式Shellへ反映する

## 実行方法

### 構文確認

```bash
bash -n samples/resource-check/*.sh
```

### bash コマンドでの実行例

```bash
bash samples/resource-check/resourceBasicSample.sh
bash samples/resource-check/resourceCurrentSample.sh
bash samples/resource-check/resourceSarSample.sh
bash samples/resource-check/resourceVmstatSample.sh
bash samples/resource-check/resourceIoSample.sh
bash samples/resource-check/resourceNetworkSample.sh
bash samples/resource-check/resourceProcessSample.sh
bash samples/resource-check/resourceOracleStatspackSample.sh
```

### 実行権限を付ける場合

```bash
chmod 755 samples/resource-check/*.sh
```

### 実行権限付与後の直接実行例

```bash
./samples/resource-check/resourceBasicSample.sh
./samples/resource-check/resourceOracleStatspackSample.sh
```

## 正式化の流れ

1. 各サンプルを客先環境で実行して取得可否を確認する
2. 取得が必要な観点を客先と合意する
3. 合意した観点を `bin/` 配下に正式なスクリプトとして実装する
4. サンプルはそのまま残す（参照用）
