#!/bin/sh
# ------------------------------------------------------------------
# メモリ使用率の監視スクリプト
# ------------------------------------------------------------------

. "$(dirname "$0")/../com/utils.shrc"
. "$(dirname "$0")/../com/logger.shrc"
setLANG utf-8
runAs root "$@"

# ------------------------------------------------------------------
# 変数宣言
# ------------------------------------------------------------------
scope="var"

readonly JOB_OK=0
readonly JOB_WR=1
readonly JOB_ER=2

hostname=$(hostname -s)
host_id="$hostname"
conf_path="$ETC_PATH/$host_id/mem_threshold.conf"
mem_list="$conf_path"
mem_record="$NNN_TMP_PATH/mem_alert.rep"
exec_date=$(date "+%Y-%m-%d %H:%M:%S")

# ------------------------------------------------------------------
# 関数定義
# ------------------------------------------------------------------
scope="func"

# ------------------------------------------------------------------
# 終了処理（ロック解除）
# ------------------------------------------------------------------
terminate() {
    releaseLock
}

# ------------------------------------------------------------------
# 設定ファイルと記録ファイルの存在確認
# 引数1：設定ファイルパス
# 引数2：記録ファイルパス
# ------------------------------------------------------------------
validateFiles() {
    [ ! -f "$1" ] && logError "Configuration file not found: $1" && exitLog ${JOB_ER}
    [ ! -f "$2" ] && touch "$2"
}

# ------------------------------------------------------------------
# 引数数の妥当性チェック（0または2のみ許容）
# 引数1：引数の個数
# ------------------------------------------------------------------
validateArgs() {
    [ "$1" -ne 0 ] && [ "$1" -ne 2 ] && logError "Invalid number of arguments." && exitLog ${JOB_ER}
}

# ------------------------------------------------------------------
# pre-process
# ------------------------------------------------------------------
scope="pre"

startLog
logInfo "args: [ $* ]"

if acquireLock; then
    logInfo "Successfully locked."
else
    abort "Could not acquire lock."
fi

trap "terminate" 0 1 2 3 15
validateFiles "$mem_list" "$mem_record"
validateArgs "$#"

# ------------------------------------------------------------------
# main-process
# ------------------------------------------------------------------
scope="main"

# 閾値超過回数と比較値を取得
excess=$(awk '!/^#/ && NF {print $1}' "$mem_list")
usage_src=$(awk '!/^#/ && NF {gsub(/%/, "", $2); print $2}' "$mem_list")
logDebug "Usage_src is : $usage_src %"

# 実メモリ使用率取得
if [ $# -lt 1 ]; then
    usage_act=$(getMemUtilization)
else
    usage_act=$1
    exec_date=$2
fi

usage_act=$(echo "$usage_act" | awk '{printf("%d\n",$1)}')
logDebug "Usage_act is : $usage_act %"
logDebug "Exec_date is : $exec_date"

# しきい値と比較し、記録ファイルを更新
if [ "$usage_act" -ge "$usage_src" ]; then
    echo "$usage_act% $exec_date" >> "$mem_record"
    logWarn "Memory usage exceeded: $usage_act %"
else
    if [ -s "$mem_record" ]; then
        > "$mem_record"
        logDebug "Cleared alert history: $mem_record"
    fi
    logDebug "Memory usage is within normal range."
fi

# 超過回数チェック
exceed_num=$(wc -l < "$mem_record" | tr -d ' ')
logDebug "Exceed_num is : $exceed_num"

# 致命的しきい値も確認してログ出力
if [ "$exceed_num" -ge "$excess" ]; then
    usage_src_err=$(awk '!/^#/ && NF {gsub(/%/, "", $3); print $3}' "$mem_list" | awk '{printf("%d\n",$1)}')
    if [ "$usage_act" -ge "$usage_src_err" ]; then
        logSystem "21003"  # 致命的しきい値超過
    else
        logSystem "11003"  # 通常しきい値超過
    fi
fi

# ------------------------------------------------------------------
# post-process
# ------------------------------------------------------------------
scope="post"
exitLog ${JOB_OK}
