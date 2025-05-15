#!/bin/bash

# === CONFIG ===
PROJECT_ROOT="$HOME/Documents/intrusion-detection"
ZEEK_LOG_DIR="$PROJECT_ROOT/logs/zeek"
HARDENING_SCRIPT="$PROJECT_ROOT/hardening/hardening.sh"
TELEGRAM_ALERT="$PROJECT_ROOT/alerts/send_alert.py"

# === Thresholds ===
export SCAN_THRESHOLD=20        # Unique ports from one IP
export LATERAL_MOVE_THRESHOLD=5 # Unique internal IPs contacted

# === TIMESTAMP ===
NOW=$(date +"%Y-%m-%d %H:%M:%S")

# === Ensure log exists ===
if [[ ! -f "$ZEEK_LOG_DIR/conn.log" ]]; then
    echo "[!] Zeek conn.log not found — skipping trigger check."
    exit 1
fi

# === Check for Port Scanning ===
scan_alert=$(awk '{print $3}' "$ZEEK_LOG_DIR/conn.log" | sort | uniq -c | awk '$1 > ENVIRON["SCAN_THRESHOLD"]')
if [ -n "$scan_alert" ]; then
    echo "[!] Port scanning detected at $NOW"
    python3 "$TELEGRAM_ALERT" "[Zeek Alert] Port scanning detected at $NOW:\n\n$scan_alert"
    bash "$HARDENING_SCRIPT"
    exit 0
fi

# === Check for Lateral Movement (internal-to-internal IPs) ===
lateral_alert=$(awk '{if ($3 ~ /^192\.168\.|^10\.|^172\.(1[6-9]|2[0-9]|3[0-1])\./ && $5 ~ /^192\.168\.|^10\.|^172\.(1[6-9]|2[0-9]|3[0-1])\./) print $3, $5}' "$ZEEK_LOG_DIR/conn.log" | sort | uniq -c | awk '$1 > ENVIRON["LATERAL_MOVE_THRESHOLD"]')
if [ -n "$lateral_alert" ]; then
    echo "[!] Lateral movement detected at $NOW"
    python3 "$TELEGRAM_ALERT" "[Zeek Alert] Lateral movement detected at $NOW:\n\n$lateral_alert"
    bash "$HARDENING_SCRIPT"
    exit 0
fi

echo "[+] No suspicious activity at $NOW"

# === Run capture + analysis last ===
/bin/bash "$PROJECT_ROOT/monitors/zeek/capture_analyze.sh"
