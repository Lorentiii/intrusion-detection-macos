#!/bin/bash

# === CONFIG ===
PROJECT_ROOT="$HOME/Documents/intrusion-detection"
LOG_FILE="$PROJECT_ROOT/logs/setup.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# === COLORS ===
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m" # No Color

echo -e "${BLUE}=== Monitor Status Report ===${NC}"
echo -e "Checked at: $TIMESTAMP\n"

# === fswatch monitor ===
fswatch_pid=$(pgrep -f "fswatch_realtime.sh")
if [ -n "$fswatch_pid" ]; then
    echo -e "[${GREEN}✓${NC}] fswatch monitor is running (PID $fswatch_pid)"
else
    echo -e "[${RED}✗${NC}] fswatch monitor is NOT running"
fi

# === Zeek monitor ===
zeek_pid=$(pgrep -f "zeek_trigger_monitor.sh")
if [ -n "$zeek_pid" ]; then
    echo -e "[${GREEN}✓${NC}] Zeek monitor is running (PID $zeek_pid)"
else
    echo -e "[${RED}✗${NC}] Zeek monitor is NOT running"
fi

# === File Integrity Monitor (osquery) ===
fim_last_run=$(grep "Running File Integrity Monitor" "$LOG_FILE" | tail -1 | cut -d']' -f1 | tr -d '[')
if [ -n "$fim_last_run" ]; then
    echo -e "[${YELLOW}~${NC}] File Integrity Monitor last ran at: $fim_last_run"
else
    echo -e "[${RED}✗${NC}] File Integrity Monitor has not run yet"
fi

echo -e "\n${BLUE}=== End of Report ===${NC}"
