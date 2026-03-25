#!/bin/bash
# Linux Baseline - Baseline Security Snapshot Tool
# Outputs: baseline-report.html, baseline-report.txt, evidence/

set -euo pipefail

OUTPUT_DIR="$(pwd)/linux-baseline-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"
HTML_FILE="$OUTPUT_DIR/baseline-report.html"
TXT_FILE="$OUTPUT_DIR/baseline-report.txt"
EVIDENCE_DIR="$OUTPUT_DIR/evidence"
mkdir -p "$EVIDENCE_DIR"

# Function to append to TXT and HTML — reads from stdin
log_section() {
    local title="$1"
    echo "=== $title ===" >> "$TXT_FILE"
    echo "<h2>$title</h2>" >> "$HTML_FILE"
    echo "<pre>" >> "$HTML_FILE"
    tee -a "$TXT_FILE" >> "$HTML_FILE"
    echo "</pre>" >> "$HTML_FILE"
    echo "" >> "$TXT_FILE"
}

# Function to copy evidence files (accepts multiple args)
collect_evidence() {
    for src in "$@"; do
        local dst="$EVIDENCE_DIR/$(echo "$src" | sed 's|/|-|g; s|^-||')"
        if [[ -r "$src" ]]; then
            cp "$src" "$dst"
        fi
    done
}

# Header — note: unquoted heredoc EOF so $(date) and $(hostname) expand
cat > "$HTML_FILE" << EOF
<!DOCTYPE html>
<html><head><title>Linux Baseline</title>
<style>body{font-family:monospace;white-space:pre-wrap;} h1,h2{color:#333;} pre{background:#f4f4f4;padding:10px;border:1px solid #ddd;}</style></head>
<body>
<h1>Linux Baseline - $(date)</h1>
<p>Hostname: $(hostname)</p>
<p>Generated: $(date)</p>
EOF

echo "Linux Baseline - $(date)" > "$TXT_FILE"
echo "Hostname: $(hostname)" >> "$TXT_FILE"
echo "Generated: $(date)" >> "$TXT_FILE"
echo "" >> "$TXT_FILE"

# 1. System Info
(
    uname -a
    cat /etc/os-release
    uptime
) | log_section "1. System Information"

# 2. Current Users and UID Mapping
(
    column -t -s: < /etc/passwd
) | log_section "2. Users and UID Mapping"
collect_evidence /etc/passwd /etc/group

# 3. SSH Configuration
(
    grep -v '^#' /etc/ssh/sshd_config 2>/dev/null | grep -v '^$' || echo "sshd_config not found"
) | log_section "3. SSH Configuration (/etc/ssh/sshd_config)"
collect_evidence /etc/ssh/sshd_config

# 4. Authorized Keys per User
(
    for user in $(cut -d: -f1 /etc/passwd); do
        home=$(eval echo "~$user")
        keyfile="$home/.ssh/authorized_keys"
        if [[ -r "$keyfile" ]]; then
            echo "=== $user ($keyfile) ==="
            sed 's/^/  /' "$keyfile"
        fi
    done
) | log_section "4. Authorized Keys per User"
for user in $(cut -d: -f1 /etc/passwd); do
    home=$(eval echo "~$user")
    collect_evidence "$home/.ssh/authorized_keys"
done

# 5. Open Ports and Listening Services
(
    ss -tulnp 2>/dev/null || netstat -tulnp 2>/dev/null || echo "Neither ss nor netstat available"
) | log_section "5. Open Ports and Listening Services"

# 6. Cron Jobs
(
    echo "=== User Crontabs ==="
    for user in $(cut -d: -f1 /etc/passwd); do
        echo "--- $user ---"
        crontab -u "$user" -l 2>/dev/null || echo "No crontab"
    done
    echo ""
    echo "=== System Crons ==="
    find /etc/cron* -type f -executable 2>/dev/null | xargs ls -la 2>/dev/null || true
    find /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.monthly /etc/cron.weekly -type f 2>/dev/null | xargs ls -la 2>/dev/null || true
) | log_section "6. Cron Jobs"
for user in $(cut -d: -f1 /etc/passwd); do
    crontab -u "$user" -l > "$EVIDENCE_DIR/crontab-$user" 2>/dev/null || :
done
find /etc/cron* -type f 2>/dev/null | while read -r f; do collect_evidence "$f"; done

# 7. Sudo Privileges
(
    sudo visudo -c 2>&1 || true
    find /etc/sudoers.d -type f 2>/dev/null | sort | while read -r f; do
        echo "=== $f ==="
        cat "$f" 2>/dev/null || true
    done
    grep -v '^#' /etc/sudoers 2>/dev/null | grep -v '^$' || true
) | log_section "7. Sudo Privileges"
find /etc/sudoers.d /etc/sudoers -type f 2>/dev/null | while read -r f; do collect_evidence "$f"; done

# 8. Outbound Connections
(
    ss -tunap 2>/dev/null || netstat -tunap 2>/dev/null || echo "Neither ss nor netstat available"
) | log_section "8. Active Connections (Outbound/Established)"

# 9. World-Writable Files and Directories
(
    echo "=== World-Writable Directories ==="
    # find / -xdev -writable -type d 2>/dev/null | head -50
    find / -xdev -type d -perm -0002 2>/dev/null | head -50
    echo ""
    echo "=== World-Writable Files ==="
    find / -xdev -writable -type f 2>/dev/null | head -50
) | log_section "9. World-Writable Files/Directories"

# 10. Suspicious Permissions (SUID/SGID/777)
(
    echo "=== SUID/SGID Binaries ==="
    find / -xdev \( -perm -4000 -o -perm -2000 \) 2>/dev/null | head -50
    echo ""
    echo "=== Mode 777 ==="
    find / -xdev -perm 777 2>/dev/null | head -50
) | log_section "10. Suspicious Permissions"

# 11. Login History
(
    last -F 2>/dev/null | head -30 || true
    echo ""
    w 2>/dev/null || true
    echo ""
    who 2>/dev/null || true
) | log_section "11. Login History"
for logfile in /var/log/wtmp /var/log/btmp /var/log/auth.log /var/log/secure; do
    collect_evidence "$logfile"
done

# 12. Running Processes
(
    ps auxww | head -100
) | log_section "12. Running Processes"

# 13. Mounted Filesystems
(
    mount | column -t
    echo ""
    df -h
) | log_section "13. Mounted Filesystems"

# 14. Kernel Modules
(
    lsmod 2>/dev/null || echo "lsmod not available"
) | log_section "14. Loaded Kernel Modules"

# Footer
echo '</body></html>' >> "$HTML_FILE"

# Create evidence pack
tar -czf "$OUTPUT_DIR/evidence.tar.gz" -C "$EVIDENCE_DIR" .

# Symlink to current dir for convenience
ln -sf "$OUTPUT_DIR/baseline-report.html" ./baseline-report.html
ln -sf "$OUTPUT_DIR/baseline-report.txt" ./baseline-report.txt
ln -sf "$OUTPUT_DIR/evidence.tar.gz" ./evidence.tar.gz

echo "Report generated:"
echo "  HTML: $HTML_FILE"
echo "  TXT:  $TXT_FILE"
echo "  Evidence: $OUTPUT_DIR/evidence.tar.gz"
echo "Symlinks created in current directory."
