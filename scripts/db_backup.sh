#!/bin/bash

set -euo pipefail

PROJECT_DIR="/home/trainee/techkraft-devops-assignment"
BACKUP_DIR="/var/backups/db"
DATE=$(date "+%Y%m%d")
BACKUP_FILE="$BACKUP_DIR/db_backup_${DATE}.sql.gz"

cd "$PROJECT_DIR"

if [ ! -f ".env" ]; then
    echo "Error: .env file was not found"
    exit 1
fi

set -a
source .env
set +a

mkdir -p "$BACKUP_DIR"

docker compose exec -T db pg_dump \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" | gzip > "$BACKUP_FILE"

if [ -s "$BACKUP_FILE" ]; then
    echo "Database backup created successfully:"
    echo "$BACKUP_FILE"
else
    echo "Error: database backup failed"
    exit 1
fi

find "$BACKUP_DIR" \
    -type f \
    -name "db_backup_*.sql.gz" \
    -mtime +7 \
    -delete
