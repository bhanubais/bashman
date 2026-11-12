# bashman

> **Ultra-fast, dependency-light CLI utility for API testing and network request orchestration.**  
> Native execution speed. Zero Electron bloat. 100% Git-friendly plain text.

---

## ⚡ The Problem: Why `bashman`?

Standard API clients like Postman have devolved into heavy, cloud-tethered Electron apps:
- **Memory Bloat:** Frequently consumes 1.2+ GB of RAM just sitting idle, starving local IDEs, compilers, and Docker containers.
- **Cloud Lock-In & Vendor Friction:** Mandates cloud accounts, telemetry, and subscriptions just to share simple requests with your team.
- **Cumbersome Raw `curl`:** While raw `curl` + `jq` scripts are lightweight, they lack environment management, have tedious escaping issues, and lack visual clarity.

**`bashman` bridges this gap.** It combines the ergonomics of modern API clients with the raw speed and scriptability of the command line. Using standard single-request `.http` files and cascading `.env` configs, your API definitions stay in Git right alongside your application code.

```
Postman (Electron GUI)      raw curl + jq                 bashman
----------------------      -------------                 -------
❌ ~1.2 GB idle RAM         ✅ Minimal RAM                ✅ < 10 MB RAM
❌ Cloud accounts & sync    ✅ Local files                ✅ Local files & Git-native
❌ Heavy GUI latency        ❌ Tedious syntax & escaping  ✅ Instant Rust/Bash pipeline
❌ Proprietary export/sync  ❌ Manual env management      ✅ Cascading .env & {{VARS}}
```

---

## 🏛️ Architecture & Hybrid Engine

`bashman` is architected as a lightweight, safe Bash orchestration layer that utilizes a **Two-Tier Hybrid Engine** with automatic, graceful degradation:

```
                  ┌───────────────────────────────┐
                  │   bashman CLI Orchestrator    │
                  │   (Single-Request .http + .env)│
                  └──────────────┬────────────────┘
                                 │
                 ┌───────────────┴───────────────┐
                 ▼                               ▼
       Tier 1: Accelerated              Tier 2: Foundational
       (Modern Rust Tools)               (POSIX / GNU Base)
     ────────────────────────          ───────────────────────
     Transport:    xh                  Transport:    curl
     Template:     sd                  Template:     awk
     Presentation: bat                 Presentation: jq / raw
```

- **Tier 1 (Accelerated Engine):** When modern compiled Rust binaries (`xh`, `sd`, `bat`) are installed on your `$PATH`, `bashman` automatically leverages them for sub-millisecond execution, safe literal templating, and syntax-highlighted terminal output.
- **Tier 2 (Foundational Engine):** If Rust tools are absent, `bashman` seamlessly degrades to standard POSIX/GNU primitives (`curl`, `awk`, `jq`). It runs anywhere without mandatory external installations—including CI/CD runners, minimal containers, and Windows Git Bash.
- **Deterministic & Safe:** Built strictly with `set -eou pipefail`. Literal string substitution prevents regex injection and escaping corruption when values contain `/`, `&`, `\`, or `$`.
- **Stateless:** No background daemons, no background agents, and no hidden SQLite databases. The filesystem is the single source of truth.

---

## 📦 Prerequisites & Toolchain

### Foundational (Required)
The following utilities are standard across Linux, macOS, and Git Bash:
- `bash` (v3.2+)
- `curl`
- `awk`
- `jq`

### Accelerated Tier (Recommended)
For enhanced speed, literal regex-safe templating, and colored terminal output:
- [`xh`](https://github.com/ducaale/xh) – Native, fast HTTP tool
- [`sd`](https://github.com/chmln/sd) – Intuitive, fast search & replace
- [`bat`](https://github.com/sharkdp/bat) – Syntax-highlighting cat clone

#### Installation of Accelerated Tools:

- **macOS (Homebrew):**
  ```bash
  brew install xh sd bat jq
  ```

- **Arch Linux:**
  ```bash
  pacman -S xh sd bat jq
  ```

- **Ubuntu / Debian:**
  ```bash
  apt install jq bat
  cargo install xh sd
  ```

- **Cargo (Any OS with Rust):**
  ```bash
  cargo install xh sd bat
  ```

---

## 🚀 Installation

Clone the repository and add the `bin/` directory to your `$PATH`:

```bash
git clone https://github.com/your-username/bashman.git
cd bashman

# Symlink to your user binary path (e.g., ~/.local/bin or /usr/local/bin)
ln -s "$(pwd)/bin/bashman" ~/.local/bin/bashman
```

Verify your installation and inspect toolchain capabilities:
```bash
bashman doctor
```

Output:
```text
bashman Toolchain Diagnostics
============================

[Foundational Engine - Portable Base]
  ✓ curl     [/usr/bin/curl]
  ✓ jq       [/usr/bin/jq]
  ✓ awk      [/usr/bin/awk]

[Accelerated Engine - Modern Rust Tools]
  ✓ xh       [/usr/local/bin/xh]
  ✓ sd       [/usr/local/bin/sd]
  ✓ bat      [/usr/local/bin/bat]

Engine Status:
  Tier 1 (Maximum Acceleration): xh + sd + bat active.
```

---

## 📖 Quick Start

### 1. Create a `.http` Request File
Store your requests as standard RFC-compliant `.http` files:

```http
# requests/login.http
POST https://api.example.com/v1/auth/login
Content-Type: application/json
Authorization: Bearer {{API_TOKEN}}

{
  "username": "{{USERNAME}}",
  "password": "{{PASSWORD}}"
}
```

### 2. Configure Environment Variables
Define base variables in `.env` and environment-specific overrides in `.env.<name>`:

```ini
# .env
API_TOKEN=dev-secret-token
USERNAME=developer

# .env.staging
API_TOKEN=staging-vault-token
USERNAME=staging-user
```

### 3. Execute Requests

- **Standard Execution:**
  ```bash
  bashman run requests/login.http
  ```

- **With Cascading Environment:**
  ```bash
  bashman run --env staging requests/login.http
  ```

- **Dry-Run (Inspect without dispatching network calls):**
  ```bash
  bashman run --dry-run --env staging requests/login.http
  ```

---

## 📋 `.http` Specification

`bashman` strictly supports deterministic, single-request `.http` files:

```http
[METHOD] [URL] [HTTP_VERSION?]
[Header-Name]: [Header-Value]
...

[Optional Request Body]
```

- **Line 1:** HTTP Method followed by the Target URL (defaults to `GET` if the method is omitted).
- **Headers:** Key-value pairs (`Key: Value`) immediately following line 1 until the first empty line. Comment lines starting with `#` or `//` are safely ignored.
- **Body:** Multi-line payload (JSON, XML, GraphQL, plain text) following the blank separator line. Zero whitespace or quote mangling.

### Variable Cascading Hierarchy
Variables formatted as `{{VARIABLE_NAME}}` are resolved with the following precedence:
1. Active host shell environment (`$VARIABLE_NAME`)
2. Target environment file (`.env.<name>`, if `--env <name>` is passed)
3. Base environment file (`.env`)

---

## 🛠️ CLI Reference

```text
Usage:
  bashman [command] [options] <arguments>

Commands:
  run <file.http>      Execute the single-request .http file
  doctor               Inspect toolchain dependencies and report engine tier

Options:
  --env <name>         Load cascading environment (.env.<name>)
  --dry-run            Parse and display the prepared request without dispatching
  -h, --help           Show help manual
  -v, --version        Show current version
```

### Exit Codes
- `0`: Success
- `1`: Runtime failure (missing file, network unreachable)
- `2`: CLI usage / syntax error
- `127`: Missing foundational dependencies (`curl`, `awk`, or `jq`)

---

## 🧪 Testing & Development

`bashman` adheres to strict Test-Driven Development (TDD) using a lightweight, deterministic POSIX bash test harness.

To run the full test suite:
```bash
./tests/run_tests.sh
```

---

## 🗺️ Project Roadmap

- [x] **Milestone 1:** Core Scaffolding, CLI Router & Toolchain Diagnostics (`bashman doctor`)
- [x] **Milestone 2:** Cascading Environment Loader & Safe Literal Substitution (`sd` / `awk`)
- [x] **Milestone 3:** Deterministic Single-Request `.http` Parser
- [x] **Milestone 4:** Foundational `curl` Dispatcher, Metadata Banners & `jq` Output
- [x] **Milestone 5:** Accelerated `xh` Transport & `bat` Syntax Highlighting
- [x] **Milestone 6:** Release Packaging & Cross-Platform Validation

Detailed architecture records and design decisions are documented in the [`.ai/`](./.ai/) directory.

---

## 📄 License

MIT © 2026
