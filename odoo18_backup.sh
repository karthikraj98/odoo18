#!/bin/bash

# Set paths and configuration
CONFIG_FILE="/var/lib/jenkins/workspace/job2/hosts.csv"
BACKUP_BASE_DIR="/var/lib/jenkins/odoo_backups_1"
CURRENT_IP=$(hostname -I | awk '{print $1}')
DATE=$(date +%Y-%m-%d_%H-%M-%S)
LOG_FILE="$BACKUP_BASE_DIR/backup_log_$DATE.txt"

# Ensure backup directory exists
mkdir -p "$BACKUP_BASE_DIR"

# Read config from CSV
IFS=, # Set comma as delimiter
tail -n +2 "$CONFIG_FILE" | while read ip db user; do
    if [[ "$ip" == "$CURRENT_IP" ]]; then
        DB_NAME="$db"
        DB_USER="$user"
        echo "[$(date)] Matched IP: $ip → $DB_NAME / $DB_USER" | tee -a "$LOG_FILE"
        break
    fi
done

# Check if DB_NAME and DB_USER are set
if [[ -z "$DB_NAME" || -z "$DB_USER" ]]; then
    echo "[$(date)] ERROR: No match found for IP $CURRENT_IP in $CONFIG_FILE" | tee -a "$LOG_FILE"
    exit 1
fi

# Set final backup file name
BACKUP_FILE="$BACKUP_BASE_DIR/${DB_NAME}_$DATE.dump"

# Perform the database dump
echo "[$(date)] Starting backup for $DB_NAME..." | tee -a "$LOG_FILE"
pg_dump -U "$DB_USER" -p 5432 -h 127.0.0.1 -Fc -v -f "$BACKUP_FILE" "$DB_NAME" >> "$LOG_FILE" 2>&1

if [[ $? -eq 0 ]]; then
    echo "[$(date)] Backup completed: $BACKUP_FILE" | tee -a "$LOG_FILE"
else
    echo "[$(date)] ERROR: Backup failed for $DB_NAME" | tee -a "$LOG_FILE"
    exit 2
fi

# Cleanup: Delete backups older than 7 days
echo "[$(date)] Cleaning up old backups..." | tee -a "$LOG_FILE"
find "$BACKUP_BASE_DIR" -type f -name "${DB_NAME}_*.dump" -mtime +7 -exec rm {} \; >> "$LOG_FILE" 2>&1
echo "[$(date)] Cleanup complete." | tee -a "$LOG_FILE"
