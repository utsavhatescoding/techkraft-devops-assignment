#!/bin/bash

LOG_FILE="/var/log/infra_health.log"
APP_CONTAINER="trainee-app"
DISK_LIMIT=85
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

CPU_IDLE=$(LC_ALL=C top -bn1 | awk '/Cpu\(s\)/ {print $8}')
CPU_USAGE=$(awk -v idle="$CPU_IDLE" 'BEGIN {printf "%.1f", 100 - idle}')

RAM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
RAM_USED=$(free -m | awk '/^Mem:/ {print $3}')
RAM_PERCENT=$((RAM_USED * 100 / RAM_TOTAL))

DISK_USAGE=$(df -P / | awk 'NR==2 {gsub("%", "", $5); print $5}')

echo "Infrastructure Health Check - $TIMESTAMP"
echo "CPU usage: ${CPU_USAGE}%"
echo "RAM usage: ${RAM_USED}MB / ${RAM_TOTAL}MB (${RAM_PERCENT}%)"
echo "Root disk usage: ${DISK_USAGE}%"

if systemctl is-active --quiet docker; then
    echo "Docker service: running"
else
    echo "[WARNING] Docker service is not running"
    echo "$TIMESTAMP [WARNING] Docker service is not running" >> "$LOG_FILE"
fi

APP_RUNNING=$(docker inspect -f '{{.State.Running}}' "$APP_CONTAINER" 2>/dev/null)

if [ "$APP_RUNNING" = "true" ]; then
    echo "Application container: running"
else
    echo "[WARNING] Application container is stopped or missing"
    echo "$TIMESTAMP [WARNING] Application container is stopped or missing" >> "$LOG_FILE"
fi

if [ "$DISK_USAGE" -gt "$DISK_LIMIT" ]; then
    echo "[WARNING] Root disk usage is above ${DISK_LIMIT}%"
    echo "$TIMESTAMP [WARNING] Root disk usage is ${DISK_USAGE}%" >> "$LOG_FILE"
fi
