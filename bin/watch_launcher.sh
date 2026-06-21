#!/bin/sh
# ------------------------------------------------------------------
# 初期処理
# ------------------------------------------------------------------
. "$(dirname "$0")/../com/logger.shrc"
. "$(dirname "$0")/../com/utils.shrc"
setLANG     utf-8
runAs root "$@"

# ----------------------------------------------------------
# functions
# ----------------------------------------------------------
# program version.
VERSION=20250805_01

# ------------------------------------------------------------------
# 変数宣言
# ------------------------------------------------------------------
scope="var"

readonly JOB_OK=0
readonly JOB_WR=1
readonly JOB_ER=2
rc=${JOB_ER}

# ----------------------------------------------------------
# bail out after clean up lock and working directory.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
terminate() {
  logOut "DEBUG" "$0:terminate() STARTED !"
  switchLog
  status=0
  [ "$1" ] && status=$1
  logOut "INFO" "terminating with status [${status}]..."
  if [ -d ${lockD} ]; then
    rm -rf ${lockD}
  fi
  logOut "INFO" "done."
  logOut "DEBUG" "$0:terminate() ENDED !"
  exitLog ${status}
}

# ----------------------------------------------------------
# do the job only once.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
once() {
  logOut "DEBUG" "$0:once() STARTED !"
  logOut "INFO" ==== on demand process start
  limit=0  # break sleeping
  once=1
  logOut "DEBUG" "$0:once() ENDED !"
}

# ----------------------------------------------------------
# reload both config and command.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
reload() {
  logOut "DEBUG" "$0:reload() STARTED !"
  loadConfig
  loadCommand
  dumpSetting
  logOut "DEBUG" "$0:reload() ENDED !"
}

# ----------------------------------------------------------
# how to use.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
usage() {
  logOut "DEBUG" "$0:usage() STARTED !"
  cat <<EOUSAGE

  $0 configFile {operation-1}
  $0 {operation-2}

  configFile:
    the configuration file. please specify as full path.

  operation-1:
    status    show current status.
    start     start cyclic processing.
    stop      stop cyclic processing.
    reload    reload settings from "configFile" and "cmdfile".
    once      do the job only once.
    log [arg] tail the logfile. all [arg] will be passed to tail.
    dump      dump current settings.
    cleanup   clean up dead lock directory.

  operation-2:
    list      list all cyclic processes.
    template  show sample config.
    help      show this message.

EOUSAGE
  logOut "DEBUG" "$0:usage() ENDED !"
}

# ----------------------------------------------------------
# sample config.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
template() {
    cat <<'EOF'
#------------------------------------------------------------TEMPLATE_BEGIN
name=your_process_name
lockD="$TMP_PATH/${name}/lock"
pidfile=${lockD}/pid
cmdfile=${lockD}/cmd
inifile=${lockD}/ini
logfile=$LOG_PATH/${name}.`date "+%Y%m%d"`.log
interval=10
repeat=0
once=0
dumpvariables="name basedir lockD pidfile cmdfile logfile interval repeat once"

process() {
  value=`ps auxww | wc -l`
  if [ $value -gt 400 ]; then
    /usr/bin/logger "check processes... too many processes. : ${value}"
  fi
}
#------------------------------------------------------------TEMPLATE_END
EOF
    return 0
}

# ----------------------------------------------------------
# the job. please re-define this function in your config file.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
process() {
  :
}

# ----------------------------------------------------------
# directory preparation.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
prepareDirs() {
  logOut "DEBUG" "$0:prepareDirs() STARTED !"
        logOut "DEBUG" "${basedir} ${logdir}"
  for d in ${basedir} ${logdir}; do
    if [ ! -d ${d} ]; then
      logOut "DEBUG" "${d}"
      mkdir -p "${d}"
    fi
  done
  logOut "DEBUG" "$0:prepareDirs() ENDED !"
}

# ----------------------------------------------------------
# sleep intermittently.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
intermittentSleep() {
  logOut "DEBUG" "$0:intermittentSleep() STARTED !"
  logOut "INFO" sleeping [${interval}] sec...
  limit=${interval}
  a=0
  while ([ ${a} -lt ${limit} ])
  do
    let a=${a}+1 > /dev/null
    sleep 1
  done
  logOut "DEBUG" "$0:intermittentSleep() ENDED !"
}

# ----------------------------------------------------------
# switch current logfile depend upon machine date.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
switchLog() {
  logOut "DEBUG" "$0:switchLog() STARTED !"

  exec >> ${logfile} 2>&1

  if [ `ls ${logdir}/${name}.*.log | wc -l` -gt 8 ]; then
    ls -t ${logdir}/${name}.*.log | tail -1 | xargs rm
  fi
  logOut "DEBUG" "$0:switchLog() ENDED !"
}

# ----------------------------------------------------------
# dump current setting variables for convenience.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
dumpSetting() {
  logOut "DEBUG" "$0:dumpSetting() STARTED !"
  cat /dev/null > ${inifile}
  for key in ${dumpvariables}
  do
    eval value=\$${key}
    echo ${key}=${value} >> ${inifile}
  done
  logOut "DEBUG" "$0:dumpSetting() ENDED !"
}

# ----------------------------------------------------------
# search and decide the config file.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
searchConfig() {
  logOut "DEBUG" "$0:searchConfig() STARTED !"
  if [ -f ${config} ]; then
    return 0
  fi
  for path in $ETC_PATH/$hostname; do
    if [ -f $path/${config} ]; then
      config=${path}/${config}
      break
    fi
    if [ -f $path/${config}.shrc ]; then
      config=${path}/${config}.conf
      break
    fi
  done
  logOut "DEBUG" "$0:searchConfig() ENDED !"
}

# ----------------------------------------------------------
# load config.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
loadConfig() {
  logOut "DEBUG" "$0:loadConfig() STARTED !"
  if [ -f ${config} ]; then
    load ${config}
  fi
  logOut "DEBUG" "$0:loadConfig() ENDED !"
}

# ----------------------------------------------------------
# load command and remove it.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
loadCommand() {
  logOut "DEBUG" "$0:loadCommand() STARTED !"
  if [ -f ${cmdfile} ]; then
    load ${cmdfile}
    rm ${cmdfile}
    dumpSetting
  fi
  logOut "DEBUG" "$0:loadCommand() ENDED !"
}

# ----------------------------------------------------------
# load one file.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
load() {
  logOut "DEBUG" "$0:load() STARTED !"
  theFile=$1
  logOut "INFO" loading [${theFile}]...
  . ${theFile}
  if [[ ${terminate} -eq 1 ]]; then
    logOut "INFO" "terminate command accepted."
    terminate 0
  fi
  limit=0  # break intermittent sleep
  logOut "DEBUG" "$0:load() ENDED !"
}

# ----------------------------------------------------------
# perform specified process.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
callProcess() {
  logOut "DEBUG" "$0:callProcess() STARTED !"
  if [ ${repeat} -eq 1 -o ${once} -eq 1 ]; then
    process
    if [ ${once} -eq 1 ]; then
      once=0
    fi
  fi
  logOut "DEBUG" "$0:callProcess() ENDED !"
}

# ----------------------------------------------------------
# check status. (and clean up dead lock directory.).
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
checkStatus() {
  logOut "DEBUG" "$0:checkStatus() STARTED !"
  withClean=$1
  if [ -d ${lockD} ]; then
    if [ -f ${pidfile} ]; then
      pid=`cat ${pidfile}`
      logOut "INFO" ${name} maybe running. pid = ${pid}
      logOut "DEBUG" "ps -aef | grep ${config##*/} | grep ${pid} | grep -v grep | wc -l"
      count=`ps -aef | grep ${config##*/} | grep ${pid} | grep -v grep | wc -l`
      if [ $count -eq 0 ]; then
        logOut "INFO" but ${pid} is not ${name}.
        if [ "$withClean" = "clean" ]; then
          logOut "INFO" cleaning up lock directory ...
          cd / && rm -rf ${lockD}.dead && mv ${lockD} ${lockD}.dead
          logOut "INFO" done.
        fi
      fi
    fi
  else
    logOut "INFO" ${name} is not running.
  fi
  logOut "DEBUG" "$0:checkStatus() ENDED !"
}

# ----------------------------------------------------------
# Checking argument.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
checkArgs(){
  logOut "DEBUG" "$0:checkArgs() STARTED !"
  # operation-2 group does not require config filename.
  # so check them here.
  if [ ! "$1" -o "$1" = "help" -o "$1" = "usage" ]; then
    usage
    exitLog 0
  fi
  if [ "$1" = "template" ]; then
    cd $invoked > /dev/null
    $1
    exitLog 0
  fi
  if [ "$1" = "list" ]; then
    PROGRAM=${0##*/}
    ps auxww | grep $PROGRAM | grep -v grep | grep ' run'
    exitLog 0
  fi
  logOut "DEBUG" "$0:checkArgs() ENDED !"
}

# ----------------------------------------------------------
# It started monitoring patrol processing.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
startLoop() {
  logOut "DEBUG" "$0:startLoop() STARTED !"
  prepareDirs

  if [ -f "${pidfile}" ]; then
      logOut "Warn" "already running. try $0 status"
      exitLog 1
  fi

  logOut "DEBUG" "nohup $fullname ${config} run ver=$VERSION > /dev/null 2>&1 &"
  nohup $fullname ${config} run ver=$VERSION > /dev/null 2>&1 &

  # pidfile確認（リトライ）
  for i in {1..5}; do
      remain=$((5 - i))
      logOut "DEBUG" "Checking pidfile. ${remain}sec seconds remaining..."
      [ -s "${pidfile}" ] && break
      sleep 1
  done

  pid=`cat ${pidfile}`
  count=`ps auxww | grep ${pid} | grep -v grep | wc -l`
  if [ ${count} -eq 1 ]; then
    echo "may be launched."
    exit 0
  else
    echo "boot failure. check ${lockD}"
    [ -f ${logfile} ] && tail -5 ${logfile} || echo '(no logfile)'
    exit 1
  fi

  logOut "INFO" "may be launched. [pid=${pid}]"
  logOut "DEBUG" "$0:startLoop() ENDED !"
  exitLog 0
}

# ----------------------------------------------------------
# Stop monitoring patrol processing.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
stopLoop() {
  logOut "DEBUG" "$0:stopLoop() STARTED !"
  if [ -d ${lockD} ]; then
    if [ -f ${pidfile} ]; then
      pid=`cat ${pidfile}`
      logOut "DEBUG" "ps -aef | grep ${config##*/} | grep ${pid} | grep -v grep | wc -l"
      status=`ps -aef | grep ${config##*/} | grep ${pid} | grep -v grep | wc -l`
      if [ ${status} -eq 1 ]; then
        kill ${pid}
        logOut "INFO" "the process ${pid} was killed. return code : $?"
      else
        logOut "Warn" "there is no process to be stopped."
        exitLog 1
      fi
    else
      logOut "ERROR" "it may be corrupted. check environment." 1>&2
      exitLog 2
    fi
  else
    logOut "Warn" "there is no process to be stopped."
    exitLog 1
  fi
  logOut "DEBUG" "$0:stopLoop() ENDED !"
  exitLog 0
}

# ----------------------------------------------------------
# Check lock.
# ----------------------------------------------------------
# return   N/A
# ----------------------------------------------------------
checkLock() {
  logOut "DEBUG" "$0:checkLock() STARTED !"
  if [ -d ${lockD} ]; then
    if [ -f ${pidfile} ]; then
      pid=`cat ${pidfile}`
    fi
    if [ "${pid}" ]; then
      logOut "INFO" "is there doppelganger? please check pid=[${pid}]." 1>&2
      ps -aef | grep ${pid} | grep -v grep
      exitLog 0
    else
      logOut "ERROR" "it may be corrupted. check environment." 1>&2
      exitLog 2
    fi
  else
    mkdir -p ${lockD} || exitLog 1
    echo $$ > ${pidfile}
    cd ${lockD}
  fi
  logOut "DEBUG" "$0:checkLock() ENDED !"
}

# ----------------------------------------------------------
# pre-process
# ----------------------------------------------------------
scope="pre"
hostname=`hostname -s`
os=`uname -s`

#------------------------------------------------------------
# default variables
#------------------------------------------------------------
conf=""
name="cyclic"
basedir="$TMP_PATH/${name}"
logdir=${basedir}/log
lockD=${basedir}/lock
pidfile=${lockD}/pid
cmdfile=${lockD}/cmd
inifile=${lockD}/ini
logfile=$LOG_PATH/${name}.`date "+%Y%m%d"`.log
interval=60
threshold_warn=10
threshold_err=15
repeat=1
once=0
dumpvariables="name interval threshold_warn threshold_err basedir lockD pidfile cmdfile inifile logfile"

startLog

logOut "INFO" args: ["$@"]

checkArgs $*
# ----------------------------------------------------------
# main-routine
# ----------------------------------------------------------
scope="main"

TZ="JST-9"
export TZ
invoked=`pwd`
cd `dirname $0`
fullname=`pwd`/${0##*/}
cd /

# operation-1 group need config file for process information to run.
# check it before starting.
if [ $# -ge 2 ]; then
  config=$1
  shift
  searchConfig
  if [ ! -r ${config} ]; then
    logOut "ERROR" "ERROR. no such file [${config}]."
    exitLog 2
  fi
  loadConfig
  if [ $? -ne 0 ];then
    logOut "ERROR" "ERROR. can not load config [${config}]."
    exitLog 2
  fi
fi

case $1 in
  "log"    ) 
        echo "------------------------------------------------------------------------"
        tail $2 ${logfile}; 
        echo "------------------------------------------------------------------------" 
        exitLog 0
        ;;
  "start"  ) startLoop                              ;;
  "stop"   ) stopLoop                               ;;
  "dump"   ) cat ${inifile}; exitLog 0              ;;
  "once"   ) kill -USR1 `cat ${pidfile}`; exitLog 0 ;;
  "reload" ) kill -USR2 `cat ${pidfile}`; exitLog 0 ;;
  "status" ) checkStatus; exitLog 0                 ;;
  "cleanup") checkStatus clean; exitLog 0           ;;
  "run"    ) break                                  ;;
  *        ) usage; exitLog 0                       ;;
esac

# entering infinite loop.
checkLock

##########※ Do not move these params from here!!##########
# define signal traps. 
# see also  "man kill" and "/usr/include/sys/signal.h" for detail.
#define SIGHUP     1    /* hangup, generated when terminal disconnects */
#define SIGINT     2    /* interrupt, generated from terminal special char */
#define SIGQUIT    3    /* (*) quit, generated from terminal special char */
#define SIGTERM   15    /* software termination signal */
#define SIGUSR1   10    /* user defined signal 1 */
#define SIGUSR2   12    /* user defined signal 2 */
trap "terminate 0" 1 2 3 15
trap "once" 10
trap "reload" 12
###########################################################

# initialize.
switchLog
logOut "INFO" initializing...

# dump current setting variables for convenience.
dumpSetting

# main loop.
logOut "INFO" entering main loop.
while true
do
  switchLog
  loadCommand
  callProcess
  intermittentSleep
done

# ----------------------------------------------------------
# post-process
# ----------------------------------------------------------
scope="post"

exitLog 0
