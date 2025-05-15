#!/bin/bash

# === CONFIG ===
PROJECT_ROOT="$HOME/Documents/intrusion-detection"
LOG_DIR="$PROJECT_ROOT/logs/zeek"
PCAP_DIR="$LOG_DIR/pcaps"
CAPTURE_DURATION=30  # 30 seconds of pcap
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
PCAP_FILE="$PCAP_DIR/pcap_$TIMESTAMP.pcap"
ZEEK_TMP_DIR="$PROJECT_ROOT/tmp_zeek_logs_$TIMESTAMP"

# === INIT ===
mkdir -p "$PCAP_DIR"
mkdir -p "$ZEEK_TMP_DIR"
echo "[*] Starting PCAP capture for $CAPTURE_DURATION seconds at $(date)" >> "$LOG_DIR/pcap_monitor.log"

# === PACKET CAPTURE ===
sudo tcpdump -i any -w "$PCAP_FILE" -G "$CAPTURE_DURATION" -W 1 >/dev/null 2>&1

# === ANALYZE WITH ZEEK ===
zeek -r "$PCAP_FILE" Log::default_path="$ZEEK_TMP_DIR" >/dev/null 2>&1

# === MOVE ZEEK LOGS TO LOG_DIR ===
if [ -d "$ZEEK_TMP_DIR" ] && [ "$(ls -A "$ZEEK_TMP_DIR")" ]; then
    mv "$ZEEK_TMP_DIR"/* "$LOG_DIR/"
    rmdir "$ZEEK_TMP_DIR"
else
    echo "[!] No Zeek logs generated for $PCAP_FILE" >> "$LOG_DIR/pcap_monitor.log"
fi

# === SEND TELEGRAM ALERT ===
python3 "$PROJECT_ROOT/alerts/telegram_bot/send_alert.py" "[Zeek PCAP] Suspicious activity captured and analyzed at $TIMESTAMP"

# === TRIGGER HARDENING ===
/bin/bash "$PROJECT_ROOT/hardening/hardening.sh"
echo "[*] Hardening script triggered after PCAP capture at $(date)" >> "$LOG_DIR/pcap_monitor.log"

# === CLEAN OLD PCAPs (older than 7 days) ===
find "$PCAP_DIR" -name "pcap_*.pcap" -type f -mtime +7 -delete

echo "[+] PCAP capture, analysis, and hardening complete at $(date)" >> "$LOG_DIR/pcap_monitor.log"