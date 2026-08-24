#!/bin/sh
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
#
# template.sh ver.1.0.0 2021.07.18
#
# Usage:
#     sh 00_console.sh
#
# Description:
#     IAS 状態確認コマンド
#     検証環境用
#
# 設計書
#     設計書のタイトル記載
#
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
# ＜変更履歴＞
# Ver. 変更管理No. 日付        更新者       変更内容
# 1.0  〇〇〇〇〇  2021/07/19  〇〇〇〇       新規作成
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
# ------------------------------------------------------------------
# 初期処理
# ------------------------------------------------------------------
. "$(dirname "$0")/../com/utils.shrc"
. "$(dirname "$0")/../com/logger.shrc"

# 旧バージョンの共通ライブラリ互換ラッパー(現行logger.shrcの logOut/DEFAULT_LOG_MODE に合わせる)
logError() { logOut "ERROR" "$*"; }
logDebug() { logOut "DEBUG" "$*"; }
setLogMode() {
  case "$1" in
    standard|"") DEFAULT_LOG_MODE="CONSOLE" ;;
    *) DEFAULT_LOG_MODE="$1" ;;
  esac
}

# 旧バージョン互換: メニュー表示・確認プロンプト用ヘルパー(現行utils.shrcには無いため直接定義)
line() { echo -e "${1}"; }
lineS() { echo -e "-------------------------------------------------"; }
echoNl() {
  local indent="$1"; shift
  printf "%*s%s\n" "$indent" "" "$*"
}
question() {
  local msg="$1" default="$2" type="$3"
  case "$type" in
    yesNo)
      if confirmAction "${msg} [y/N]"; then
        ans="yes"
      else
        ans="no"
      fi
      ;;
    *)
      read -r -p "${msg} (${default}): " ans
      [ -z "$ans" ] && ans="$default"
      ;;
  esac
}
initPlatform() { :; }
doMenu() {
  echo
  local i=1
  declare -A menuMap
  while IFS='|' read -r label func; do
    [ -z "$label" ] && continue
    [ -z "$func" ] && continue
    echo "  ${i}) ${label}"
    menuMap[$i]="$func"
    i=$((i+1))
  done < "$menudata"
  echo "  0) 終了"
  read -r -p "番号を選択してください: " sel
  if [ "$sel" = "0" ]; then exit 0; fi
  local target="${menuMap[$sel]}"
  if [ -n "$target" ]; then
    cmd="$target"
    "$target"
  else
    echoNl 2 "無効な番号です。"
  fi
}
setLANG     utf-8
runAs root "$@"

SCRIPT_HOME="${BASE_PATH}/bin"
CHK_MSG_SVC="サービス名を入力してください。（例: httpd, tomcat, sshd）"
CHK_MSG_CTX="Tomcatのコンテキストパスを入力してください。（例: /myapp）"
CHK_MSG_DIR="バックアップ対象ディレクトリを入力してください。"
CHK_MSG_YN="よろしいですか？"

# ----------------------------------------------------------------
# Checking the Configuration file.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
checkConf() {
  if [ ! -f $1 ]; then
    logError Configuration file can not be found [ $1 ].
    exit 2
  fi
}

# --------------------------------------------------
# 中項目仕切り.
# --------------------------------------------------
# return N/A
# --------------------------------------------------
line2 (){
  echo -e "▼ ${1}"
  echo -e "-------------------------------------------------\\n"
}

# --------------------------------------------------
# FINAL LINE.
# --------------------------------------------------
# return N/A
# --------------------------------------------------
lineF (){
  echo -e "\\n-------------------------------------------------"
}

# ----------------------------------------------------------
# クラスタ情報取得
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
getCluster() {
  case "${hostname}" in
    env01)
    line "# 環境1サーバ#1"
    CLUSTERS=("CLU01A" "CLU01B" "CLU01C" "CLU01D" "CLU01E" "CLU01F")
      ;;
    env02)
    line "環境2サーバ#1"
    CLUSTERS=("CLU02A" "CLU02B")
      ;;
    env03)
    line "環境3サーバ#1"
    CLUSTERS=("CLU03A" "CLU03B")
      ;;
    env04)
    line "環境4サーバ#1"
    CLUSTERS=("CLU04A" "CLU04B" "CLU04C" "CLU04D")
      ;;
    env05)
    line "環境5サーバ#1"
    CLUSTERS=("CLU05A" "CLU05B" "CLU05C" "CLU05D")
      ;;
    env06)
    line "環境6サーバ#1"
    CLUSTERS=("CLU06A")
      ;;
    dev01)
    line "開発サーバ#1"
    CLUSTERS=("CLU01A" "CLU01B")
      ;;
  esac
}

# ----------------------------------------------------------------
# Get the caption for a menu action.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
getCaption() {
  case $1 in
    check_service_status    ) echo "サービスの状態を確認"           ;;
    start_service            ) echo "サービスを起動"                 ;;
    stop_service             ) echo "サービスを停止"                 ;;
    list_tomcat_apps         ) echo "Tomcatアプリの一覧を表示"       ;;
    check_tomcat_app_status  ) echo "Tomcatアプリの状態を確認"       ;;
    check_server_resource    ) echo "サーバーリソースを確認"         ;;
    backup_files             ) echo "指定ディレクトリをバックアップ" ;;
    *) echo "$1" ;;
  esac
}

# ----------------------------------------------------------------
# サービスの状態を確認する (manage_service.sh -c status)
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
check_service_status() {
  logDebug "Method $cmd() Started!"
  question "`getCaption $cmd`します。${CHK_MSG_SVC}" "" "alpha"
  if [ -n "${ans}" ]; then
    logDebug "${SCRIPT_HOME}/manage_service.sh -s ${ans} -c status"
    ${SCRIPT_HOME}/manage_service.sh -s "${ans}" -c status
  else
    echoNl 2 "サービス名が入力されませんでした。`getCaption ${cmd}`を中止します。"
  fi
  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# サービスを起動する (manage_service.sh -c start)
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
start_service() {
  logDebug "Method $cmd() Started!"
  question "`getCaption $cmd`します。${CHK_MSG_SVC}" "" "alpha"
  local svc="${ans}"
  if [ -n "${svc}" ]; then
    question "[ ${svc} ] `getCaption $cmd`します。${CHK_MSG_YN}" "yes" "yesNo"
    if [ "${ans}" == "yes" ]; then
      logDebug "${SCRIPT_HOME}/manage_service.sh -s ${svc} -c start"
      ${SCRIPT_HOME}/manage_service.sh -s "${svc}" -c start
    else
      echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
    fi
  else
    echoNl 2 "サービス名が入力されませんでした。`getCaption ${cmd}`を中止します。"
  fi
  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# サービスを停止する (manage_service.sh -c stop)
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
stop_service() {
  logDebug "Method $cmd() Started!"
  question "`getCaption $cmd`します。${CHK_MSG_SVC}" "" "alpha"
  local svc="${ans}"
  if [ -n "${svc}" ]; then
    question "[ ${svc} ] `getCaption $cmd`します。${CHK_MSG_YN}" "yes" "yesNo"
    if [ "${ans}" == "yes" ]; then
      logDebug "${SCRIPT_HOME}/manage_service.sh -s ${svc} -c stop"
      ${SCRIPT_HOME}/manage_service.sh -s "${svc}" -c stop
    else
      echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
    fi
  else
    echoNl 2 "サービス名が入力されませんでした。`getCaption ${cmd}`を中止します。"
  fi
  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# Tomcatアプリの一覧を表示する (monitor_tomcat_app.sh -c list)
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
list_tomcat_apps() {
  logDebug "Method $cmd() Started!"
  logDebug "${SCRIPT_HOME}/monitor_tomcat_app.sh -c list"
  ${SCRIPT_HOME}/monitor_tomcat_app.sh -c list
  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# Tomcatアプリの状態を確認する (monitor_tomcat_app.sh -c status)
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
check_tomcat_app_status() {
  logDebug "Method $cmd() Started!"
  question "`getCaption $cmd`します。${CHK_MSG_CTX}" "" "alpha"
  if [ -n "${ans}" ]; then
    logDebug "${SCRIPT_HOME}/monitor_tomcat_app.sh -c status -a ${ans}"
    ${SCRIPT_HOME}/monitor_tomcat_app.sh -c status -a "${ans}"
  else
    echoNl 2 "コンテキストパスが入力されませんでした。`getCaption ${cmd}`を中止します。"
  fi
  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# サーバーリソースを確認する (serverResourceCheck.sh)
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
check_server_resource() {
  logDebug "Method $cmd() Started!"
  logDebug "${SCRIPT_HOME}/serverResourceCheck.sh"
  ${SCRIPT_HOME}/serverResourceCheck.sh
  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# 指定ディレクトリをバックアップする (backupFiles.sh -b)
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
backup_files() {
  logDebug "Method $cmd() Started!"
  question "`getCaption $cmd`します。${CHK_MSG_DIR}" "" "alpha"
  local dir="${ans}"
  if [ -n "${dir}" ]; then
    question "[ ${dir} ] `getCaption $cmd`します。${CHK_MSG_YN}" "yes" "yesNo"
    if [ "${ans}" == "yes" ]; then
      logDebug "${SCRIPT_HOME}/backupFiles.sh -b ${dir}"
      ${SCRIPT_HOME}/backupFiles.sh -b "${dir}"
    else
      echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
    fi
  else
    echoNl 2 "ディレクトリが入力されませんでした。`getCaption ${cmd}`を中止します。"
  fi
  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# pre-process
# ----------------------------------------------------------------
step="pre"
hostname=`hostname -s`
menudir=$BASE_PATH/bin
menufile=$ETC_PATH/`hostname -s`/00_console_`hostname -s`.conf

setLogMode ${LOG_MODE:-standard}

logDebug args: ["$@"]

# Check Conf.
checkConf $menufile

PATH=$PATH:$menudir
export PATH

menudata=$TMP_PATH/menu.dat
sed -n '1,/__FUNCTIONS__/p' $menufile > $menudata
menushrc=$TMP_PATH/menu.shrc
sed -n '/__FUNCTIONS__/,$p' $menufile > $menushrc
. $menushrc

initPlatform

getCluster
# ----------------------------------------------------------------
# main-routine
# ----------------------------------------------------------------
step="main"
while true; do
  cd $menudir
  echo -e "\\n                              created by bepro"
  lineS "S"
  echo -e "実行環境：`hostname -s` IP：`hostname -I | cut -f1 -d' '`"
  lineS "S"
  echoNl 1 "  □機能を番号で選択してください "
  doMenu $*
done
# ----------------------------------------------------------------
# post-process
# ----------------------------------------------------------------
step="post"

exit 0


