#!/bin/sh
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
#
# template.sh ver.1.0.0 2021.07.18
#
# Usage:
#     sh 00_console.sh
#
# Description:
#     IAS 状態確認コマンド 新人用
#     検証2 totoapp11usr用
#
# 設計書
#     設計書のタイトル記載
#
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
# ＜変更履歴＞
# Ver. 変更管理No. 日付        更新者       変更内容
# 1.0  〇〇〇〇〇  2021/07/19  奈良@IAC     新規作成
#_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/_/
# ------------------------------------------------------------------
# 初期処理
# ------------------------------------------------------------------
. "$(dirname "$0")/../com/utils.shrc"
. "$(dirname "$0")/../com/logger.shrc"
setLANG     utf-8
runAs root "$@"

SCRIPT_HOME="${BASE_PATH}/bin"
DOMAIN_HOME="/var/opt/FJSVisje6/nodes/localhost-domain1"
ASADMIN_CMD="/opt/FJSVisje6/glassfish/bin/asadmin"
WEB_HOME="/var/jsc"
CHK_MSG_1="環境番号を入力してください。01-15（必須）"
CHK_MSG_2="クラスタIDを入力してください。"
CHK_MSG_3="よろしいですか？"
CHK_MSG_4="表示する件数を指定してください。（必須）"
CHK_MSG_5="対象のデータソース番号を選択してください。（必須）"
CHK_MSG_6="設定するリソース番号を選択してください。（必須）"
CHK_MSG_7="設定する値を入力してください。（必須）"
CHK_MSG_8="対象のターゲット番号を選択してください。（必須）"

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
    k2vsgam001)
    line "# 提携サイト向けGWサーバ#1"
    CLUSTERS=("CLUSSJY" "CLUSSKD" "CLUSSSM" "CLUSSSB" "CLUSSJB" "CLUSSRS")
      ;;
    k2vsgcm001)
    line "コンビニ向けGWサーバ#1"
    CLUSTERS=("CLUSSFM" "CLUSSSE")
      ;;
    k2vbjgm001)
    line "業務支援WebAP･くじ情報連携サーバ#1"
    CLUSTERS=("CLUBSAP" "CLULTJL")
      ;;
    k2vowam001)
    line "販売系AP･パートナー向けWebAPサーバ#1"
    CLUSTERS=("CLUOSAP" "CLUPIAP" "CLULTOL" "CLUPAAP")
      ;;
    k2voswm001)
    line "販売系Web･メディア向け情報提供サーバ#1"
    CLUSTERS=("CLUOSPC" "CLUOSSP" "CLUOSVT" "CLUOSIF")
      ;;
    k2vstnm001)
    line "発番サーバ#1"
    CLUSTERS=("CLUTNAP")
      ;;
    vm-ir8x-p420171)
    line "開発サーバ#1"
    CLUSTERS=("CLUSSFM" "CLUSSSE")
      ;;
  esac
}

# ----------------------------------------------------------------
# Selection of POSTGRES.
# ---------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
getCaption() {
  case $1 in
    status_httpd           ) echo "HTTPDの状態を確認" 	     ;;
    start_httpd	           ) echo "HTTPDを起動"              ;;
    stop_httpd	           ) echo "HTTPDを停止"              ;;
    port_no_httpd          ) echo "HTTPDのポート番号を確認"  ;;
    collect_httpd          ) echo "HTTPDの資材を回収"        ;;
    check_httpd_accesslog  ) echo "アクセスログを確認"       ;;
    check_httpd_errorlog   ) echo "エラーログを確認"         ;;
    status_instance        ) echo "インスタンスの状態を確認" ;;
    start_instance         ) echo "インスタンスを起動"       ;;
    stop_instance          ) echo "インスタンスを停止"       ;;
    check_ias_accesslog    ) echo "アクセスログを確認"       ;;
    check_ias_errorlog     ) echo "エラーログを確認"         ;;
    port_no_insance        ) echo "インスタンスポート番号を確認";;
    collect_instance       ) echo "インスタンスの資材を回収" ;;
    list_datasource        ) echo "データソースの一覧を表示" ;;
    delete_datasource      ) echo "データソースを削除"       ;;
    create_datasource      ) echo "データソースを作成"       ;;
    list_resource          ) echo "リソースの一覧を表示"     ;;
    set_resource           ) echo "リソースを設定"           ;;
    list_jvm_resource      ) echo "JVMリソースの一覧を表示"  ;;
    delete_jvm_resource    ) echo "JVMリソースを削除"        ;;
    set_jvm_resource       ) echo "JVMリソースを更新"        ;;
    list_jndi              ) echo "データソース-JNDI間の紐付き情報を表示"  ;;
    create_jndi            ) echo "JNDIを作成"               ;;
  esac
}

# ----------------------------------------------------------------
# Check the state of Catalina.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
port_no_httpd() {
  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "空はALL" "alpha"
    if [ ${ans} == "空はALL" ]; then
      question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
      if [ $ans == "yes" ]; then
        logDebug "${SCRIPT_HOME}/10_fjApacheCtl.sh -c port -p httpd -a ${envNum}"
        ${SCRIPT_HOME}/10_fjApacheCtl.sh -c port -p httpd -a ${envNum}
      else
        echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
      fi
    else
      logDebug "ans:${ans}"
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
      cluster=${ans}
        question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
        if [ $ans == "yes" ]; then
          logDebug "${SCRIPT_HOME}/10_fjApacheCtl.sh -c port -p httpd -a ${envNum} -i ${cluster}"
          ${SCRIPT_HOME}/10_fjAJapacheCtl.sh -c port -p httpd -a ${envNum} -i ${cluster}
        else
          echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
        fi
      else
        echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n`getCaption ${cmd}`を中止します。"
      fi
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# Check the state of Catalina.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
status_httpd() {
  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"  
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "空はALL" "alpha"
    if [ ${ans} == "空はALL" ]; then
      question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
      if [ $ans == "yes" ]; then
        logDebug "${SCRIPT_HOME}/10_fjApacheCtl.sh -c status -p httpd -a ${envNum}"
        ${SCRIPT_HOME}/10_fjApacheCtl.sh -c status -p httpd -a ${envNum}
      else
        echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
      fi
    else
      logDebug "ans:${ans}"
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
      cluster=${ans}
        question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
        if [ $ans == "yes" ]; then
          logDebug "${SCRIPT_HOME}/10_fjApacheCtl.sh -c status -p httpd -a ${envNum} -i ${cluster}"
          ${SCRIPT_HOME}/10_fjApacheCtl.sh -c status -p httpd -a ${envNum} -i ${cluster}
        else
          echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
        fi
      else
        echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n`getCaption ${cmd}`を中止します。"
      fi
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# START HTTPD.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
start_httpd() {
  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"  
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "空はALL" "alpha"
    if [ ${ans} == "空はALL" ]; then
      question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
      if [ $ans == "yes" ]; then
        logDebug "${SCRIPT_HOME}/10_fjApacheCtl.sh -c start -p httpd -a ${envNum}"
        ${SCRIPT_HOME}/10_fjApacheCtl.sh -c start -p httpd -a ${envNum}
      else
        echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
      fi
    else
      logDebug "ans:${ans}"
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
      cluster=${ans}
        question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
        if [ $ans == "yes" ]; then
          logDebug "${SCRIPT_HOME}/10_fjApacheCtl.sh -c start -p httpd -a ${envNum} -i ${cluster}"
          ${SCRIPT_HOME}/10_fjApacheCtl.sh -c start -p httpd -a ${envNum} -i ${cluster}
        else
          echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
        fi
      else
        echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n`getCaption ${cmd}`を中止します。"
      fi
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# STOP HTTPD.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
stop_httpd() {
  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"  
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "空はALL" "alpha"
    if [ ${ans} == "空はALL" ]; then
      question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
      if [ $ans == "yes" ]; then
        logDebug "${SCRIPT_HOME}/10_fjApacheCtl.sh -c stop -p httpd -a ${envNum}"
        ${SCRIPT_HOME}/10_fjApacheCtl.sh -c stop -p httpd -a ${envNum}
      else
        echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
      fi
    else
      logDebug "ans:${ans}"
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
      cluster=${ans}
        question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
        if [ $ans == "yes" ]; then
          logDebug "${SCRIPT_HOME}/10_fjApacheCtl.sh -c stop -p httpd -a ${envNum} -i ${cluster}"
          ${SCRIPT_HOME}/10_fjApacheCtl.sh -c stop -p httpd -a ${envNum} -i ${cluster}
        else
          echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
        fi
      else
        echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n`getCaption ${cmd}`を中止します。"
      fi
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# START INSTANCE.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
start_instance() {
  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"  
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "空はALL" "alpha"
    if [ ${ans} == "空はALL" ]; then
      question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
      if [ $ans == "yes" ]; then
        logDebug "${SCRIPT_HOME}/11_glassFishCtl.sh -c start -a ${envNum}"
        ${SCRIPT_HOME}/11_glassFishCtl.sh -c start -a ${envNum}
      else
        echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
      fi
    else
      logDebug "ans:${ans}"
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
      cluster=${ans}
        question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
        if [ $ans == "yes" ]; then
          logDebug "${SCRIPT_HOME}/11_glassFishCtl.sh -c start -a ${envNum} -i ${cluster}"
          ${SCRIPT_HOME}/11_glassFishCtl.sh -c start -a ${envNum} -i ${cluster}
        else
          echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
        fi
      else
        echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n`getCaption ${cmd}`を中止します。"
      fi
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# STOP INSTANCE.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
stop_instance() {
  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"  
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "空はALL" "alpha"
    if [ ${ans} == "空はALL" ]; then
      question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
      if [ $ans == "yes" ]; then
        logDebug "${SCRIPT_HOME}/11_glassFishCtl.sh -c stop -a ${envNum}"
        ${SCRIPT_HOME}/11_glassFishCtl.sh -c stop -a ${envNum}
      else
        echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
      fi
    else
      logDebug "ans:${ans}"
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
      cluster=${ans}
        question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
        if [ $ans == "yes" ]; then
          logDebug "${SCRIPT_HOME}/11_glassFishCtl.sh -c stop -a ${envNum} -i ${cluster}"
          ${SCRIPT_HOME}/11_glassFishCtl.sh -c stop -a ${envNum} -i ${cluster}
        else
          echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
        fi
      else
        echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n`getCaption ${cmd}`を中止します。"
      fi
    fi
  else
    echoNl 2 "01-15以外が入力されました。状態確認を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# STATUS INSTANCE.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
status_instance() {
  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}）" "11" "alpha"  
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "空はALL" "alpha"
    if [ ${ans} == "空はALL" ]; then
      question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
      if [ $ans == "yes" ]; then
        logDebug "${SCRIPT_HOME}/11_glassFishCtl.sh -c status -a ${envNum}"
        ${SCRIPT_HOME}/11_glassFishCtl.sh -c status -a ${envNum}
      else
        echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
      fi
    else
      logDebug "ans:${ans}"
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
      cluster=${ans}
        question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
        if [ $ans == "yes" ]; then
          logDebug "${SCRIPT_HOME}/11_glassFishCtl.sh -c status -a ${envNum} -i ${cluster}"
          ${SCRIPT_HOME}/11_glassFishCtl.sh -c status -a ${envNum} -i ${cluster}
        else
          echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
        fi
      else
        echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n`getCaption ${cmd}`を中止します。"
      fi
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# PORT_NO INSTANCE.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
port_no_instance() {
  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "空はALL" "alpha"
    if [ ${ans} == "空はALL" ]; then
      question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
      if [ $ans == "yes" ]; then
        logDebug "${SCRIPT_HOME}/11_glassFishCtl.sh -c port -a ${envNum}"
        ${SCRIPT_HOME}/11_glassFishCtl.sh -c port -a ${envNum}
      else
        echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
      fi
    else
      logDebug "ans:${ans}"
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
      cluster=${ans}
        question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
        if [ $ans == "yes" ]; then
          logDebug "${SCRIPT_HOME}/11_glassFishCtl.sh -c port -a ${envNum} -i ${cluster}"
          ${SCRIPT_HOME}/11_glassFishCtl.sh -c port -a ${envNum} -i ${cluster}
        else
          echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
        fi
      else
        echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n`getCaption ${cmd}`を中止します。"
      fi
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# COLLECT HTTPD.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
collect_httpd() {
  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "空はALL" "alpha"
    if [ ${ans} == "空はALL" ]; then
      question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
      if [ $ans == "yes" ]; then
        logDebug "${SCRIPT_HOME}/12_collectConfig.sh -c collect -p httpd -a ${envNum}"
        ${SCRIPT_HOME}/12_collectConfig.sh -c collect -p httpd -a ${envNum}
      else
        echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
      fi
    else
      logDebug "ans:${ans}"
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
      cluster=${ans}
        question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
        if [ $ans == "yes" ]; then
          logDebug "${SCRIPT_HOME}/12_collectConfig.sh -c collect -p httpd -a ${envNum} -i ${cluster}"
          ${SCRIPT_HOME}/12_collectConfig.sh -c collect -p httpd -a ${envNum} -i ${cluster}
        else
          echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
        fi
      else
        echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n`getCaption ${cmd}`を中止します。"
      fi
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# COLLECT INSTANCE.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
collect_instance() {
  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"  
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "空はALL" "alpha"
    if [ ${ans} == "空はALL" ]; then
      question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
      if [ $ans == "yes" ]; then
        logDebug "${SCRIPT_HOME}/12_collectConfig.sh -c collect -p glassfish -a ${envNum}"
        ${SCRIPT_HOME}/12_collectConfig.sh -c collect -p glassfish -a ${envNum}
      else
        echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
      fi
    else
      logDebug "ans:${ans}"
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
      cluster=${ans}
        question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
        if [ $ans == "yes" ]; then
          logDebug "${SCRIPT_HOME}/12_collectConfig.sh -c collect -p glassfish -a ${envNum} -i ${cluster}"
          ${SCRIPT_HOME}/12_collectConfig.sh -c collect -p glassfish -a ${envNum} -i ${cluster}
        else
          echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
        fi
      else
        echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n`getCaption ${cmd}`を中止します。"
      fi
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}
# ----------------------------------------------------------------
# CHECK HTTPD ACCESSLOG.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
check_httpd_accesslog() {
  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"  
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "${CLUSTERS[0]}" "alpha"
    if [ -n ${ans} ]; then
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
        cluster=${ans}
        question "`getCaption $cmd`します。${CHK_MSG_4}" "30" "alpha"
        if isNumeric ${ans}; then
          count=${ans}
          question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
          if [ ${ans} == "yes" ]; then
            logDebug "tail -n ${count} ${WEB_HOME}/app${envNum}/web/WEB${cluster:3:4}${envNum}/logs/accesslog"
            tail -n ${count} ${WEB_HOME}/app${envNum}/web/WEB${cluster:3:4}${envNum}/logs/accesslog
          else
            echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
          fi
        else
          echoNl 2 "不正な値が入力されました。`getCaption ${cmd}`を中止します。"
        fi
      fi
    else
      echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n`getCaption ${cmd}`を中止します。"
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# CHECK HTTPD ERRORLOG.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
check_httpd_errorlog() {
  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"  
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "${CLUSTERS[0]}" "alpha"
    if [ -n ${ans} ]; then
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
        cluster=${ans}
        question "`getCaption $cmd`します。${CHK_MSG_4}" "30" "alpha"
        if isNumeric ${ans}; then
          count=${ans}
          question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"        
          if [ ${ans} == "yes" ]; then
            logDebug "tail -n ${count} ${WEB_HOME}//app${envNum}/web/WEB${cluster:3:4}${envNum}/logs/errorlog"
            tail -n ${count} ${WEB_HOME}//app${envNum}/web/WEB${cluster:3:4}${envNum}/logs/errorlog
          else
            echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
          fi
        else
          echoNl 2 "不正な値が入力されました。`getCaption ${cmd}`を中止します。"
        fi
      fi
    else
      echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n`getCaption ${cmd}`を中止します。"
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# CHECK IAS ACCESSLOG.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
check_ias_accesslog() {
  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "${CLUSTERS[0]}" "alpha"
    if [ -n ${ans} ]; then
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
        cluster=${ans}
        question "`getCaption $cmd`します。${CHK_MSG_4}" "30" "alpha"
        if isNumeric ${ans}; then
          count=${ans}
          question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
          if [ ${ans} == "yes" ]; then
            logDebug "tail -n ${count} ${DOMAIN_HOME}/INS${cluster:3:4}${envNum}/logs/access/server_access_log.txt"
            tail -n ${count} ${DOMAIN_HOME}/INS${cluster:3:4}${envNum}/logs/access/server_access_log.txt
          else
            echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
          fi
        else
          echoNl 2 "不正な値が入力されました。`getCaption ${cmd}`を中止します。"
        fi
      fi
    else
      echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n
`getCaption ${cmd}`を中止します。"
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# CHECK IAS SERVERLOG.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
check_ias_serverlog() {
  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "${CLUSTERS[0]}" "alpha"
    if [ -n ${ans} ]; then
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
        cluster=${ans}
        question "`getCaption $cmd`します。${CHK_MSG_4}" "30" "alpha"
        if isNumeric ${ans}; then
          count=${ans}
          question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
          if [ ${ans} == "yes" ]; then
            logDebug "tail -n ${count} ${DOMAIN_HOME}/INS${cluster:3:4}${envNum}/logs/server.log"
            tail -n ${count} ${DOMAIN_HOME}/INS${cluster:3:4}${envNum}/logs/server.log
          else
            echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
          fi
        else
          echoNl 2 "不正な値が入力されました。`getCaption ${cmd}`を中止します。"
        fi 
      fi
    else
      echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n
`getCaption ${cmd}`を中止します。"
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# LIST DATASOURCE.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
list_datasource() {
  logDebug "Method $cmd() Started!"

  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
    if [ ${ans} == "yes" ]; then
      logDebug "${SCRIPT_HOME}/13_datasurceSetting.sh -c list -a ${envNum}"
      ${SCRIPT_HOME}/13_datasurceSetting.sh -c list -a ${envNum}
    else
      echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# DELETE DATASOURCE.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
delete_datasource() {
  logDebug "Method $cmd() Started!"

  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    line2 "$cmd"
    arrayDs=()
    count=0
    arrayDs=(`${ASADMIN_CMD} -e list-jdbc-connection-pools | sed -e '1d' | sed -e '$d' | grep ${envNum}`)
    for ds in ${arrayDs[@]} ; do
      echo "${count} : ${ds}"
      count=$(( count + 1 ))
    done
    lineF
    question "`getCaption $cmd`します。削除${CHK_MSG_5}" "0" "alpha"
    if isNumeric ${ans}; then
      if [ ${ans} -lt ${#arrayDs[@]} ]; then
        target=${ans}
        question "[ ${arrayDs[${target}]} ]`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
        if [ ${ans} == "yes" ]; then
          logDebug "${SCRIPT_HOME}/13_datasurceSetting.sh -c delete -a ${envNum} -t ${arrayDs[${target}]}"
          ${SCRIPT_HOME}/13_datasurceSetting.sh -c delete -a ${envNum} -t ${arrayDs[${target}]}
        else
          echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
        fi
      else
        echoNl 2 "範囲外の数値が入力されました。`getCaption ${cmd}`を中止します。"        
      fi
    else
      echoNl 2 "数値以外が入力されました。`getCaption ${cmd}`を中止します。"
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# CREATE DATASOURCE.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
create_datasource () {
  logDebug "Method $cmd() Started!"
  
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    line2 "${cmd}target"
    arrayCaption=("cnt:（センターデータベース）" "ofs:（オフィシャルサイトデータベース）")
    arrayDsClass=("cnt" "ofs")
    count=0
    for ds in ${arrayCaption[@]} ; do
      echo "${count} : ${ds}"
      count=$(( count + 1 ))
    done
    lineF
    question "`getCaption $cmd`します。${CHK_MSG_8}" "0" "alpha"
    if isNumeric ${ans}; then
      if [ ${ans} -lt ${#arrayDsClass[@]} ]; then
        target=${ans}
        question "[ ${arrayCaption[${target}]} ]`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
        if [ ${ans} == "yes" ]; then
          logDebug "${SCRIPT_HOME}/13_datasurceSetting.sh -c create -a ${envNum} -t ${arrayDsClass[${target}]}"
          ${SCRIPT_HOME}/13_datasurceSetting.sh -c create -a ${envNum} -t ${arrayDsClass[${target}]}
        else
          echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
        fi
      else
        echoNl 2 "範囲外の数値が入力されました。`getCaption ${cmd}`を中止します。"
      fi
    else
      echoNl 2 "数値以外が入力されました。`getCaption ${cmd}`を中止します。"
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi  

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# LIST RESOURCE.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
list_resource() {
  logDebug "Method $cmd() Started!"

  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    line2 "$cmd"
    arrayDs=()
    count=0
    arrayDs=(`${ASADMIN_CMD} -e list-jdbc-connection-pools | sed -e '1d' | sed -e '$d' | grep ${envNum}`)
    for ds in ${arrayDs[@]} ; do
      echo "${count} : ${ds}"
      count=$(( count + 1 ))
    done
    lineF
    question "`getCaption $cmd`します。${CHK_MSG_5}" "0" "alpha"
    if isNumeric ${ans}; then
      if [ ${ans} -lt ${#arrayDs[@]} ]; then
        target=${ans}
        question "[ ${arrayDs[${target}]} ]`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
        if [ ${ans} == "yes" ]; then
          logDebug "${SCRIPT_HOME}/13_datasurceSetting.sh -c "list_resource" -a ${envNum} -t ${arrayDs[${target}]}"
          ${SCRIPT_HOME}/13_datasurceSetting.sh -c "list_resource" -a ${envNum} -t ${arrayDs[${target}]}
        else
          echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
        fi
      else
        echoNl 2 "範囲外の数値が入力されました。`getCaption ${cmd}`を中止します。"
      fi
    else
      echoNl 2 "数値以外が入力されました。`getCaption ${cmd}`を中止します。"
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# SET RESOURCE.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
set_resource() {
  logDebug "Method $cmd() Started!"

  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    line2 "$cmd"
    arrayDs=()
    count=0
    arrayDs=(`${ASADMIN_CMD} -e list-jdbc-connection-pools | sed -e '1d' | sed -e '$d' | grep ${envNum}`)
    for ds in ${arrayDs[@]} ; do
      echo "${count} : ${ds}"
      count=$(( count + 1 ))
    done
    lineF
    question "`getCaption $cmd`します。リソース設定${CHK_MSG_5}" "0" "alpha"
    if isNumeric ${ans}; then
      if [ ${ans} -lt ${#arrayDs[@]} ]; then
        target=${ans}
        line2 "choose"
        arrayOpt=()
        count=0
        arrayOpt=("max-pool-size" "steady-pool-size" "pool-resize-quantity" "idle-timeout-in-seconds" "max-wait-time-in-millis")
        for opt in ${arrayOpt[@]} ; do
          echo "${count} : ${opt}"
          count=$(( count + 1 ))
        done
        lineF
        question "`getCaption $cmd`します。${CHK_MSG_6}" "0" "alpha"
        if isNumeric ${ans}; then
          if [ ${ans} -lt ${#arrayOpt[@]} ]; then
            resource=${ans}
            question "`getCaption $cmd`します。${CHK_MSG_7}" "10" "alpha"
            if isNumeric ${ans}; then
              val=${ans}
              question "[ ${arrayOpt[${resource}]} ]`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
              if [ ${ans} == "yes" ]; then
                logDebug "${SCRIPT_HOME}/13_datasurceSetting.sh -c set_resource -a ${envNum} -t ${arrayDs[${target}]}.${arrayOpt[${resource}]}=${val}"
                ${SCRIPT_HOME}/13_datasurceSetting.sh -c set_resource -a ${envNum} -t ${arrayDs[${target}]}.${arrayOpt[${resource}]}=${val}
              else
                echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
              fi
            else
              echoNl 2 "数値以外が入力されました。`getCaption ${cmd}`を中止します。"
            fi
          else
            echoNl 2 "範囲外の数値が入力されました。`getCaption ${cmd}`を中止します。"
          fi
        else
          echoNl 2 "数値以外が入力されました。`getCaption ${cmd}`を中止します。"
        fi
      else
        echoNl 2 "範囲外の数値が入力されました。`getCaption ${cmd}`を中止します。"
      fi
    else
      echoNl 2 "数値以外が入力されました。`getCaption ${cmd}`を中止します。"
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# LIST JVM RESOURCE
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
list_jvm_resource() {
  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "空はALL" "alpha"
    if [ ${ans} == "空はALL" ]; then
      question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
      if [ $ans == "yes" ]; then
        logDebug "${SCRIPT_HOME}/14_jvmSetting.sh -c list -a ${envNum}"
        ${SCRIPT_HOME}/14_jvmSetting.sh -c list -a ${envNum}
      else
        echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
      fi
    else
      logDebug "ans:${ans}"
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
      cluster=${ans}
        question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
        if [ $ans == "yes" ]; then
          logDebug "${SCRIPT_HOME}/14_jvmSetting.sh -c list -a ${envNum} -i ${cluster}"
          ${SCRIPT_HOME}/14_jvmSetting.sh -c list -a ${envNum} -i ${cluster}
        else
          echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
        fi
      else
        echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n`getCaption ${cmd}`を中止します。"
      fi
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# DELETE JVM RESOURCE.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
delete_jvm_resource() {
  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "${CLUSTERS[0]}" "alpha"
    if [ -n ${ans} ]; then
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
        cluster=${ans}
        arrayRes=()
        line2 "$cmd"
        count=0
        arrayOpt=("\\-XX\\:MaxPermSize" "\\-XX\\:PermSize" "\\-Xmx" "\\-Xms" "\\-verbose" "\\-Dcntjndi" "\\-Dofsjndi")
        for opt in ${arrayOpt[@]} ; do
          val=(`${ASADMIN_CMD} -e list-jvm-options --target ${cluster}${envNum} | grep ${opt}`)
          if [ -n "${val}" ]; then
            echo "${count} : ${val}"
            arrayRes[${count}]=$(echo ${val} | sed -e 's/\-/\\-/' -e 's/\:/\\:/')
            count=$(( count + 1 ))
          fi
        done
        lineF
        question "`getCaption $cmd`します。削除${CHK_MSG_8}" "0" "alpha"
        if isNumeric ${ans}; then
          if [ ${ans} -lt ${#arrayOpt[@]} ]; then
            target=${ans}
            question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
            if [ ${ans} == "yes" ]; then
              logDebug "${SCRIPT_HOME}/14_jvmSetting.sh -c delete -a ${envNum} -i ${cluster} -t ${arrayRes[${target}]}"
              ${SCRIPT_HOME}/14_jvmSetting.sh -c delete -a ${envNum} -i ${cluster} -t "${arrayRes[${target}]}"
              line2 "$cmd"
              count=0
              arrayOpt=("\\-XX\\:MaxPermSize" "\\-XX\\:PermSize" "\\-Xmx" "\\-Xms" "\\-verbose" "\\-Dcntjndi")
              for opt in ${arrayOpt[@]} ; do
                val=(`${ASADMIN_CMD} -e list-jvm-options --target ${cluster}${envNum} | grep ${opt}`)
                if [ -n "${val}" ]; then
                  echo "${count} : ${val}"
                  arrayRes[${count}]=$(echo ${val} | sed -e 's/\-/\\-/' -e 's/\:/\\:/')
                  count=$(( count + 1 ))
                 fi
              done
              lineF 
            else
              echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
            fi
          else
            echoNl 2 "範囲外の数値が入力されました。`getCaption ${cmd}`を中止します。"
          fi
        else
          echoNl 2 "不正な値が入力されました。`getCaption ${cmd}`を中止します。"
        fi
      fi
    else
      echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n
`getCaption ${cmd}`を中止します。"
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# CREATE JVM RESOURCE.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
set_jvm_resource() {
  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "${CLUSTERS[0]}" "alpha"
    if [ -n ${ans} ]; then
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
        cluster=${ans}
        arrayOpt=()
        line2 "$cmd"
        count=0
        arrayPost=("\\-XX\\:MaxPermSize=@m" "\\-XX\\:PermSize=@m" "\\-Xmx@m" "\\-Xms@m" "\\-verbose\\:@" "\\-Dcntjndi=jdbc/@" "\\-Dofsjndi=jdbc/@")
        arrayOpt=("\\-XX\\:MaxPermSize" "\\-XX\\:PermSize" "\\-Xmx" "\\-Xms" "\\-verbose" "\\-Dcntjndi" "\\-Dofsjndi")
        
        for opt in ${arrayOpt[@]} ; do
            echo "${count} : ${opt}"
            count=$(( count + 1 ))
        done
        lineF
        question "`getCaption $cmd`します。作成${CHK_MSG_8}" "0" "alpha"
        if isNumeric ${ans}; then
          if [ ${ans} -lt ${#arrayOpt[@]} ]; then
            target=${ans}
            question "`getCaption $cmd`します。${CHK_MSG_7}" "10" "alpha"
            val=${ans}
            target=$(echo ${arrayPost[${target}]} | sed -e "s/\@/${val}/")
            question "`getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
            if [ ${ans} == "yes" ]; then
              logDebug "${SCRIPT_HOME}/14_jvmSetting.sh -c set -a ${envNum} -i ${cluster} -t ${target}"
              ${SCRIPT_HOME}/14_jvmSetting.sh -c set -a ${envNum} -i ${cluster} -t "${target}"
              line2 "$cmd"
              count=0
              arrayOpt=("\\-XX\\:MaxPermSize" "\\-XX\\:PermSize" "\\-Xmx" "\\-Xms" "\\-verbose" "\\-Dcntjndi")
              for opt in ${arrayOpt[@]} ; do
                val=(`${ASADMIN_CMD} -e list-jvm-options --target ${cluster}${envNum} | grep ${opt}`)
                if [ -n "${val}" ]; then
                  echo "${count} : ${val}"
                  arrayRes[${count}]=$(echo ${val} | sed -e 's/\-/\\-/' -e 's/\:/\\:/')
                  count=$(( count + 1 ))
                 fi
              done
              lineF
            else
              echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
            fi
          else
            echoNl 2 "範囲外の数値が入力されました。`getCaption ${cmd}`を中止します。"
          fi
        else
          echoNl 2 "不正な値が入力されました。`getCaption ${cmd}`を中止します。"
        fi
      fi
    else
      echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n
`getCaption ${cmd}`を中止します。"
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"
}

# ----------------------------------------------------------------
# LIST JNDI.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
list_jndi() {

  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "${CLUSTERS[0]}" "alpha"
    if [ -n ${ans} ]; then
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
        cluster=${ans}
        arrayRes=()
        line2 "$cmd"
        count=0
        arrayDs=(`${ASADMIN_CMD} -e list-jdbc-connection-pools | sed -e '1d' | sed -e '$d' | grep ${envNum}`)
        for ds in ${arrayDs[@]} ; do
          echo "${count} : ${ds}"
          count=$(( count + 1 ))
        done
        question "`getCaption $cmd`します。${CHK_MSG_5}" "0" "alpha"
        if isNumeric ${ans}; then
          if [ ${ans} -lt ${#arrayDs[@]} ]; then
            target=${ans}
            val=jdbc/${cluster:3:4}${arrayDs[${target}]:10:3}${envNum}
            question "[ ${val} ] `getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
            if [ ${ans} == "yes" ]; then
              logDebug "${SCRIPT_HOME}/14_jvmSetting.sh -c list_jndi -a ${envNum} -i ${cluster} -t ${arrayDs[${target}]} ${val}"
              ${SCRIPT_HOME}/14_jvmSetting.sh -c list_jndi -a ${envNum} -i ${cluster} -t "${arrayDs[${target}]} ${val}"
           else
              echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
            fi
          else
            echoNl 2 "範囲外の数値が入力されました。`getCaption ${cmd}`を中止します。"
          fi
        else
          echoNl 2 "数値以外が入力されました。`getCaption ${cmd}`を中止します。"
        fi
      fi
    else
      echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n
`getCaption ${cmd}`を中止します。"
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
  fi

  logDebug "Method $cmd() Ended!"

}
# ----------------------------------------------------------------
# CREATE JNDI.
# ----------------------------------------------------------------
# return   N/A
# ----------------------------------------------------------------
create_jndi() {

  logDebug "Method $cmd() Started!"

  cluster=""
  envNum=""
  question "`getCaption $cmd`します。${CHK_MSG_1}" "11" "alpha"
  if [[ "${ans}" == [0-9][0-5] ]]; then
    envNum=${ans}
    question "`getCaption $cmd`します。${CHK_MSG_2}" "${CLUSTERS[0]}" "alpha"
    if [ -n ${ans} ]; then
      if printf '%s\n' "${CLUSTERS[@]}" | grep -qx "${ans}" > /dev/null >&2; then
        cluster=${ans}
        arrayRes=()
        line2 "$cmd"
        count=0
        arrayDs=(`${ASADMIN_CMD} -e list-jdbc-connection-pools | sed -e '1d' | sed -e '$d' | grep ${envNum}`)
        for ds in ${arrayDs[@]} ; do
          echo "${count} : ${ds}"
          count=$(( count + 1 ))
        done
        question "`getCaption $cmd`します。接続${CHK_MSG_5}" "0" "alpha"
        if isNumeric ${ans}; then
          if [ ${ans} -lt ${#arrayDs[@]} ]; then
            target=${ans}
            val=jdbc/${cluster:3:4}${arrayDs[${target}]:10:3}${envNum}
            question "[ ${val} ] `getCaption $cmd`します。${CHK_MSG_3}" "yes" "yesNo"
            if [ ${ans} == "yes" ]; then
              logDebug "${SCRIPT_HOME}/14_jvmSetting.sh -c create_jndi -a ${envNum} -i ${cluster} -t ${arrayDs[${target}]} ${val}"
              ${SCRIPT_HOME}/14_jvmSetting.sh -c create_jndi -a ${envNum} -i ${cluster} -t "${arrayDs[${target}]} ${val}"
           else
              echoNl 2 "[ No ]が選択されました。`getCaption ${cmd}`を中止します。"
            fi
          else
            echoNl 2 "範囲外の数値が入力されました。`getCaption ${cmd}`を中止します。"
          fi
        else
          echoNl 2 "数値以外が入力されました。`getCaption ${cmd}`を中止します。"
        fi
      fi
    else
      echoNl 2 "認識されないクラスタIDが入力されました。\\nクラスタIDは[ ${CLUSTERS[@]} ]の中から入力してください。\\n
`getCaption ${cmd}`を中止します。"
    fi
  else
    echoNl 2 "01-15以外が入力されました。`getCaption ${cmd}`を中止します。"
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
  echo -e "\\n                              created by IAC"
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


