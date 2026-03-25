`snapshot.sh`

Create a complete, production-ready Bash script for the "Linux Baseline" baseline security snapshot tool. 

Key requirements:

- **Single command runnable script** (e.g., via curl | bash).
- **Run as root** for full access; check and warn if not.
- **Captures ALL listed items precisely**:
  1. Current users and UID mapping (/etc/passwd, groups).
  2. SSH configuration state (/etc/ssh/sshd_config key settings).
  3. Authorized keys per user (~user/.ssh/authorized_keys).
  4. Open ports and listening services (ss -tulnp fallback to netstat).
  5. Cron jobs (user crontabs, /etc/cron.*).
  6. Sudo privileges (/etc/sudoers, /etc/sudoers.d/*).
  7. Outbound connections (ss -tunap for active/established).
  8. World-writable files (find / -writable).
  9. Suspicious file permissions (SUID/SGID, 777, etc.).
  10. Login history (last, w, who).
  11. Running processes (ps aux).
- **Bonus relevant items** for completeness: system info, mounts, kernel modules, logs.
- **Outputs**:
  - **Clean HTML view**: Styled, sectioned, monospace pre blocks, timestamped, hostnamed.
  - **Raw TXT output**: Sectioned with === headers.
  - **Evidence pack**: Copy raw files (configs, keys, logs, crontabs) into evidence/ dir, tar.gz it.
- **Safe & Efficient**: Limit find outputs (head -50), handle non-root gracefully, no overwrites, timestamped dir.
- **Professional**: Clean code, error handling (set -euo pipefail), column formatting, visudo check.
- **Self-contained**: No external deps beyond standard Linux utils (ss/netstat/ps/find etc.).

Test mentally for Ubuntu/CentOS/RHEL. Make HTML pretty but readable. End with usage summary printing paths/symlinks.

<br>
