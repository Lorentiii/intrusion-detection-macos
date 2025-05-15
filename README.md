# intrusion-detection-macos
 Real-Time Intrusion Detection System for macOS (Demo Version) Monitors file integrity, suspicious network activity, and system changes using Zeek, osquery, and fswatch. Sends smart alerts via Telegram.

Intrusion Detection Project (macOS Demo)

This project is a macOS-based intrusion detection system (IDS) demo, designed to monitor and alert on suspicious system and network activity. It leverages open-source tools integrated with custom scripts to provide real-time insights into potential security threats.
Note: This is a demo tailored for macOS environments. A deployable and production-ready Linux version is planned for future release.


The system combines multiple monitoring layers, each focusing on different threat vectors:
1. Zeek Network Monitoring
Purpose: Zeek inspects live network traffic and generates detailed logs about connections, protocols, and suspicious events.
What it detects: Unusual port scanning, failed login attempts, lateral movement attempts, connections to known malicious IPs, and abnormal traffic spikes (potential DDoS).
Data output: Zeek produces human- and machine-readable logs, including connection summaries and security events, stored in designated log directories.
Triggering: Custom scripts parse these logs to detect defined anomalies and raise alerts.
1. Osquery File Integrity Monitoring
Purpose: Osquery runs scheduled queries to detect changes in important system files and binaries, ensuring system integrity.
What it detects: Unexpected modifications, additions, or deletions in critical files that could indicate compromise or malware.
Snapshots: Osquery exports JSON snapshots of the current state, which are compared over time.
Alerts: When deviations from baseline are detected, alerts are generated.
1. Fswatch Filesystem Monitoring
Purpose: Watches real-time filesystem events for rapid detection of changes in key directories.
What it detects: Immediate creation, deletion, or modification of monitored files/folders.
Use case: Complements osquery by catching real-time changes that might be missed between snapshot intervals.
Alert Severity & Color Coding

To help prioritize responses, alerts are color-coded by severity:
🔴 Red (Critical): High-confidence indicators of active intrusion, such as confirmed lateral movement, unauthorized binary changes, or known malicious IP communication.
🟡 Yellow (Warning): Suspicious but less certain events, like unusual port scans or repeated failed logins that warrant investigation.
🟢 Green (Informational): Normal or low-risk activities, such as routine system events or successful monitoring script startups.
Alerts are delivered through a Telegram bot, providing real-time notifications to the system administrator or security team.
Core Setup Script: setup.sh

This script automates initial environment preparation and system activation:
Dependency Verification and Installation:
Checks for required tools (Zeek, osquery, fswatch) and installs missing components, ensuring the system has all necessary capabilities.
Directory Structure Creation:
Establishes organized folders for logs, PCAP captures, osquery snapshots, and integrity checks to maintain data separation and facilitate analysis.
Environment Variable Loading:
Securely loads sensitive data from the .env file—this includes Telegram tokens, API keys, and encryption passphrases—preventing accidental exposure in code or logs.
Monitor Initialization:
Starts the Zeek, osquery, and fswatch monitoring scripts, which run continuously or on schedules, enabling persistent system and network surveillance.
Log Rotation and Maintenance:
Sets up automated log rotation and cleanup routines to manage disk space and keep logs manageable over time.