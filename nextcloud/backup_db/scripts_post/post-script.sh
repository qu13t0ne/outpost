##!/bin/bash

# #### Example Post Script
# #### $1=EXIT_CODE (After running backup routine)
# #### $2=DB_TYPE (Type of Backup)
# #### $3=DB_HOST (Backup Host)
# #### #4=DB_NAME (Name of Database backed up
# #### $5=BACKUP START TIME (Seconds since Epoch)
# #### $6=BACKUP FINISH TIME (Seconds since Epoch)
# #### $7=BACKUP TOTAL TIME (Seconds between Start and Finish)
# #### $8=BACKUP FILENAME (Filename)
# #### $9=BACKUP FILESIZE
# #### $10=HASH (If CHECKSUM enabled)

logFile="/assets/logfiles/${3}_backups.log"

if [ ${1} -eq 0 ]; then
    echo -e "$(date +Iseconds)\tSUCCESS(${1})\t${2} Backup Completed on ${3} for ${4} on ${5} ending ${6} for a duration of ${7} seconds. Filename: ${8} Size: ${9} bytes SHA1: ${10}" >> $logFile
else
    echo -e "$(date +Iseconds)\tERROR(${1})\t${2} Backup Completed with errors on ${3} for ${4} on ${5} ending ${6} for a duration of ${7} seconds. Filename: ${8} Size: ${9} bytes SHA1: ${10}" >> $logFile
fi

# Monitor the log file directory and remove old files as necessary to keep it under 500 MB

# Set the size threshold for the directory in bytes
sizeThreshold=500000

# Check if the directory that the file is in is larger than the size threshold
while [ $(du -b "$logFile" | cut -f1) -gt $sizeThreshold ]
do
# Find the oldest file in the directory and delete it
    oldestFile=$(find "$(dirname "$FILE")" -type f -printf '%T@ %p\n' | sort -n | head -1 | cut -d' ' -f2)
    echo -e "$(date +Iseconds)\tLogfile directory exceeds size threshold. Removing file: $oldestFile" >> $logFile
    rm "$oldestFile"
done
