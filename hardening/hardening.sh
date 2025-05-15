#!/bin/bash

# === CONFIG ===
PROJECT_ROOT="$HOME/Documents/intrusion-detection"
LOG_DIR="$PROJECT_ROOT/logs/hardening"
REPORT_FILE="$LOG_DIR/hardening_report_$(date +"%Y-%m-%d_%H-%M-%S").log"
INTEGRITY_DIR="$PROJECT_ROOT/integrity_checks"

mkdir -p "$LOG_DIR"
mkdir -p "$INTEGRITY_DIR"

log() {
    echo "[*] $1" | tee -a "$REPORT_FILE"
}

success() {
    echo "[✔] $1" | tee -a "$REPORT_FILE"
}

fail() {
    echo "[✘] $1" | tee -a "$REPORT_FILE"
}

log "Starting macOS Hardening..."
log "Report File: $(basename "$REPORT_FILE")"
log "Timestamp: $(date)"
log "----------------------------------------"

# === Disable Remote Login (SSH) ===
log "Disabling Remote Login (SSH)..."
if systemsetup -getremotelogin | grep -q "On"; then
    sudo systemsetup -f -setremotelogin off
fi
success "Remote Login is disabled"

# === Enable Firewall ===
log "Enabling Firewall..."
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
success "Firewall is enabled"

# === Enable Stealth Mode ===
log "Enabling Stealth Mode..."
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
if /usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode | grep -q "enabled"; then
    success "Stealth Mode is enabled"
else
    fail "Failed to enable Stealth Mode"
fi

# === Disable Guest Account ===
log "Disabling Guest Account..."
if dscl . -list /Users | grep -q "^Guest$"; then
    sudo dscl . -delete /Users/Guest 2>/dev/null && success "Guest account removed" || fail "Guest account removal failed"
else
    success "Guest account already removed"
fi

# === Enable Automatic Updates ===
log "Enabling Automatic Updates..."
sudo softwareupdate --schedule on
success "Automatic updates are enabled"

# === Disable AirDrop ===
log "Disabling AirDrop..."
defaults write com.apple.NetworkBrowser DisableAirDrop -bool true
success "AirDrop is disabled"

# === Disable Bluetooth ===
log "Disabling Bluetooth..."
sudo defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0
sudo pkill -HUP blued 2>/dev/null
success "Bluetooth is disabled"

# === Lock /tmp and /var/tmp permissions ===
log "Locking down /tmp and /var/tmp permissions..."
TMP_PERM=$(stat -f "%p" /tmp)
VARTMP_PERM=$(stat -f "%p" /var/tmp)
[ "$TMP_PERM" = "41777" ] && success "/tmp permissions are secure" || fail "/tmp permissions are insecure"
[ "$VARTMP_PERM" = "41777" ] && success "/var/tmp permissions are secure" || fail "/var/tmp permissions are insecure"

# === Enable Audit Framework ===
log "Enabling Audit Framework..."
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.auditd.plist 2>/dev/null
if pgrep auditd >/dev/null; then
    success "Auditd is running"
else
    fail "Auditd failed to start. Try running 'sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.auditd.plist'"
fi

# === Generate Checksums ===
log "Generating SHA256 Checksums of System Binaries..."
for DIR in /bin /sbin /usr/bin /usr/sbin; do
    log "  -> Scanning $DIR"
    find "$DIR" -type f -exec shasum -a 256 {} \; >> "$INTEGRITY_DIR/checksums_$(basename "$DIR").sha256"
done
log "Integrity hashes saved in $INTEGRITY_DIR/"

log "----------------------------------------"
log "Hardening complete! Reboot recommended for all changes to take effect."
