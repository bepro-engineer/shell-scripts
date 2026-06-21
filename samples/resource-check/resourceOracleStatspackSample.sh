#!/bin/bash
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
# スクリプト名　：resourceOracleStatspackSample.sh
# 概要　　　　：Oracle Statspack 取得前提確認サンプル
# 用途　　　　：Oracle Statspack 取得前提確認（sqlplus・環境変数・SQLファイル存在確認）
# 説明　　　　：
#   Oracle Statspack による性能情報取得の前提となる環境変数・コマンド・
#   関連SQLファイルの存在を確認して標準出力する。
#   本番用ではなく、取得観点の確認を目的としたサンプルである。
#   DB接続・ログイン・問い合わせは一切行わない。
#
# 引数　　　　：
#   -h : Usage を表示
#
# 戻り値　　　：0=正常, 2=異常
# 実行例　　　：bash samples/resource-check/resourceOracleStatspackSample.sh
# 注意事項　　：
#   Statspackレポートを自動取得する本番Shellではない。
#   DBへ自動ログインしない。
#   ユーザー名、パスワード、接続文字列は扱わない。
#   本番DBへ問い合わせを投げない。
#   客先確認後に、必要な取得範囲だけ正式Shellへ反映する。
# 使用箇所　　：取得観点確認用サンプル実行時
#
# 設計書　　　：なし
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
# ＜変更履歴＞
# Ver. 変更管理No. 日付        更新者       変更内容
# 1.0  -           2026-06-21  -            初版作成
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/

# ----------------------------------------------------------
# variables
# ----------------------------------------------------------
JOB_OK=0
JOB_ER=2

# ----------------------------------------------------------
# functions
# ----------------------------------------------------------

# ------------------------------------------------------------------
# 関数名　　：terminate
# 概要　　　：終了時の後処理を行う
# 説明　　　：
#   trap から呼び出される。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：trap
# ------------------------------------------------------------------
terminate() {
  :
}

# ------------------------------------------------------------------
# 関数名　　：usage
# 概要　　　：使用方法を標準エラー出力する
# 説明　　　：
#   このスクリプトの使い方を表示する。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：checkArgs
# ------------------------------------------------------------------
usage() {
  cat >&2 <<'EOF'
--------------------------------------
Usage:
  bash resourceOracleStatspackSample.sh

Options:
  -h : Usage を表示

Example:
  bash resourceOracleStatspackSample.sh
--------------------------------------
EOF
}

# ------------------------------------------------------------------
# 関数名　　：checkArgs
# 概要　　　：引数の妥当性を確認する
# 説明　　　：
#   引数不正を検知した場合は Usage を表示して終了する。
#
# 引数　　　：スクリプト引数一式
# 戻り値　　：なし（エラー時はスクリプトを終了する）
# 使用箇所　：前処理
# ------------------------------------------------------------------
checkArgs() {
  while getopts ":h" opt; do
    case "${opt}" in
      h)
        usage
        exit ${JOB_OK}
        ;;
      \?)
        usage
        exit ${JOB_ER}
        ;;
    esac
  done
  shift $((OPTIND - 1))

  if [ $# -gt 0 ]; then
    usage
    exit ${JOB_ER}
  fi
}

# ------------------------------------------------------------------
# 関数名　　：printSection
# 概要　　　：セクション区切りを出力する
# 説明　　　：
#   セクションタイトルを見やすい形式で出力する。
#
# 引数　　　：$1=セクションタイトル
# 戻り値　　：なし
# 使用箇所　：各確認関数
# ------------------------------------------------------------------
printSection() {
  local title="$1"
  printf '\n=== %s ===\n' "${title}"
}

# ------------------------------------------------------------------
# 関数名　　：checkSqlplus
# 概要　　　：sqlplus コマンドの存在を確認する
# 説明　　　：
#   PATH 上に sqlplus が存在するかどうかを確認して結果を出力する。
#   存在する場合はバージョン表示コマンドのパスも確認する。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：メイン処理
# ------------------------------------------------------------------
checkSqlplus() {
  printSection "sqlplus 存在確認"
  if command -v sqlplus > /dev/null 2>&1; then
    printf 'sqlplus     : FOUND (%s)\n' "$(command -v sqlplus)"
  else
    printf 'sqlplus     : NOT FOUND\n'
  fi
}

# ------------------------------------------------------------------
# 関数名　　：checkOracleEnv
# 概要　　　：Oracle 環境変数の設定状況を確認する
# 説明　　　：
#   ORACLE_HOME と ORACLE_SID の設定有無およびパスの実在を確認する。
#   DB への接続は行わない。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：メイン処理
# ------------------------------------------------------------------
checkOracleEnv() {
  printSection "Oracle 環境変数確認"

  if [ -n "${ORACLE_HOME:-}" ]; then
    printf 'ORACLE_HOME : %s\n' "${ORACLE_HOME}"
    if [ -d "${ORACLE_HOME}" ]; then
      printf 'ORACLE_HOME : directory EXISTS\n'
    else
      printf 'ORACLE_HOME : directory NOT FOUND\n'
    fi
  else
    printf 'ORACLE_HOME : NOT SET\n'
  fi

  if [ -n "${ORACLE_SID:-}" ]; then
    printf 'ORACLE_SID  : %s\n' "${ORACLE_SID}"
  else
    printf 'ORACLE_SID  : NOT SET\n'
  fi
}

# ------------------------------------------------------------------
# 関数名　　：checkStatspackFiles
# 概要　　　：Statspack 関連 SQL ファイルの存在を確認する
# 説明　　　：
#   ORACLE_HOME 配下の Statspack 関連 SQL ファイル（spreport.sql、
#   spauto.sql、spcreate.sql、spdrop.sql）の存在を確認して結果を出力する。
#   ORACLE_HOME が未設定の場合はスキップする。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：メイン処理
# ------------------------------------------------------------------
checkStatspackFiles() {
  printSection "Statspack 関連 SQL ファイル確認"

  if [ -z "${ORACLE_HOME:-}" ]; then
    printf '[INFO] ORACLE_HOME が未設定のためスキップ\n'
    return
  fi

  local statspack_dir="${ORACLE_HOME}/rdbms/admin"
  printf 'Statspack dir : %s\n' "${statspack_dir}"

  if [ ! -d "${statspack_dir}" ]; then
    printf 'Statspack dir : NOT FOUND\n'
    return
  fi

  local sql_files="spreport.sql spauto.sql spcreate.sql spdrop.sql"
  for f in ${sql_files}; do
    if [ -f "${statspack_dir}/${f}" ]; then
      printf '  %-16s : FOUND\n' "${f}"
    else
      printf '  %-16s : NOT FOUND\n' "${f}"
    fi
  done
}

# ----------------------------------------------------------
# pre-process
# ----------------------------------------------------------
trap "terminate" HUP INT QUIT TERM

checkArgs "$@"

# ----------------------------------------------------------
# main-routine
# ----------------------------------------------------------
printf '=== Oracle Statspack 取得前提確認サンプル ===\n'
printf '取得日時 : %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
printf '[NOTE] このスクリプトは DB 接続を行わない。環境確認のみ。\n'

checkSqlplus
checkOracleEnv
checkStatspackFiles

# ----------------------------------------------------------
# post-process
# ----------------------------------------------------------
exit ${JOB_OK}
