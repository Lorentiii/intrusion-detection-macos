#!/usr/bin/env python3
import os
import requests
from dotenv import load_dotenv
import sys

# Load .env file
load_dotenv(os.path.expanduser("~/Documents/intrusion-detection/.env"))


# Get Telegram credentials
TOKEN = os.getenv("TELEGRAM_TOKEN")
CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")

# Use message from CLI argument or default
message = sys.argv[1] if len(sys.argv) > 1 else "🚨 Telegram bot test successful from your Mac!"

# Telegram API endpoint
url = f"https://api.telegram.org/bot{TOKEN}/sendMessage"

# Send message
response = requests.post(url, data={"chat_id": CHAT_ID, "text": message})

if response.status_code == 200:
    print("[+] Telegram message sent successfully.")
else:
    print(f"[!] Failed to send Telegram message. Status: {response.status_code}")
