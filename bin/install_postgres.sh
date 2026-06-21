#!/bin/sh
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
#
# Usage:
#    install_postgres.sh
# 
# Description:
#    This script installs PostgreSQL based on defined version and port.
#
# Design documents
#    None
#
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
# ＜変更履歴＞
# Ver. 変更管理No. 日付        更新者       変更内容
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/

. "$(dirname "$0")/../com/logger.shrc"
. "$(dirname "$0")/../com/utils.shrc"

# Job status codes
JOB_OK=0
JOB_WR=1
JOB_ER=2
rc=$JOB_ER

# ----------------------------------------------------------
# functions terminate
# ----------------------------------------------------------
terminate() {
    releaseLock
}

# ----------------------------------------------------------
# functions checkArgs
# ----------------------------------------------------------
checkArgs() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        logOut "ERROR" "引数が不足しています。使用方法: install_postgres.sh <version> <port>"
        exit $JOB_ER
    fi
}

# ----------------------------------------------------------
# functions checkConf
# ----------------------------------------------------------
checkConf() {
    :
}

# ====== PostgreSQL設定ファイルの作成（ダミー） ======

if [ -z "$ETC_PATH" ]; then
  ETC_PATH="/etc"
fi

mkdir -p "$ETC_PATH"

TEMPLATE_FILE="$ETC_PATH/postgres_install.cfg"

if [ -f "$TEMPLATE_FILE" ]; then
  mv "$TEMPLATE_FILE" "${TEMPLATE_FILE}.bak_$(date +%Y%m%d%H%M%S)"
fi

cat <<EOT > "$TEMPLATE_FILE"
# PostgreSQL 設定ファイル
VERSION=$1
PORT=$2
EOT

# ----------------------------------------------------------
# pre-process
# ----------------------------------------------------------
scope="pre"

hostname=dev01
os=Linux
temp_list="$TEMPLATE_FILE"

startLog
logOut "INFO" args: ["$@"]

if acquireLock; then
  logOut "INFO" "ロックを取得しました。"
else
  abort "ロックの取得に失敗しました。"
fi

trap "terminate" 0 1 2 3 15

checkArgs $1 $2

# ----------------------------------------------------------
# main-routine
# ----------------------------------------------------------
scope="main"

if [ ! -f "$temp_list" ]; then
    logOut "ERROR" "設定ファイルが存在しません: $temp_list"
    exitLog $JOB_ER
fi

sed '/^#/d;/^[[:blank:]]*$/d' "$temp_list" | while IFS= read -r line; do
    logOut "DEBUG" "処理対象: [$line]"
    # 処理をここに記述
    sleep 1
    if [ $? -ne 0 ]; then
        logOut "ERROR" "処理失敗: [$line]"
        exitLog $JOB_ER
    fi
done

rc=$JOB_OK

# ----------------------------------------------------------
# post-process
# ----------------------------------------------------------
scope="post"

exitLog $rc