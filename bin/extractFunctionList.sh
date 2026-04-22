#!/bin/bash
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
#
# Usage:
#    extractFunctionList.sh <file_path>
#
# Description:
#    Extracts function names from a shell script file and outputs them
#    to stdout, one per line.
#    Supports .sh and .shrc files.
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
# 関数名　　：checkArgs
# 概要　　　：引数の妥当性を確認する
# 説明　　　：
#   引数が1つ指定されているか、対象ファイルの存在・読み取り可否・
#   拡張子（.sh / .shrc）を確認します。
#   不正な場合は abort して終了します。
#
# 引数　　　：$1:対象ファイルパス
# 戻り値　　：0:正常 2:異常
# 使用箇所　：pre-process
# ------------------------------------------------------------------
checkArgs() {
  if [ "$#" -ne 1 ]; then
    abort "Usage: extractFunctionList.sh <file_path>"
  fi
  if [ ! -f "$1" ]; then
    abort "File not found: $1"
  fi
  if [ ! -r "$1" ]; then
    abort "File not readable: $1"
  fi
  case "$1" in
    *.sh|*.shrc) ;;
    *) abort "Unsupported file type: $1" ;;
  esac
}

# ------------------------------------------------------------------
# 関数名　　：extractFunctionList
# 概要　　　：関数名一覧を抽出して標準出力する
# 説明　　　：
#   対象ファイルから以下の形式の関数定義行を抽出し、
#   関数名を1行ずつ標準出力します。
#     - function funcName() {
#     - funcName() {
#     - function funcName {
#   0件の場合は rc に JOB_WR をセットします。
#
# 引数　　　：$1:対象ファイルパス
# 戻り値　　：0:正常 1:0件検出
# 使用箇所　：main-routine
# ------------------------------------------------------------------
extractFunctionList() {
  local target_file="$1"
  local func_list
  local count

  logOut "DEBUG" "target: ${target_file}"
  logOut "DEBUG" "抽出開始"

  func_list=$(grep -E '^[[:blank:]]*(function[[:blank:]]+[a-zA-Z_][a-zA-Z0-9_]*([[:blank:]]*\(\))?[[:blank:]]*\{?|[a-zA-Z_][a-zA-Z0-9_]*[[:blank:]]*\(\)[[:blank:]]*\{?)' "${target_file}" \
    | sed 's/^[[:blank:]]*//' \
    | sed 's/^function[[:blank:]]*//' \
    | sed 's/[[:blank:]]*(.*//' \
    | sed 's/[[:blank:]]*{.*//')

  if [ -n "${func_list}" ]; then
    count=$(printf '%s\n' "${func_list}" | wc -l | awk '{print $1}')
    printf '%s\n' "${func_list}"
  else
    count=0
    rc=${JOB_WR}
  fi

  logOut "DEBUG" "抽出終了: ${count}件"
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

# ----------------------------------------------------------
# main-routine
# ----------------------------------------------------------
scope="main"

rc=${JOB_OK}
extractFunctionList "$1"

# ----------------------------------------------------------
# post-process
# ----------------------------------------------------------
# shellcheck disable=SC2034
scope="post"

exitLog "${rc}"
