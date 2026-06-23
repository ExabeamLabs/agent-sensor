# Usage — agent-sensor

`agent-sensor` is an endpoint collector for Agent Behavior Analytics. It captures events from AI CLI tools (Claude Code, Codex, Gemini CLI, OpenClaw) and forwards them — normalized to Exabeam CIM — to a local JSONL audit log and/or a SIEM webhook.

---

## Synopsis

```
agent-sensor [OPTIONS] [SUBCOMMAND]
```

Running `agent-sensor` without a subcommand is equivalent to `agent-sensor run`.

---

## Global Options

| Flag | Default | Description |
|------|---------|-------------|
| `-c, --config <PATH>` | `~/.agent-sensor/config.toml` | Path to config file |
| `--log-level <LEVEL>` | `info` | Log verbosity: `error`, `warn`, `info`, `debug`, `trace` |
| `--hook-port <PORT>` | `0` (OS-assigned) | Port for the hook server. All three CLI paths (`/claude`, `/codex`, `/gemini`) are served on this port. Use `4982` for a stable well-known port. |
| `--port-range <MIN-MAX>` | _(none)_ | Constrain all hook port binds to this range, e.g. `10000-11000`. Ephemeral ports outside the range exit with code 3; explicit ports outside the range exit with code 78. |
| `--auto-config` | — | Install hooks for Claude Code, Codex CLI, and Gemini CLI, and write a default `config.toml` (never overwrites an existing one). |
| `--dry-run` | — | Preview changes for `--auto-config` or `--enable-local-encryption` without modifying any files. |
| `--enable-local-encryption` | — | Encrypt JSONL and SQLite files at rest. Requires `AGENT_SENSOR_KEY` env var. |
| `--project-dir <PATH>` | `~/.agent-sensor` | Project directory for registry lookup (useful when running multiple instances). |

> **Security note:** Never pass bearer tokens as CLI flags — they appear in `ps aux`.
> Use `--token-file <path>` or the `AGENT_SENSOR_WEBHOOK_TOKEN` env var instead.

---

## Subcommands

### `run` _(default)_

Start the forwarder. Listens for hooks from AI CLIs and tails Claude Code transcripts. Runs until terminated (SIGINT / SIGTERM on macOS; Ctrl+C on Windows). SIGHUP triggers a clean in-place restart.

```sh
agent-sensor run
agent-sensor --hook-port 4982 run
```

On startup, the bound port is printed in a machine-readable line:

```
hook-port: 4982 (paths: /claude /codex /gemini)
```

---

### `version`

Print the binary version and exit.

```sh
agent-sensor version
```

---

### `check-config [PATH]`

Validate a config file. Exits `0` if valid, `78` if malformed or missing.

```sh
agent-sensor check-config
agent-sensor check-config /path/to/custom-config.toml
```

---

### `inspect-cursors`

Dump the current source read cursor state as JSON. Useful for debugging missed or duplicated events.

```sh
agent-sensor inspect-cursors
```

---

### `install-service`

Install `agent-sensor` as a background service.

- **macOS**: launchd plist (requires `sudo`)
- **Windows**: Windows Service (requires administrator) or scheduled task (no elevation)

```sh
# macOS / Linux
sudo agent-sensor install-service --hook-port 4982

# Windows — scheduled task (no admin required)
agent-sensor install-service --use-scheduled-task --hook-port 4982
```

| Flag | Description |
|------|-------------|
| `--use-scheduled-task` | Install as a Windows ONLOGON scheduled task instead of a Windows Service. Ignored on macOS. |
| `--hook-port <PORT>` | Port to embed in the service manifest. |
| `--port-range <MIN-MAX>` | Port range constraint to embed in the service manifest. |
| `--project-dir <PATH>` | Sets `AGENT_SENSOR_PROJECT_DIR` in the service environment. |

---

### `uninstall-service`

Remove the background service installed by `install-service`.

```sh
sudo agent-sensor uninstall-service   # macOS
agent-sensor uninstall-service        # Windows
```

---

### `status`

Print whether the background service is running, stopped, or not installed.

```sh
agent-sensor status
```

---

### `metrics`

Fetch and print current forwarder metrics in Prometheus text format. The forwarder must be running.

```sh
agent-sensor metrics

# When multiple forwarders are running, scope to a specific project directory:
agent-sensor metrics --project-dir /path/to/project
```

---

### `replay-dlq`

Re-inject events from the dead-letter queue (`~/.agent-sensor/dlq.jsonl`) through their original sink. Use this to recover events that failed to deliver (e.g. webhook was temporarily unreachable).

```sh
# Replay all DLQ events
agent-sensor replay-dlq

# Preview without sending
agent-sensor replay-dlq --dry-run

# Replay only events for a specific sink
agent-sensor replay-dlq --sink my-webhook
```

| Flag | Description |
|------|-------------|
| `--sink <NAME>` | Only replay entries for this sink name. Omit to replay all. |
| `--dry-run` | List what would be replayed without sending. |

---

### `detect-sources`

Print available and all known source slugs as JSON. Used by the installer wizard.

```sh
agent-sensor detect-sources
```

---

### `update`

Check for or apply a pending update (requires `[update] enabled = true` in config).

```sh
agent-sensor update            # Check and apply
agent-sensor update --check    # Poll GitHub for a new release, update state file, exit (does not apply)
agent-sensor update --rollback # Restore the previous binary from .prev
```

---

## Common Workflows

### First-time setup

```sh
# Install hooks for all supported CLIs and write default config
agent-sensor --auto-config

# Start the forwarder on port 4982
agent-sensor --hook-port 4982
```

### Preview hook installation without applying

```sh
agent-sensor --auto-config --dry-run
```

### Forward events to Exabeam

Edit `~/.agent-sensor/config.toml`:

```toml
[[sinks]]
kind = "webhook"
url = "https://your-exabeam-collector.example.com/agent-sensor"
token_file = "~/.agent-sensor/webhook.token"
```

Save the webhook bearer token:

```sh
echo -n "YOUR_TOKEN" > ~/.agent-sensor/webhook.token
chmod 600 ~/.agent-sensor/webhook.token
```

Restart the forwarder for the new config to take effect.

### Validate config before restarting

```sh
agent-sensor check-config && sudo launchctl kickstart -k system/com.exabeam.agent-sensor
```

### Inspect captured events

```sh
# Raw JSONL
cat ~/.agent-sensor/events.jsonl

# Filter by source
jq 'select(.framework=="claude_code")' ~/.agent-sensor/events.jsonl

# Session starts only
jq 'select(.event_type=="session_start") | {ts, session_id, framework}' ~/.agent-sensor/events.jsonl
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Runtime error |
| `3` | Hook port unavailable (bind failed or outside `--port-range`) |
| `78` | Configuration error (malformed config or port outside explicit range) |

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `RUST_LOG` | Log filter, e.g. `RUST_LOG=debug` |
| `AGENT_SENSOR_KEY` | Encryption key for `--enable-local-encryption` |
| `AGENT_SENSOR_WEBHOOK_TOKEN` | Bearer token for webhook sink (alternative to `token_file` in config) |
| `AGENT_SENSOR_PROJECT_DIR` | Project directory (same as `--project-dir` flag) |
