#!/bin/bash

# Variables
BACKUP_DIR="/home/odoo/odoo_backups"
DB_NAME="odoo18"
DB_USER="odoo18"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_$DATE.dump"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Dump the database without compression
pg_dump -U "$DB_USER" "$DB_NAME" -p 5432 -U odoo18 -h 127.0.0.1 -Fc -v -f "$BACKUP_FILE"

# Optional: Delete backups older than 7 days
find "$BACKUP_DIR" -type f -name "${DB_NAME}_*.sql" -mtime +7 -exec rm {} \;

