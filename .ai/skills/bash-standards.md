# Bash Engineering & Safety Standards

## 1. Execution Directives
- Every script must begin with:
  ```bash
  #!/usr/bin/env bash
  set -eou pipefail
  ```
- No scripts may assume Bash 5+ features unless strictly guarded; target Bash 3.2+ / POSIX compatibility for universal macOS and Windows Git Bash support.

## 2. Variable & Parameter Quoting
- Double-quote every variable expansion: `"${var}"` (never `$var`).
- Array expansions must strictly use `"${array[@]}"`.
- Default values must use safe parameter expansion: `"${1:-default}"`.

## 3. Safe Script Portability
- Never use hardcoded absolute paths to binaries (e.g. `/usr/bin/curl`); rely on `command -v <binary>` or resolved helper lookups.
- Avoid platform-specific `sed` flags (e.g., `sed -i ''` on macOS vs `sed -i` on Linux). When modifying text, use streaming `awk` or write to a deterministic temporary file.
- Handle CRLF line endings cleanly: `.http` and `.env` files written on Windows may have `\r\n`. Strip `\r` before parsing tokens.

## 4. Exit Codes & Error Handling
- Exit `0`: Success.
- Exit `1`: General runtime error (e.g., missing file, network error).
- Exit `2`: CLI usage / syntax error.
- Exit `127`: Missing required foundational binary.
- All error messages must be printed to `stderr` with a unified prefix: `[bashman] error: ...`.
