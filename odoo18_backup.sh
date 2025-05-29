#!/bin/bash

CURRENT_IP=$(hostname -I | awk '{print $1}')
CONFIG_FILE="/path/to/hosts.csv"

IFS=, # set delimiter
tail -n +2 "$CONFIG_FILE" | while read ip db user; do
    if [[ "$ip" == "$CURRENT_IP" ]]; then
        DB_NAME="$db"
        DB_USER="$user"
        echo "Matched IP: $ip → $DB_NAME / $DB_USER"
        break
    fi
done
