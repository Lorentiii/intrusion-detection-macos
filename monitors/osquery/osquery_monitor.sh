#!/bin/bash

# === Strict settings ===
set -euo pipefail
IFS=$'\n\t'

# === Config & Paths ===
PROJECT_ROOT="$HOME/Documents/intrusion-detection"
OSQUERY_BIN="/opt/osquery/lib/osquery.app/Contents/MacOS/osqueryi"
SNAPSHOT_DIR="$PROJECT_ROOT/snapshots/osquery"
LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE="$LOG_DIR/osquery_$(date +%F_%H-%M-%S).log"
TELEGRAM_SCRIPT="$PROJECT_ROOT/alerts/send_alert.py"
TEMP_OUTPUT="/tmp/osquery_fim.json"  #!=============================

# === Ensure directories ===
mkdir -p "$SNAPSHOT_DIR"
mkdir -p "$LOG_DIR"

# === Paths to monitor ===
MONITORED_PATHS=(
    "/etc"
    "/private/etc"
    "/usr/bin"
    "/usr/local/bin"
    "/tmp"
    "/Users/Shared"
)

# === Build SQL query dynamically ===
build_query() {
    local query="SELECT path, mode, uid, gid, size, sha256 FROM file WHERE "
    for i in "${!MONITORED_PATHS[@]}"; do
        query+="path LIKE '${MONITORED_PATHS[$i]}/%'"
        if [ "$i" -lt "$(( ${#MONITORED_PATHS[@]} - 1 ))" ]; then
            query+=" OR "
        fi
    done
    echo "$query;"
}

QUERY=$(build_query)
SNAPSHOT_FILE="$SNAPSHOT_DIR/fim_snapshot.json"

# === Run osquery ===
if ! "$OSQUERY_BIN" --json "$QUERY" > "$TEMP_OUTPUT"; then
    echo "[!] Osquery execution failed at $(date)" >> "$LOG_FILE"
    exit 1
fi

# === Dry-run support ===
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "[*] Dry run mode active — no alert will be sent." >> "$LOG_FILE"
fi

# === First run baseline snapshot ===
if [ ! -f "$SNAPSHOT_FILE" ]; then
    cp "$TEMP_OUTPUT" "$SNAPSHOT_FILE"
    echo "[+] First run. Snapshot saved at $(date)." >> "$LOG_FILE"
    exit 0
fi

# === Diff with old snapshot ===
DIFF=$(diff <(jq -S . "$SNAPSHOT_FILE") <(jq -S . "$TEMP_OUTPUT"))

if [ -n "$DIFF" ]; then
    echo "[!] Changes detected at $(date)" >> "$LOG_FILE"
    echo "$DIFF" >> "$LOG_FILE"

    SHORT_DIFF=$(echo "$DIFF" | grep '"path"' | head -n 10)

    if [ "$DRY_RUN" = false ]; then
        python3 "$TELEGRAM_SCRIPT" "[Osquery Alert] File changes detected!\n\n$SHORT_DIFF\n\n(See log for full diff)"
    else
        echo "[*] Dry run: Alert suppressed." >> "$LOG_FILE"
    fi

    cp "$TEMP_OUTPUT" "$SNAPSHOT_FILE"
else
    echo "[+] No changes at $(date)" >> "$LOG_FILE"
fi

# === Cleanup old logs ===
find "$LOG_DIR" -name "osquery_*.log" -mtime +7 -exec rm {} \;

# === Optional: Remove Zeek capture call unless intended ===
# /bin/bash "$PROJECT_ROOT/montior/zeek/capture_analyze.sh"
