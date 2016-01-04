#!/bin/bash
#
#  brsync2nas.sh - Simple shell script for Backup with RSYNS to NAS
#
#  SYNOPSIS
#    brsync2nas.sh [<SRCD>  [<DSTNASMP> [<DSTNASMPSUBD>]]]
#
# SRCD - Top of directory tree to be backed up
# DSTNASMP - NFS Mount point of destination NAS (needs to be mounted)
# DSTNASMPSUBD - Subidrectory within NAS to be used (by default null - ".")
#
#
# LOGF - Log file location
# EXCLUDE - File with exclusions (rsync pattern format)

# Top directory to be backed up. No trailing "/"
SRCD=${1:-"/home"}; SRCD="${SRCD%/}"
if [[ ! -d $SRCD ]]; then
  echo Source directory ${SRCD} does not exist. Exiting.
  exit 1
fi

# Destination NFS mountpoint. No trailing "/"
DSTNASMP=${2:-"/qnap/Backup-$(hostname)"}; DSTNASMP="${DSTNASMP%/}"

# Subidrectory on NAS.
DSTNASMPSUBD="$3";
if [[ -n "${DSTNASMPSUBD}" ]]; then
  # If set make sure it starts with "/"
  [[ "${DSTNASMPSUBD}" = "${DSTNASMPSUBD#/}" ]] && DSTNASMPSUBD="/${DSTNASMPSUBD}"
fi

#Destination dir on NAS - don't change instead set DSTNASMP or DSTNASMPSUBD
DSTD="${DSTNASMP}${DSTNASMPSUBD}"

#Log, lock and excludes - allow different for different destination
MYNAME=$(basename $0)
BR2ND="$SRCD/.${MYNAME%.sh}${DSTNASMP}${DSTNASMPSUBD}"
LOGF="$BR2ND/log"
LOCKD="$BR2ND/lock"

# Exclude may be specific to destination or global for source directory tree
if [[ -f "$BR2ND/exclude" ]]; then
  EXCLUDEFROM="--exclude-from=$BR2ND/exclude"
elif [[ -f "$SRCD/.${MYNAME%.sh}/exclude" ]]; then
  EXCLUDEFROM="--exclude-from=$SRCD/.${MYNAME%.sh}/exclude"
fi

function finish {
  rmdir $LOCKD
}

mkdir -p $BR2ND
if
  mkdir $LOCKD 2> /dev/null
then
  trap finish EXIT SIGINT SIGTERM SIGKILL
else
  echo Cannot create $LOCKD. Insufficient permissions or another ${MYNAME} is still running. Exiting.
  exit 2
fi

if
  ! (mount | grep "$DSTNASMP type nfs" > /dev/null)
then
  echo NAS is not mounted on ${DSTNASMP}. Exiting.
  exit 3
fi

exec >> $LOGF 2>&1
echo $(date +"%D %T") ${MYNAME} starting.
rsync -avH --exclude=$LOCKD $EXCLUDEFROM --delete $SRCD $DSTD
echo $(date +"%D %T") ${MYNAME} finished.
exit 0
