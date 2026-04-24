# 設定ファイル配置ルール

## 目的

このファイルは、Shell スクリプトで使用する設定ファイルの配置規約を定義する。

## ノード別設定ファイル配置ルール

- ノードごとに値が異なる設定ファイルは、`${ETC_PATH}/$(hostname -s)` 配下に配置する
- 複数ノードで同一スクリプトを使用する場合、設定ファイル名の競合を避けるため、ホスト名単位でディレクトリを分ける
- resourceAlert.sh のしきい値設定ファイルは、`${ETC_PATH}/$(hostname -s)` 配下に配置する

## resourceAlert.sh のしきい値設定ファイル

resourceAlert.sh では、下記の設定ファイルを使用する。

`${ETC_PATH}/$(hostname -s)/cpu_threshold.conf`

`${ETC_PATH}/$(hostname -s)/disk_threshold.conf`

`${ETC_PATH}/$(hostname -s)/mem_threshold.conf`

## 読み込み例

`host_id=$(hostname -s)`

`threshold_file="${ETC_PATH}/${host_id}/${type}_threshold.conf"`

## 禁止事項

- ノードごとに異なる設定ファイルを `${ETC_PATH}` 直下へ配置しない
- `cpu_threshold.conf`、`disk_threshold.conf`、`mem_threshold.conf` を全ノード共通ファイルとして扱わない
- ホスト名ディレクトリを経由せずに resourceAlert.sh のしきい値設定ファイルを参照しない
