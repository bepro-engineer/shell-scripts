#!/bin/bash
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
#
# Usage:
#    countStepLines.sh <file_path>
#
# Description:
#    Counts effective step lines in a file.
#    Excludes blank lines and comment lines (lines starting with #).
#
# Design documents
#    None
#
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
# ＜変更履歴＞
# Ver. 変更管理No. 日付        更新者       変更内容
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/

# shellcheck disable=SC1091
. "$(dirname "${BASH_SOURCE[0]}")/../com/logger.shrc"
. "$(dirname "${BASH_SOURCE[0]}")/../com/utils.shrc"

# runAs       root "$@"
# setLANG     utf-8

# ----------------------------------------------------------
# variables
# ----------------------------------------------------------
scope="var"

# Job status codes
JOB_OK=0  # Normal exit
JOB_WR=1  # Warning exit
JOB_ER=2  # Error exit

# Global variables
rc=${JOB_ER}
scope=""

# ----------------------------------------------------------
# functions
# ----------------------------------------------------------
scope="func"

# ------------------------------------------------------------------
# 関数名　　：terminate
# 概要　　　：終了時の共通後処理を行う
# 説明　　　：
#   trap から呼び出される終了処理です。
#   ロック解放などの後処理を実施します。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：trap
# ------------------------------------------------------------------
terminate() {
  releaseLock
}

# ------------------------------------------------------------------
# 関数名　　：showUsage
# 概要　　　：使用方法を標準エラーに出力する
# 説明　　　：
#   スクリプトの使用方法を標準エラー出力へ出力します。
#   引数不足・不正引数・ヘルプ指定時に呼び出されます。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：pre-process
# ------------------------------------------------------------------
showUsage() {
  printf '%s\n' '--------------------------------------' >&2
  printf 'Usage:\n' >&2
  printf 'sh countStepLines.sh <file_path>\n' >&2
  printf '\n' >&2
  printf 'Options:\n' >&2
  printf '%s\n' '-h, --help : Usage を表示' >&2
  printf '\n' >&2
  printf 'Example:\n' >&2
  printf 'sh countStepLines.sh /path/to/target.sh\n' >&2
  printf '%s\n' '--------------------------------------' >&2
}

# ------------------------------------------------------------------
# 関数名　　：checkArgs
# 概要　　　：引数の妥当性を確認する
# 説明　　　：
#   引数の内容を判定し、戻り値で結果を返します。
#   終了制御・表示は呼び出し元が行います。
#     0: 正常（続行）
#     1: -h / --help 指定
#     2: 引数なし・引数過多・不正オプション
#     3: ファイル不存在
#
# 引数　　　：$1:対象ファイルパス
# 戻り値　　：0:正常 1:ヘルプ 2:引数エラー 3:ファイル不存在
# 使用箇所　：pre-process
# ------------------------------------------------------------------
checkArgs() {
  case "${1:-}" in
    -h|--help) return 1 ;;
    -*)        return 2 ;;
  esac
  if [ "$#" -ne 1 ]; then return 2; fi
  if [ ! -f "$1" ]; then return 3; fi
}

# ------------------------------------------------------------------
# 関数名　　：countStepLines
# 概要　　　：実ステップ数を数えて標準出力する
# 説明　　　：
#   対象ファイルから空行とコメント行（# 始まり）を除外し、
#   実ステップ数を数えて標準出力します。
#
# 引数　　　：$1:対象ファイルパス
# 戻り値　　：0:正常
# 使用箇所　：main-routine
# ------------------------------------------------------------------
countStepLines() {
  local target_file="$1"
  local step_count

  step_count=$(sed '/^[[:blank:]]*#/d;/^[[:blank:]]*$/d' "${target_file}" | wc -l | awk '{print $1}')

  logOut "DEBUG" "target: ${target_file}"
  logOut "DEBUG" "step count: ${step_count}"
  echo "${step_count}"
}

# ----------------------------------------------------------
# pre-process
# ----------------------------------------------------------
scope="pre"

startLog
trap "terminate" HUP INT QUIT TERM

logOut "DEBUG" "args: [$*]"

if acquireLock; then
  logOut "INFO" "successfully locked."
else
  abort "could not acquire lock."
fi

checkArgs "$@"
case $? in
  1) showUsage; rc=${JOB_OK}; exitLog "${rc}" ;;
  2) case "${1:-}" in
       -*) logOut "ERROR" "Unknown option: $1" ;;
       '') logOut "ERROR" "Argument required." ;;
       *)  logOut "ERROR" "Too many arguments." ;;
     esac
     showUsage; rc=${JOB_ER}; exitLog "${rc}" ;;
  3) logOut "ERROR" "File not found: $1"; rc=${JOB_ER}; exitLog "${rc}" ;;
esac

# ----------------------------------------------------------
# main-routine
# ----------------------------------------------------------
scope="main"

countStepLines "$1"
rc=${JOB_OK}

# ----------------------------------------------------------
# post-process
# ----------------------------------------------------------
# shellcheck disable=SC2034
scope="post"

exitLog "${rc}"
