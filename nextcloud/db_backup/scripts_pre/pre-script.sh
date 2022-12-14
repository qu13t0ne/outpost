#!/bin/bash

# #### Example Pre Script
# #### $1=DB_TYPE (Type of Backup)
# #### $2=DB_HOST (Backup Host)
# #### $3=DB_NAME (Name of Database backed up)
# #### $4=BACKUP START TIME (Seconds since Epoch)
# #### $5=BACKUP FILENAME (Filename)

logFile="/assets/logfiles/${2}_backups.log"
# Max log file size is 5 MB
maxSize=500000

if ( -f $logFile ); then
    fileSize=$(stat -c%s "$logFile")
    if (( fileSize > maxSize)); then
        mv $logFile $logFile.$(date +"%T").bak
        touch $logFile
    fi
else
    touch $logFile
fi

echo -e "$(date +"%T")\t${1} Backup Starting on ${2} for ${3} at ${4}. Filename: ${5}" >> $logFile
