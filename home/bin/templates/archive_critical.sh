
cd $homedir

date=`date +%Y/%m/%d`
backupdir=$backup_directory
arcdir="$backupdir/$date"

echo $0: ACIS nightly backup/archiving 
echo `date`

if test -z "$backupdir"; then
   echo Error: specify backup-directory in main.conf and run bin/setup
   exit 1
fi
if test ! -d "$backupdir"; then
   echo "Error: specified backup directory doesn't exist: $backupdir"
   exit 2
fi


# prepare the backup/archive directory
cd $backupdir
mkdir -p $date && test -d $arcdir && echo will backup and archive things to $arcdir

### backup important data
cd $homedir


# archive userdata and deleted userdata
echo ... userdata
tar czf $arcdir/userdata.tgz         userdata 2>/dev/null
echo ... deleted userdata
tar czf $arcdir/deleted-userdata.tgz deleted-userdata 2>/dev/null

###  ARCHIVE SHORT-ID LOGS
echo ... short-id logs
tar czf $arcdir/short-id.log.tgz SID/short-id.log


#
# Restart RePEc-Index daemon and backup update logs
#
echo Restart RePEc-Index daemon and backup update logs
ridir=$homedir/RI
bdbbindir=$berkeleydb_bin_dir
if test "$bdbbindir"; then 
  bdbbindir="$bdbbindir/"
else 
  bdbbindir=''
fi

echo bdbbindir: $bdbbindir

$homedir/bin/rid stop && {

echo backup update daemon logs and data to $arcdir

cd $ridir
tar czf $arcdir/update_logs.tgz --remove-files ri.log daemon.log update_ch*.log 

### intiate checkpoint, remove unneeded log files, archive database
echo ${bdbbindir}db_checkpoint -1 -h $ridir/data && echo ${bdbbindir}db_archive -d -h $ridir/data && echo db checkpoint ok 

cd $homedir
tar czf $arcdir/update_db.tgz RI/data && echo packed the data

find $backupdir -name update_db.tgz -mtime +1 -print | xargs echo will remove these old files:
find $backupdir -name update_db.tgz -mtime +1 -print | xargs /bin/rm -f

}

$homedir/bin/rid start
