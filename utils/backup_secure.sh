#!/bin/bash

# === CONFIGURATION ===
BACKUP_SOURCE="$HOME/Documents/intrusion-detection"
BACKUP_TARGET="$HOME/Documents/intrusion-detection/backups"
SNAPSHOT_DIR="$BACKUP_TARGET/snapshots"
ENCRYPTED_DIR="$BACKUP_TARGET/encrypted"
ENCRYPTION_PASSWORD_FILE="$HOME/.backup_passphrase"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_NAME="backup_$TIMESTAMP.tar.gz"
ENCRYPTED_NAME="$BACKUP_NAME.enc"

# === SETUP DIRECTORIES ===
mkdir -p "$SNAPSHOT_DIR"
mkdir -p "$ENCRYPTED_DIR"

# === CREATE TAR ARCHIVE ===
tar --exclude="$BACKUP_TARGET" \
    -czf "$SNAPSHOT_DIR/$BACKUP_NAME" "$BACKUP_SOURCE"

# === ENCRYPT THE BACKUP ===
if [ ! -f "$ENCRYPTION_PASSWORD_FILE" ]; then
    echo "[ERROR] Password file not found at $ENCRYPTION_PASSWORD_FILE"
    exit 1
fi

openssl enc -aes-256-cbc -salt -pbkdf2 \
    -in "$SNAPSHOT_DIR/$BACKUP_NAME" \
    -out "$ENCRYPTED_DIR/$ENCRYPTED_NAME" \
    -pass file:"$ENCRYPTION_PASSWORD_FILE"

# === REMOVE UNENCRYPTED TAR ===
rm -f "$SNAPSHOT_DIR/$BACKUP_NAME"

# === ROTATE: KEEP ONLY LAST 5 BACKUPS ===
cd "$ENCRYPTED_DIR" || exit 1

# Read sorted backup list safely into array
mapfile -t BACKUPS < <(find . -maxdepth 1 -type f -name "backup_*.tar.gz.enc" -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2-)

if [ "${#BACKUPS[@]}" -gt 5 ]; then
    for ((i=5; i<${#BACKUPS[@]}; i++)); do
        rm -f "${BACKUPS[$i]}"
    done
fi

echo "[+] Backup completed and encrypted at $(date)"
