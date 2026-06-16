# Installation — aba-sensor

## Prerequisites

- **macOS**: 11.0 (Big Sur) or later
- **Windows**: Windows 10 or 11 (x86_64)
- **Disk**: ~100 MB
- **Network**: Port 4982 (hook server) must be available locally

---

## Download

Download the binary for your platform from the [Releases page](https://github.com/ExabeamLabs/aba-sensor-dist/releases).

| Platform | Binary filename |
|----------|----------------|
| macOS Apple Silicon (M1/M2/M3) | `aba-sensor-v{VERSION}-aarch64-apple-darwin` |
| macOS Intel | `aba-sensor-v{VERSION}-x86_64-apple-darwin` |
| Windows x86_64 | `aba-sensor-v{VERSION}-x86_64-pc-windows-gnu.exe` |

---

## macOS

### Install via curl (recommended)

Replace `VERSION` with the release you want (e.g. `1.0.4`).

**Apple Silicon (M1/M2/M3):**

```sh
VERSION=1.0.4
curl -fsSL https://github.com/ExabeamLabs/aba-sensor-dist/releases/download/v${VERSION}/aba-sensor-v${VERSION}-aarch64-apple-darwin \
  -o /usr/local/bin/aba-sensor
chmod +x /usr/local/bin/aba-sensor
```

**Intel:**

```sh
VERSION=1.0.4
curl -fsSL https://github.com/ExabeamLabs/aba-sensor-dist/releases/download/v${VERSION}/aba-sensor-v${VERSION}-x86_64-apple-darwin \
  -o /usr/local/bin/aba-sensor
chmod +x /usr/local/bin/aba-sensor
```

### Verify the download

Always confirm the download is a real binary and not a saved error page:

```sh
file /usr/local/bin/aba-sensor
# Expected: Mach-O 64-bit executable arm64   (Apple Silicon)
# Expected: Mach-O 64-bit executable x86_64  (Intel)
# If you see "ASCII text" — the download failed; retry the curl command.

aba-sensor --version
```

### Gatekeeper (macOS security)

On first run macOS may block the binary with "cannot be opened because the developer cannot be verified." To allow it:

```sh
xattr -d com.apple.quarantine /usr/local/bin/aba-sensor
```

Or: **System Settings → Privacy & Security → Allow Anyway**.

---

## Windows

1. Download `aba-sensor-v{VERSION}-x86_64-pc-windows-gnu.exe` from the [Releases page](https://github.com/ExabeamLabs/aba-sensor-dist/releases).
2. Rename it to `aba-sensor.exe`.
3. Move it to a directory on your `PATH` (e.g. `C:\Program Files\aba-sensor\`).

Verify in PowerShell:

```powershell
aba-sensor --version
```

### Windows service (no admin required)

```powershell
aba-sensor install-service --use-scheduled-task --hook-port 4982
```

This registers an ONLOGON scheduled task — no administrator privileges needed.

---

## Quick Start

```sh
# 1. Install hooks for Claude Code, Codex CLI, and Gemini CLI + write default config
aba-sensor --auto-config

# 2. Start the forwarder (listens on port 4982 by default)
aba-sensor --hook-port 4982

# 3. After a Claude Code session, inspect the JSONL audit log
cat ~/.aba-sensor/events.jsonl
```

Preview what `--auto-config` would change before applying:

```sh
aba-sensor --auto-config --dry-run
```

---

## Configuration

The default config file is `~/.aba-sensor/config.toml`. It is created automatically by `--auto-config` if it does not already exist. Example:

```toml
[sources]

[[sinks]]
kind = "jsonl"
path = "/Users/YOU/.aba-sensor/events.jsonl"
rotation_size_mb = 100
max_rotated_files = 5

# Uncomment to forward events to Exabeam or another SIEM:
# [[sinks]]
# kind = "webhook"
# url = "https://your-collector.example.com/aba-sensor"
# token_file = "~/.aba-sensor/webhook.token"
```

The file is never overwritten by subsequent `--auto-config` runs — edit it freely.

**Environment variables:**

| Variable | Purpose |
|----------|---------|
| `RUST_LOG=aba_sensor=info` | Log level (`error`, `warn`, `info`, `debug`, `trace`) |
| `ABA_SENSOR_KEY` | Encryption key (required when `--enable-local-encryption` is set) |
| `ABA_SENSOR_WEBHOOK_TOKEN` | Bearer token for webhook sink (alternative to `token_file`) |

---

## Install as a Background Service

### macOS (launchd)

```sh
sudo aba-sensor install-service --hook-port 4982

# Verify
sudo launchctl list | grep aba-sensor
```

### Windows (scheduled task — no admin)

```powershell
aba-sensor install-service --use-scheduled-task --hook-port 4982
```

---

## Verify Installation

```sh
# Check version
aba-sensor --version

# Check service status
aba-sensor status

# Send a test event to the hook server
curl -X POST http://127.0.0.1:4982/claude \
  -H "Content-Type: application/json" \
  -d '{"hook":"SessionStart","sessionId":"test"}'

# Count events captured
wc -l ~/.aba-sensor/events.jsonl
```

---

## Upgrading

Repeat the download and install steps with the new version. The new binary replaces the old one at the same path. If running as a service, restart it after replacing the binary:

```sh
# macOS
sudo launchctl stop com.exabeam.aba-sensor
sudo launchctl start com.exabeam.aba-sensor
```

---

## Uninstall

### macOS

```sh
sudo aba-sensor uninstall-service        # Remove launchd service (if installed)
sudo rm /usr/local/bin/aba-sensor        # Remove binary
rm -rf ~/.aba-sensor/                    # Remove config and logs (optional)
```

To also remove the CLI hook registrations:

```sh
rm -f ~/.claude/hooks/claude-watch-hook.sh
rm -f ~/.codex/hooks/codex-hook.sh
rm -f ~/.gemini/hooks/gemini-hook.sh
```

### Windows

```powershell
aba-sensor uninstall-service             # Remove scheduled task (if installed)
# Then delete aba-sensor.exe from your PATH directory
```

---

## Troubleshooting

### `Not: command not found` when running the binary

The file is an HTML/text error page, not a real binary (typically from a failed download).

```sh
file ./aba-sensor
# Real binary:    "Mach-O 64-bit executable"
# Saved error page: "ASCII text" or "HTML document text"
```

Fix: delete the file and re-download.

### Port already in use

```
Error: Address already in use (os error 48)
```

```sh
lsof -i :4982          # Find what is using the port
aba-sensor --hook-port 4992   # Or use a different port
```

### No events appearing

1. Verify the forwarder is running: `lsof -i :4982`
2. Check hooks are installed: `cat ~/.claude/settings.json | grep claude-watch-hook`
3. Send a test event manually (see [Verify Installation](#verify-installation) above)

### macOS Gatekeeper blocks the binary

See the [Gatekeeper](#gatekeeper-macos-security) section above.
