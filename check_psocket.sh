#!/bin/bash
#
# Check for processes accessing the Packet Socket.
# If a process exists get it's parent process tree
# in a single line
#
# For use with OSSEC.

pidtree () {
  M_PPID=$1
    # make sure pid exists before getting parents
    if ps --no-header --pid $M_PPID > /dev/null 2>&1; then
    COUNT=0
    while [ "$M_PPID" != "1" ] ; do
      # get pid, parent pid (ppid), user owning pid, and command name
      WPID_INFO="$( ps -p $M_PPID -o pid= -o ppid= -o ruser= -o cmd= )"
      # convert into array
      PID_INFO=(${WPID_INFO})
      # set to parent pid for next loop.
      M_PPID="${PID_INFO[1]}"
      PROC_LIST[${COUNT}]="${PID_INFO[@]:3:${#PID_INFO[@]}},${PID_INFO[0]},${PID_INFO[2]}"
      let COUNT=$COUNT+1
    done

    # create tree
    PID_TREE=''
    while [ $COUNT -ge 0 ] ; do
      PID_TREE="${PID_TREE}${PROC_LIST[${COUNT}]} ->"
      let COUNT=$COUNT-1
    done
    # Strip leading and trailing '->'
    PID_TREE=${PID_TREE# ->}
    PID_TREE=${PID_TREE%->}
    echo "$PID_TREE"
  else
    # report
    1>&2 echo "${M_PPID:=PID} not found."
    exit 1
  fi
}

# check for process accessing the packet socket
PID=$(sudo ss --packet -apn | grep users: | cut -d, -f2 )
if [ -n "$PID" ]; then
  PTREE="$(pidtree ${PID})"
  DATE_TIME="$(date +"%Y-%m-%d %H:%M:%S %z")"
  echo "${DATE_TIME} $(hostname -s) PACKET SOCKET ALERT: ${PTREE}"
fi
