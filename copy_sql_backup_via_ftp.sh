#!/bin/bash

PID=$$
FILE=$(date +%F).${PID}.sql

# FTP Settings
FTP_HOST="SERVER_ID"
FTP_USER="FTP_USER"
FTP_PASS="PASSWORD"
REMOTE_DIR="/SQLBACKUP"

# Local backup directory
LOCAL_BACKUP_DIR="/home/max/sql_backup"

# Create backup directory if it doesn't exist
mkdir -p "${LOCAL_BACKUP_DIR}"

# Create MySQL dump directly in the backup directory
mysqldump -u mysql_user_name --password=mysql_password database_name > "${LOCAL_BACKUP_DIR}/${FILE}"

# Check if mysqldump succeeded
if [ $? -ne 0 ]; then
    echo "Error creating MySQL dump. Exiting."
    exit 1
fi

# Verify the backup file exists and is not empty
BACKUP_FILE="${LOCAL_BACKUP_DIR}/${FILE}"
if [ ! -s "${BACKUP_FILE}" ]; then
    echo "Backup file is empty or not created. Exiting."
    exit 1
fi

# Log the backup
logger -t mysqldump -p user.info "Eseguito regolarmente backup in folder ${LOCAL_BACKUP_DIR}"

# Upload using FTP
ftp -n <<EOF
open ${FTP_HOST}
user ${FTP_USER} ${FTP_PASS}
binary
cd ${REMOTE_DIR}
put "${BACKUP_FILE}" "${FILE}"
bye
EOF

# Check if FTP succeeded
if [ $? -eq 0 ]; then
    echo "Backup successfully transferred to QNAP NAS"
    # Clean up only if transfer was successful
    rm -f "${BACKUP_FILE}"
else
    echo "Error transferring backup to QNAP NAS"
    exit 1
fi

exit 0
