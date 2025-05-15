#!/bin/bash

# === CONFIG ===
PROJECT_ROOT="$HOME/Documents/intrusion-detection"
LOG_DIR="$PROJECT_ROOT/logs"
ARCHIVE_DIR="$LOG_DIR/archive"
DATE=$(date "+%Y-%m-%d")
LOG_FILES=("fswatch/fswatch.log" "zeek/pcap_monitor.log")  # Add other logs here

# === INIT ===
mkdir -p "$ARCHIVE_DIR"

# === ROTATE LOGS ===
for relative_path in "${LOG_FILES[@]}"; do
    log_path="$LOG_DIR/$relative_path"
    log_name=$(basename "$log_path")
    if [ -f "$log_path" ]; then
        echo "[*] Rotating $log_name"
        mv "$log_path" "$ARCHIVE_DIR/${log_name%.*}_$DATE.log"
        touch "$log_path"
    else
        echo "[!] Skipping $log_name (not found)"
    fi
done

# === CLEAN OLD LOGS (older than 7 days) ===
find "$ARCHIVE_DIR" -type f -name "*.log" -mtime +7 -exec rm {} \;

echo "[+] Log rotation complete on $(date)"