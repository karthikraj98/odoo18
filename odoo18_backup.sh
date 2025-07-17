#!/bin/bash

# Get current IP
CURRENT_IP=$(hostname -I | awk '{print $1}')
CONFIG_FILE="$(dirname "$0")/hosts.csv"

# Default values (in case no match is found)
DB_NAME=""
DB_USER=""

# Log timestamp
log() {
    echo "[$(date '+%A %d %B %Y %I:%M:%S %p %Z')] $1"
}

# Read CSV and match IP
if [[ -f "$CONFIG_FILE" ]]; then
    IFS=,
    while read ip db user; do
        if [[ "$ip" == "$CURRENT_IP" ]]; then
            DB_NAME="$db"
            DB_USER="$user"
            log "Matched IP: $ip → $DB_NAME / $DB_USER"
            break
        fi
    done < <(tail -n +2 "$CONFIG_FILE")
else
    log "ERROR: Config file not found at $CONFIG_FILE"
    exit 1
fi

# Exit if no match found
if [[ -z "$DB_NAME" || -z "$DB_USER" ]]; then
    log "ERROR: No match found for IP $CURRENT_IP in $CONFIG_FILE"
    exit 1
fi

# Backup directory and file
BACKUP_DIR="/var/lib/jenkins/odoo_backups_1"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_$DATE.dump"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Dump the database
pg_dump -U "$DB_USER" -p 5432 -h 127.0.0.1 -Fc -v -f "$BACKUP_FILE" "$DB_NAME"
if [[ $? -eq 0 ]]; then
    log "Backup completed: $BACKUP_FILE"
else
    log "ERROR: Backup failed!"
    exit 1
fi

# Delete backups older than 7 days
find "$BACKUP_DIR" -type f -name "${DB_NAME}_*.dump" -mtime +7 -exec rm {} \;
log "Old backups deleted (older than 7 days)"
