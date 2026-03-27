# Linux Baseline 🐧 

A single Bash script that captures a complete security baseline snapshot of any Linux system — no dependencies, no setup, just run it.

## What Goes Unnoticed Until It's Too Late

When something goes wrong on a Linux server, the first question is always: *what changed?* But without a baseline, you're comparing against nothing. Rogue users, unexpected open ports, modified SSH configs, suspicious SUID binaries, unauthorized cron jobs — these are easy to miss without a point-in-time record of the system's state.

## Freeze the System State in One Command

`snapshot.sh` captures everything security-relevant about a Linux host and writes it to a timestamped directory. You get a styled HTML report you can open in a browser, a plain-text version for scripting and archiving, and a `.tar.gz` evidence pack with copies of the actual config files. Run it before and after any major change — or just before handing a system off — and you'll always have something to diff against.

**What it captures:**

- Users, UIDs, and group memberships
- SSH daemon configuration and per-user authorized keys
- Open ports and listening services (`ss` / `netstat`)
- All cron jobs — user crontabs and `/etc/cron.*`
- Sudo privileges (`/etc/sudoers` and `sudoers.d/`)
- Active outbound connections
- World-writable files and directories
- SUID/SGID binaries and `777`-mode files
- Login history (`last`, `w`, `who`)
- Running processes
- Mounted filesystems and kernel modules

## Example Output

```
linux-baseline-20260325-143012/
├── baseline-report.html     # Styled, sectioned, browser-ready
├── baseline-report.txt      # Plain text with === section headers
└── evidence.tar.gz          # Raw copies of configs, keys, logs
```

Symlinks are also created in the current directory for quick access:

```
./baseline-report.html
./baseline-report.txt
./evidence.tar.gz
```

## Usage

**Run as root** for full access. The script will warn (but continue) if you're not.

```bash
sudo bash snapshot.sh
```

Or pull and run directly:

```bash
curl -fsSL https://raw.githubusercontent.com/tdiprima/linux-baseline/main/snapshot.sh | sudo bash
```

Open the report:

```bash
open baseline-report.html      # macOS
xdg-open baseline-report.html  # Linux - if a desktop environment is installed.
```

**Requirements:** Standard Linux utilities only — `ss` or `netstat`, `ps`, `find`, `last`, `lsmod`. Nothing to install.

<br>
