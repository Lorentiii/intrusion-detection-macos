#!/bin/bash
set -e

# Zeek Monitor Script
# Captures 1 min of traffic, analyzes with Zeek, and sends alert on suspicious activity

# === CONFIG ===
PROJECT_ROOT="$HOME/Documents/intrusion-detection"
INTERFACE="en0"  # Replace if needed (ifconfig)
DURATION=60  # packet capture in seconds
TELEGRAM_SCRIPT="$PROJECT_ROOT/alerts/send_alert.py"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_BASE_DIR="$PROJECT_ROOT/logs/zeek/pcaps"
LOG_DIR="$LOG_BASE_DIR/$TIMESTAMP"
PCAP_FILE="$LOG_DIR/capture.pcap"
ALERT_MSG="⚠️ Zeek Alert: Suspicious activity detected. Logs saved at $LOG_DIR"

# === PREP ===
mkdir -p "$LOG_DIR"

# === CAPTURE ===
echo "[*] Capturing $DURATION seconds of traffic from $INTERFACE..."
sudo tcpdump -i "$INTERFACE" -nn -s 0 -w "$PCAP_FILE" port 1-1024 &
TCPDUMP_PID=$!

sleep "$DURATION"
kill "$TCPDUMP_PID"
echo "[*] Capture complete: $PCAP_FILE"

# === ZEEK ANALYSIS ===
echo "[*] Running Zeek analysis..."
cd "$LOG_DIR"
zeek -r "$(basename "$PCAP_FILE")" Log::default_path="$LOG_DIR" frameworks/notice main
cd - >/dev/null

# === ALERT ON NOTICE ===
if [[ -s "$LOG_DIR/notice.log" ]]; then
    echo "[!] Suspicious activity found. Sending Telegram alert..."
    python3 "$TELEGRAM_SCRIPT" "$ALERT_MSG"
fi

# === CLEANUP (OLDER THAN 7 DAYS) ===
echo "[*] Cleaning up old logs..."
find "$LOG_BASE_DIR" -type d -mtime +7 -exec rm -rf {} \;

echo "[+] Zeek monitor complete. Logs saved in: $LOG_DIR"
