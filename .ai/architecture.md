# bashman Architecture Decision Record (ADR)

## 1. System Overview
`bashman` is an ultra-fast, dependency-light CLI utility for executing API requests defined in standard single-request `.http` files. It bridges the gap between raw `curl` scripts and bloated GUI/Electron clients like Postman.

## 2. Core Architecture Principles
1. **Stateless Execution:** No background daemons, no local SQLite databases. The filesystem (`.http` and `.env` files) is the single source of truth.
2. **Hybrid Execution Engine (Graceful Degradation):**
   - **Foundational Tier:** Built on POSIX/GNU primitives: `curl`, `jq`, and `awk`. Operates out-of-the-box in minimal environments, CI/CD runners, and Windows Git Bash.
   - **Accelerated Tier:** Dynamically upgrades to compiled Rust utilities when detected on `$PATH`:
     - Network transport: `xh`
     - Template replacement: `sd`
     - Terminal presentation: `bat`
3. **Deterministic Safety:** `set -eou pipefail` enforced across all scripts. Quoting discipline strictly applied to prevent shell injection.

## 3. Component Design

### 3.1 CLI Router & Diagnostics (`bashman`)
- Options:
  - `bashman run <request.http>`: Execute request
  - `bashman run --env <name> <request.http>`: Execute with cascaded environment
  - `bashman doctor`: Inspect `$PATH` and report availability of foundational vs. accelerated binaries
  - `bashman --dry-run <request.http>`: Parse and display prepared request without dispatching
  - `bashman --version` / `bashman --help`

### 3.2 Single-Request `.http` Specification
Only single-request files are supported to maintain strict parser determinism:
```http
POST https://api.example.com/v1/auth/login
Content-Type: application/json
Authorization: Bearer {{API_TOKEN}}

{
  "username": "{{USER_NAME}}",
  "password": "{{USER_PASSWORD}}"
}
```
- Line 1: `[METHOD] [URL] [HTTP_VERSION?]` (Defaults to `GET` if method omitted)
- Lines 2..N: RFC-compliant HTTP headers (`Key: Value`) until the first blank line.
- Remaining lines: Raw request body (JSON, XML, text, GraphQL, etc.).

### 3.3 Cascading Environment Loader & Variable Substitution
- Precedence order:
  1. Base: `.env` (if exists in execution directory)
  2. Target Environment: `.env.<env_name>` (if specified via `--env <env_name>`)
  3. Active shell environment (`$VAR`)
- Variable replacement finds all `{{VARIABLE_NAME}}` tokens.
- **Substitution Engine:**
  - *Accelerated (`sd`):* Uses literal string replacement mode.
  - *Foundational (`awk`):* Uses an exact literal string replacement routine (`index` and `substr`) to prevent tokens containing `/`, `&`, `\`, or `$` from triggering regex corruption or parameter expansion bugs.

### 3.4 Execution & Presentation Pipeline
1. **Request Dispatcher:**
   - **Foundational (`curl`):**
     - Extracts HTTP code and duration via `-w "\n__METADATA__:%{http_code}:%{time_total}s\n"`.
     - Passes headers via `-H` arguments.
     - Streams body via stdin (`--data-binary @-`).
   - **Accelerated (`xh`):**
     - Invokes `xh` with extracted flags, headers, and piped body.
2. **Metadata Banner:**
   - Formats status badge (e.g., `[200 OK]` in green, `[4xx/5xx]` in red) and latency (`[142ms]`).
3. **Response Viewer:**
   - If response is JSON and `bat` is available: pipes through `bat -l json --style=plain`.
   - If response is JSON and `bat` is absent: pipes through `jq .`.
   - Fallback: prints raw response if non-JSON.
