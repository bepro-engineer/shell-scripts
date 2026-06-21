#!/bin/bash
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
# スクリプト名　：serverResourceCheck.sh
# 概要　　　　：サーバーリソース状況を確認する
# 説明　　　　：
#   CPU・メモリ・ディスク・iノード・プロセスのリソース情報を標準出力に出力する。
#   外部ツール依存を最小にし、/proc ファイルシステムを優先して使用する。
#
# 引数　　　　：
#   -h : Usage を表示
#
# 戻り値　　　：0=成功, 2=異常
# 使用箇所　　：サーバー状況の確認・定期レポート
#
# 設計書　　　：なし
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
# ＜変更履歴＞
# Ver. 変更管理No. 日付        更新者       変更内容
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/

set -u

# ----------------------------------------------------------
# variables
# ----------------------------------------------------------
scope="var"

JOB_OK=0
JOB_WR=1
JOB_ER=2

rc=${JOB_ER}
scope=""

# ----------------------------------------------------------
# functions
# ----------------------------------------------------------
scope="func"

# ------------------------------------------------------------------
# 関数名　　：usage
# 概要　　　：Usage を表示する
# 説明　　　：
#   スクリプトの使用方法を標準エラーに出力する。
#   終了制御はこの関数内では行わない。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：checkArgs
# ------------------------------------------------------------------
usage() {
  cat >&2 <<'EOF'
--------------------------------------
Usage:
  bash serverResourceCheck.sh

Options:
  -h : Usage を表示

Example:
  bash serverResourceCheck.sh
--------------------------------------
EOF
}

# ------------------------------------------------------------------
# 関数名　　：checkArgs
# 概要　　　：引数の妥当性を確認する
# 説明　　　：
#   -h オプションは Usage 表示後に JOB_OK で終了する。
#   不正なオプションは Usage 表示後に JOB_ER で終了する。
#   引数なしは正常とみなす。
#
# 引数　　　：スクリプト引数一式
# 戻り値　　：なし（エラー時は当該関数内で終了）
# 使用箇所　：pre-process
# ------------------------------------------------------------------
checkArgs() {
  while getopts ":h" opt; do
    case "${opt}" in
      h)
        usage
        exit "${JOB_OK}"
        ;;
      *)
        usage
        exit "${JOB_ER}"
        ;;
    esac
  done
}

# ------------------------------------------------------------------
# 関数名　　：printSection
# 概要　　　：セクション区切りと見出しを出力する
# 説明　　　：
#   セクションの区切り線と見出しタイトルを標準出力に出力する。
#
# 引数　　　：$1 : セクション見出し文字列
# 戻り値　　：なし
# 使用箇所　：show* 系関数
# ------------------------------------------------------------------
printSection() {
  printf '\n'
  printf '%s\n' '============================================================'
  printf '%s\n' "$1"
  printf '%s\n' '============================================================'
}

# ------------------------------------------------------------------
# 関数名　　：showBasicInfo
# 概要　　　：基本情報を出力する
# 説明　　　：
#   現在日時・ホスト名・カーネルバージョン・稼働時間を出力する。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：main
# ------------------------------------------------------------------
showBasicInfo() {
  printSection "BASIC INFO"
  printf 'DATE      : %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
  printf 'HOSTNAME  : %s\n' "$(hostname 2>/dev/null || printf 'unknown')"
  printf 'KERNEL    : %s\n' "$(uname -r 2>/dev/null || printf 'unknown')"
  printf 'UPTIME    : %s\n' "$(uptime 2>/dev/null || printf 'unknown')"
}

# ------------------------------------------------------------------
# 関数名　　：showLoadAverage
# 概要　　　：ロードアベレージを出力する
# 説明　　　：
#   /proc/loadavg が読み取れる場合はその値を使用する。
#   読み取れない場合は uptime コマンドの出力にフォールバックする。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：main
# ------------------------------------------------------------------
showLoadAverage() {
  printSection "LOAD AVERAGE"
  if [ -r /proc/loadavg ]; then
    awk '{printf "1min: %s\n5min: %s\n15min: %s\nrunning/total: %s\nlast_pid: %s\n", $1, $2, $3, $4, $5}' /proc/loadavg
  else
    uptime
  fi
}

# ------------------------------------------------------------------
# 関数名　　：showCpuUsage
# 概要　　　：CPU 使用率を出力する
# 説明　　　：
#   /proc/stat を 1 秒間隔で 2 回読み取り、差分から CPU 使用率を算出する。
#   /proc/stat が読み取れない場合はエラーメッセージを出力して JOB_ER を返す。
#
# 引数　　　：なし
# 戻り値　　：0=成功, 2=異常
# 使用箇所　：main
# ------------------------------------------------------------------
showCpuUsage() {
  printSection "CPU USAGE"

  if [ ! -r /proc/stat ]; then
    printf 'ERROR: /proc/stat is not readable\n'
    return "${JOB_ER}"
  fi

  read -r _ user1 nice1 system1 idle1 iowait1 irq1 softirq1 steal1 _ < /proc/stat
  sleep 1
  read -r _ user2 nice2 system2 idle2 iowait2 irq2 softirq2 steal2 _ < /proc/stat

  local idle_before=$((idle1 + iowait1))
  local idle_after=$((idle2 + iowait2))

  local non_idle_before=$((user1 + nice1 + system1 + irq1 + softirq1 + steal1))
  local non_idle_after=$((user2 + nice2 + system2 + irq2 + softirq2 + steal2))

  local total_before=$((idle_before + non_idle_before))
  local total_after=$((idle_after + non_idle_after))

  local total_delta=$((total_after - total_before))
  local idle_delta=$((idle_after - idle_before))

  if [ "${total_delta}" -le 0 ]; then
    printf 'CPU usage: unknown\n'
    return "${JOB_OK}"
  fi

  awk -v total="${total_delta}" -v idle="${idle_delta}" \
    'BEGIN { printf "CPU usage: %.2f%%\n", (100 * (total - idle) / total) }'
}

# ------------------------------------------------------------------
# 関数名　　：showMemoryUsage
# 概要　　　：メモリ使用量を出力する
# 説明　　　：
#   free -m コマンドでメモリ使用量（MB 単位）を出力する。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：main
# ------------------------------------------------------------------
showMemoryUsage() {
  printSection "MEMORY"
  free -m
}

# ------------------------------------------------------------------
# 関数名　　：showDiskUsage
# 概要　　　：ディスク使用量を出力する
# 説明　　　：
#   tmpfs・devtmpfs を除くファイルシステムのディスク使用量を出力する。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：main
# ------------------------------------------------------------------
showDiskUsage() {
  printSection "DISK"
  df -hP -x tmpfs -x devtmpfs
}

# ------------------------------------------------------------------
# 関数名　　：showInodeUsage
# 概要　　　：iノード使用量を出力する
# 説明　　　：
#   tmpfs・devtmpfs を除くファイルシステムの iノード使用量を出力する。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：main
# ------------------------------------------------------------------
showInodeUsage() {
  printSection "INODE"
  df -ihP -x tmpfs -x devtmpfs
}

# ------------------------------------------------------------------
# 関数名　　：showTopProcesses
# 概要　　　：リソース上位プロセスを出力する
# 説明　　　：
#   CPU 使用率上位 10 件とメモリ使用率上位 10 件のプロセスを出力する。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：main
# ------------------------------------------------------------------
showTopProcesses() {
  printSection "TOP CPU PROCESSES"
  ps -eo pid,ppid,user,stat,%cpu,%mem,etime,comm --sort=-%cpu | head -11

  printSection "TOP MEMORY PROCESSES"
  ps -eo pid,ppid,user,stat,%cpu,%mem,etime,comm --sort=-%mem | head -11
}

# ------------------------------------------------------------------
# 関数名　　：main
# 概要　　　：メイン処理を実行する
# 説明　　　：
#   各リソース確認関数を順に呼び出し、結果を標準出力に出力する。
#
# 引数　　　：なし
# 戻り値　　：0=成功
# 使用箇所　：スクリプト本体
# ------------------------------------------------------------------
main() {
  showBasicInfo
  showLoadAverage
  showCpuUsage
  showMemoryUsage
  showDiskUsage
  showInodeUsage
  showTopProcesses

  return "${JOB_OK}"
}

# ----------------------------------------------------------
# pre-process
# ----------------------------------------------------------
scope="pre"

checkArgs "$@"

# ----------------------------------------------------------
# main-routine
# ----------------------------------------------------------
scope="main"

main
rc=$?

# ----------------------------------------------------------
# post-process
# ----------------------------------------------------------
scope="post"

exit "${rc}"
