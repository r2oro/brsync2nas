#!/bin/bash
#
#  brsync2nas -- Simple shell script for NAS Backup
#
# SRCD - Source directory to Backup
# DSTNASMP - Desstination NAS mount point
# DSTD - Destination directory - assumes it is available
# LOGF - Log file location
# EXCLUDE - File with exclusions

SRCD=/home
BR2ND=$SRCD/.$(basename $0)
LOGF=$BR2ND/log
LOCKD=$BR2ND/lock
EXCLUDE=$BR2ND/exclude

DSTNASMP=/qnap/Backup-$(hostname)
DSTD=$DSTNASMP

if [ ! -d $SRCD ]; then
  echo Source directory $SRCD does not exist. Exiting.
  exit 1
fi

if
  ! (mount | grep "$DSTNASMP type nfs" > /dev/null)
then
  echo NAS to mounted on $DSTNASMP. Exiting.
  exit 2
fi

mkdir -p $BR2ND
if
  ! mkdir $LOCKD 2> /dev/null
then
  echo $LOCKD esists. Potentially another $(basename $0) is still running. Exiting.
  exit 3
fi


exec >> $LOGF 2>&1
echo $(date +"%D %T") $(basename $0) starting.
[ -f $EXCLUDE ] && EXCLUDEFROM="--exclude-from=$EXCLUDE"
rsync -avAHX --delete --exclude=$LOCKD $EXCLUDEFROM $SRCD $DSTD
rmdir $LOCKD
echo $(date +"%D %T") $(basename $0) finished.
exit 0
