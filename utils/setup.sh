#!/bin/bash

# === SETUP CONFIG ===
PROJECT_ROOT="$HOME/Documents/intrusion-detection"
LOG_FILE="$PROJECT_ROOT/logs/setup.log"
PID_FILE="$PROJECT_ROOT/utils/.monitor_pids"

ZEEK_MONITOR="$PROJECT_ROOT/monitors/zeek/zeek_trigger_monitor.sh"
FSWATCH_MONITOR="$PROJECT_ROOT/monitors/fswatch/fswatch_realtime.sh"
FIM_MONITOR="$PROJECT_ROOT/monitors/osquery/fim_monitor.sh"

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
echo -e "\n[*] === Setup started at $TIMESTAMP ===" >> "$LOG_FILE"

# Clear previous PIDs
echo -n "" > "$PID_FILE"

start_monitor() {
    local script_path=$1
    local name=$2

    if [ -x "$script_path" ]; then
        echo "[+] Launching $name..." >> "$LOG_FILE"
        nohup bash "$script_path" >> "$LOG_FILE" 2>&1 &
        echo $! >> "$PID_FILE"
    else
        echo "[!] $name not found or not executable: $script_path" >> "$LOG_FILE"
    fi
}

# === Start background monitors ===
start_monitor "$ZEEK_MONITOR" "Zeek Monitor"
start_monitor "$FSWATCH_MONITOR" "fswatch Real-time Monitor"

# === Run FIM one time (foreground) ===
if [ -x "$FIM_MONITOR" ]; then
    echo "[+] Running File Integrity Monitor (one-time)..." >> "$LOG_FILE"
    bash "$FIM_MONITOR" >> "$LOG_FILE" 2>&1
else
    echo "[!] FIM monitor not found or not executable." >> "$LOG_FILE"
fi

echo "[+] Setup completed at $(date)" >> "$LOG_FILE"
