#!/bin/bash
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
# スクリプト名　：backupFiles.sh
# 概要　　　　：指定ディレクトリ配下のファイルをアーカイブとしてバックアップする
# 説明　　　　：
#   指定されたファイル・ディレクトリをアーカイブし、除外リストを考慮して圧縮する。
#   7日以上前のバックアップを自動削除し、異常終了時は trap で後始末を行う。
#
# 引数　　　　：
#   -b <backup_directory> ：バックアップ保存先ディレクトリ
#
# 戻り値　　　：0（正常終了）、2（異常終了）
# 使用箇所　　：定期バックアップ処理
#
# 設計書　　　：なし
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
# ＜変更履歴＞
# Ver. 変更管理No. 日付        更新者       変更内容
# 1.0  PR-0001    2025/07/16 Bepro       新規作成
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/

# 共通クラスの読み込み
# shellcheck disable=SC1091
. "$(dirname "$0")/../com/logger.shrc"
. "$(dirname "$0")/../com/utils.shrc"

# ========================================
# 実行ユーザー確認（root限定）
# ========================================
runAs root "$@"

# ========================================
# 変数定義
# ========================================
scope="var"
readonly JOB_OK=0
readonly JOB_WR=1
readonly JOB_ER=2

target_list="${ETC_PATH}/target.cfg"
ignore_list="${ETC_PATH}/ignore.cfg"
backup_dir=""
backup_file=""
rc=${JOB_ER}

# 警告メッセージ定義
warn_msg01="作成されたバックアップを削除しました。"

# エラーメッセージ定義
err_msg01="バックアップ保存先が指定されていません。"
err_msg02="バックアップ保存先が存在しません。作成します。"
err_msg03="バックアップ保存先に書き込み権限がありません。"
err_msg04="ターゲットリストが存在しません。"
err_msg05="除外リストが存在しません。"
err_msg06="tar アーカイブ作成に失敗しました。"
err_msg07="古いバックアップの削除に失敗しました。"
err_msg08="異常終了のため、バックアップを削除します。"

# ========================================
# 関数定義
# ========================================
scope="func"

# ------------------------------------------------------------------
# 関数名　　：usage
# 概要　　　：使用方法を標準エラーに出力する
# 説明　　　：
#   スクリプトの使用方法を標準エラー出力へ出力します。
#   引数不足・不正引数・ヘルプ指定時に呼び出されます。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：pre-process
# ------------------------------------------------------------------
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

# ------------------------------------------------------------------
# 関数名　　：checkArg
# 概要　　　：引数および実行前提条件を確認する
# 説明　　　：
#   バックアップ保存先ディレクトリの指定有無、存在確認、書き込み権限を確認します。
#   あわせて、ターゲットリスト、除外リスト、およびターゲットリスト内の対象実体を確認します。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：pre-process
# ------------------------------------------------------------------
checkArg() {
    if [ -z "$backup_dir" ]; then
        logOut "ERROR" "${err_msg01}"
        usage
        exitLog ${JOB_ER}
    fi
    if [ ! -d "$backup_dir" ]; then
        logOut "WARN" "${err_msg02} (${backup_dir})"
        mkdir -p "$backup_dir"
    fi
    if [ ! -w "$backup_dir" ]; then
        logOut "ERROR" "${err_msg03} (${backup_dir})"
        exitLog ${JOB_ER}
    fi
    if [ ! -f "$target_list" ]; then
        logOut "ERROR" "${err_msg04} (${target_list})"
        exitLog ${JOB_ER}
    fi
    if [ ! -f "$ignore_list" ]; then
        logOut "WARN" "${err_msg05} (${ignore_list})"
    fi

    # 【追加】ターゲットリスト内のファイルが存在するか確認
    while read line; do
        if [ ! -e "$line" ]; then
            logOut "ERROR" "${err_msg04}: ${line}"
            exitLog ${JOB_ER}
        fi
    done < "$target_list"
}

# ------------------------------------------------------------------
# 関数名　　：terminate
# 概要　　　：異常終了時の後始末を行う
# 説明　　　：
#   異常終了時にエラーログを出力し、作成途中のバックアップファイルが存在する場合は削除します。
#   後始末完了後は、異常終了コードで終了処理を行います。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：HUP INT QUIT TERM シグナル受信時の `trap`
# ------------------------------------------------------------------
terminate() {
    logOut "ERROR" "${err_msg08}"
    if [ -n "${backup_file}" ] && [ -f "${backup_file}" ]; then
        rm -f "${backup_file}"
        logOut "WARN" "${warn_msg01}: ${backup_file}"
    fi
    exitLog ${JOB_ER}
}

# ------------------------------------------------------------------
# 関数名　　：executeBackup
# 概要　　　：バックアップファイルを作成する
# 説明　　　：
#   現在日時をもとにバックアップファイル名を生成し、ターゲットリストをもとに
#   tar アーカイブを作成します。アーカイブ作成に失敗した場合は terminate を呼び出します。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：main-routine
# ------------------------------------------------------------------
executeBackup() {
    date_stamp="$(getCurrentDate)"
    logOut "DEBUG" "date_stamp=${date_stamp}"
    backup_file="${backup_dir}/backup_${date_stamp}.tar.gz"

    logOut "INFO" "バックアップ開始: ${backup_file}"

    # tar でアーカイブを作成
    logOut "DEBUG" "tarアーカイブ対象のリスト:"
    cat "${target_list}" | while read line; do
        logOut "DEBUG" "  - ${line}"
    done
    /bin/tar --exclude-from="${ignore_list}" -czf "${backup_file}" -T "${target_list}"

     rc=$?
    if [ $rc -ne $JOB_OK ]; then
        logOut "ERROR" "${err_msg06}"
        terminate
    fi

    logOut "INFO" "バックアップ完了: ${backup_file}"
}

# ------------------------------------------------------------------
# 関数名　　：cleanOldBackups
# 概要　　　：古いバックアップファイルを削除する
# 説明　　　：
#   バックアップ保存先ディレクトリ配下から、作成後 7 日を超えた
#   バックアップファイルを検索し、削除します。削除失敗時は警告ログを出力します。
#
# 引数　　　：なし
# 戻り値　　：なし
# 使用箇所　：main-routine
# ------------------------------------------------------------------
cleanOldBackups() {
    find "${backup_dir}" -type f -name "backup_*.tar.gz" -mtime +7 -exec rm {} + || logOut "WARN" "${err_msg07}"
}

# ----------------------------------------------------------
# pre-process
# ----------------------------------------------------------
scope="pre"

# `trap` 設定（異常終了時に terminate() を呼び出し）
trap "terminate" HUP INT QUIT TERM

# ========================================
# 引数の処理
# ========================================
while getopts "b:" opt; do
    case $opt in
        b) backup_dir="$OPTARG" ;;
        *) usage
        exitLog ${JOB_ER} ;;
    esac
done

checkArg
startLog "backupFiles.sh バックアップ処理開始"

# ----------------------------------------------------------
# main-routine
# ----------------------------------------------------------
scope="main"
executeBackup
cleanOldBackups

# ----------------------------------------------------------
# post-process
# ----------------------------------------------------------
scope="post"
exitLog ${JOB_OK}