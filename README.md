# aba-sensor

**Endpoint Collector for Agent Behavior Analytics (ABA)** — unified event capture from AI CLI tools running on enterprise endpoints.

```
Claude Code ─┐
Codex CLI ───├─→ aba-sensor ─→ Exabeam SecOps platform
Gemini CLI ──┤
OpenClaw ────┘
```

Captures session lifecycle, user prompts, tool invocations, token usage, and agent costs — all normalized to Exabeam CIM for SIEM threat detection and investigation.

Binaries are published as [GitHub Releases](https://github.com/ExabeamLabs/aba-sensor-dist/releases) — no build toolchain required to install.

---

## Supported Platforms

| Platform | Architecture |
|----------|-------------|
| macOS | x86_64 (Intel) |
| macOS | aarch64 (Apple Silicon) |
| Windows | x86_64 |

---

## Quick Install

### macOS (Apple Silicon)

```sh
VERSION=1.0.0
curl -fsSL https://github.com/ExabeamLabs/aba-sensor-dist/releases/download/v${VERSION}/aba-sensor-v${VERSION}-aarch64-apple-darwin \
  -o /usr/local/bin/aba-sensor
chmod +x /usr/local/bin/aba-sensor
```

### macOS (Intel)

```sh
VERSION=1.0.0
curl -fsSL https://github.com/ExabeamLabs/aba-sensor-dist/releases/download/v${VERSION}/aba-sensor-v${VERSION}-x86_64-apple-darwin \
  -o /usr/local/bin/aba-sensor
chmod +x /usr/local/bin/aba-sensor
```

### Windows (x86_64)

Download `aba-sensor-v{VERSION}-x86_64-pc-windows-msvc.exe` from the [Releases page](https://github.com/ExabeamLabs/aba-sensor-dist/releases) and add it to your `PATH`.

---

## Documentation

- [Installation](docs/installation.md)
- [Usage](docs/usage.md)
- [Changelog](docs/changelog.md)
