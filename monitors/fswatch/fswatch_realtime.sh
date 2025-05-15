#!/bin/bash

# === CONFIG ===
PROJECT_ROOT="$HOME/Documents/intrusion-detection"
WATCH_PATHS=(
    "/etc"
    "/var/log"
    "/usr/bin"
    "/usr/local/bin"
    "/tmp"
    "/Users/Shared"
    "/private/etc"
    "/etc/passwd"
    "/etc/shadow"
    "/etc/sudoers"
)

LOG_FILE="$PROJECT_ROOT/logs/fswatch/fswatch.log"
EVENT_CACHE="$PROJECT_ROOT/logs/fswatch/fswatch_event_cache.tmp"
THROTTLE_SECONDS=60
CAPTURE_SCRIPT="$PROJECT_ROOT/monitors/zeek/capture_analyze.sh"
TELEGRAM_SCRIPT="$PROJECT_ROOT/alerts/telegram_bot/send_alert.py"

# === INIT ===
touch "$EVENT_CACHE"
echo "=== Real-time FSWatch started at $(date) ===" >> "$LOG_FILE"

# === Function: Determine Severity ===
get_severity_level() {
    case "$event" in
        *"/etc/shadow"* | *"/etc/passwd"* | *"/etc/sudoers"* )
            echo "CRITICAL" ;;
        *"/var/log/"* | *"/Users/Shared/"* )
            echo "HIGH" ;;
        *"/private/etc/"* )
            echo "MEDIUM" ;;
        *"/etc/"* | *"/usr/bin/"* | *"/usr/local/bin/"* )
            echo "LOW" ;;
        *"/tmp/"* )
            echo "INFO" ;;
        * )
            echo "UNKNOWN" ;;
    esac
}

# === START MONITORING ===
sudo fswatch -0 -r "${WATCH_PATHS[@]}" | while read -r -d "" event; do
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    EVENT_HASH=$(echo "$event" | md5)

    # Check for recent event (throttle)
    if grep -q "$EVENT_HASH" "$EVENT_CACHE"; then
        continue
    fi

    # Log + Cache
    echo "$EVENT_HASH|$(date +%s)" >> "$EVENT_CACHE"

    SEVERITY=$(get_severity "$event")
    echo "[$TIMESTAMP] [$SEVERITY] Filesystem change detected: $event" >> "$LOG_FILE"

    # Alert + Trigger only if severity is HIGH or CRITICAL
    if [[ "$SEVERITY" == "CRITICAL" || "$SEVERITY" == "HIGH" ]]; then
        python3 "$TELEGRAM_SCRIPT" "[FSWatch $SEVERITY] Change detected: $event"
        /bin/bash "$CAPTURE_SCRIPT"
    fi

    # Cleanup old entries
    awk -F'|' -v now="$(date +%s)" -v t="$THROTTLE_SECONDS" \
        '{ if (now - $2 < t) print $0; }' "$EVENT_CACHE" > "$EVENT_CACHE.tmp" && mv "$EVENT_CACHE.tmp" "$EVENT_CACHE"
done