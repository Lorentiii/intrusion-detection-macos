#!/bin/bash

PROJECT_ROOT="$HOME/Documents/intrusion-detection"
PID_FILE="$PROJECT_ROOT/utils/.monitor_pids"
LOG_FILE="$PROJECT_ROOT/logs/shutdown.log"

echo "[*] Shutdown started at $(date)" >> "$LOG_FILE"

if [ -f "$PID_FILE" ]; then
    while read -r pid; do
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "[+] Killing process $pid" >> "$LOG_FILE"
            kill "$pid"
        fi
    done < "$PID_FILE"
    echo "[+] Cleanup done." >> "$LOG_FILE"
    rm "$PID_FILE"
else
    echo "[!] No PID file found. Nothing to stop." >> "$LOG_FILE"
fi

echo "[+] Shutdown complete at $(date)" >> "$LOG_FILE"