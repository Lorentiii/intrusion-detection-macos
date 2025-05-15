#!/bin/bash

# === CONFIG ===
PROJECT_ROOT="$HOME/Documents/intrusion-detection"
OSQUERY_BIN="/usr/local/bin/osqueryi"
SNAPSHOT_DIR="$PROJECT_ROOT/snapshots/osquery"
LOG_FILE="$PROJECT_ROOT/logs/osquery/osquery.log"
HARDENING_SCRIPT="$PROJECT_ROOT/hardening/hardening.sh"
TELEGRAM_SCRIPT="$PROJECT_ROOT/alerts/telegram_bot/send_alert.py"
CAPTURE_ANALYZE_SCRIPT="$PROJECT_ROOT/monitors/zeek/capture_analyze.sh"
TEMP_OUTPUT="/tmp/osquery_fim.json"

# Create snapshot directory if missing
mkdir -p "$SNAPSHOT_DIR"

# Files and directories to monitor
MONITORED_PATHS=(
    "/etc"
    "/private/etc"
    "/usr/bin"
    "/usr/local/bin"
    "/tmp"
    "/Users/Shared"
)

# === BUILD SQL QUERY ===
build_query() {
    local query="SELECT path, mode, uid, gid, size FROM file WHERE "
    for i in "${!MONITORED_PATHS[@]}"; do
        local path="${MONITORED_PATHS[$i]}"
        query+="path LIKE '$path/%'"
        if [ "$i" -lt "$((${#MONITORED_PATHS[@]} - 1))" ]; then
            query+=" OR "
        fi
    done
    echo "$query;"
}

# === RUN QUERY ===
QUERY=$(build_query)
"$OSQUERY_BIN" --json "$QUERY" > "$TEMP_OUTPUT"
if [ $? -ne 0 ]; then
    echo "[!] Error running osquery at $(date)" >> "$LOG_FILE"
    exit 1
fi

# === COMPARE SNAPSHOTS ===
SNAPSHOT_FILE="$SNAPSHOT_DIR/fim_snapshot.json"

# First run: save snapshot and exit
if [ ! -f "$SNAPSHOT_FILE" ]; then
    cp "$TEMP_OUTPUT" "$SNAPSHOT_FILE"
    echo "[+] First run. Snapshot saved at $(date)" >> "$LOG_FILE"
    exit 0
fi

# Detect differences
DIFF=$(diff <(jq -S . "$SNAPSHOT_FILE") <(jq -S . "$TEMP_OUTPUT"))

if [ -n "$DIFF" ]; then
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[!] File changes detected at $TIMESTAMP" >> "$LOG_FILE"
    echo "$DIFF" >> "$LOG_FILE"

    # Trigger PCAP + Zeek
    bash "$CAPTURE_ANALYZE_SCRIPT"

    # Send Telegram alert
    python3 "$TELEGRAM_SCRIPT" "[FIM Alert] File changes detected at $TIMESTAMP. Triggering hardening."

    # Run hardening
    bash "$HARDENING_SCRIPT"

    # Update snapshot
    cp "$TEMP_OUTPUT" "$SNAPSHOT_FILE"
else
    echo "[+] No changes detected at $(date)" >> "$LOG_FILE"
fi
