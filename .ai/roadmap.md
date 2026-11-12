# bashman Technical Roadmap & Milestone Plan

## Milestone 1: Core Scaffolding & Toolchain Diagnostics
- [x] **M1.1: Project Structure & Test Harness**
  - Establish `bin/`, `lib/`, `tests/` directories.
  - Set up a lightweight, deterministic bash test runner (POSIX compliant, zero-external-dependency test assertions).
- [x] **M1.2: Toolchain Detection (`bashman doctor`)**
  - Implement `$PATH` detector for foundational tools (`curl`, `jq`, `awk`).
  - Implement `$PATH` detector for accelerated tools (`xh`, `sd`, `bat`).
  - Output clean diagnostic table reporting active engine tier (Foundational vs. Accelerated).

## Milestone 2: Environment Loader & Literal Variable Interpolation
- [x] **M2.1: Cascading `.env` Loader**
  - Safely source `.env` (base) followed by `.env.<name>` without leaking variables to host parent shell.
  - Handle missing files, blank lines, and comments cleanly.
- [x] **M2.2: Safe Literal Token Substitutor**
  - Detect `{{VARIABLE}}` patterns.
  - Implement fallback `awk` literal substitution engine (immune to `/`, `&`, `\`, `$`).
  - Implement accelerated `sd` substitution engine when present.
  - Fail gracefully with clear error when required variable is unbound.

## Milestone 3: Single-Request `.http` Parser
- [x] **M3.1: Request Line & Header Parsing**
  - Extract Method and Target URL from line 1 (default to `GET` if method omitted).
  - Extract key-value headers up to first empty line.
  - Support inline comment lines (`#` or `//`) skipping.
- [x] **M3.2: Request Body Extraction**
  - Stream raw request body following the blank line.
  - Ensure zero corruption of multi-line payloads, JSON indentation, quotes, or trailing newlines.

## Milestone 4: Foundational Dispatcher & Presentation Pipeline
- [x] **M4.1: `curl` Network Dispatcher & Dry-Run**
  - Build `curl` command builder passing extracted method, headers, and piped body via `--data-binary @-`.
  - Implement `--dry-run` flag to inspect generated command/payload without network execution.
- [x] **M4.2: Response Metadata Banner & JSON Formatting**
  - Capture HTTP status code and total execution time via `curl -w`.
  - Format status badge and latency indicator.
  - Pipe response through `jq .` with graceful degradation to raw stdout if non-JSON or `jq` errors.

## Milestone 5: Accelerated Dispatcher & Terminal UI
- [x] **M5.1: `xh` Integration**
  - Route execution through `xh` when available.
  - Preserve identical execution semantics with native `xh` speed.
- [x] **M5.2: `bat` Highlighting & Paging**
  - Pipe JSON response through `bat` with syntax coloring and optional paging.

## Milestone 6: Release Packaging & End-to-End Validation
- [x] **M6.1: Comprehensive Test Suite & Edge Case Verification**
  - Verify error handling: invalid URLs, connection timeouts, missing files, malformed `.http`.
- [x] **M6.2: Version Tagging & Documentation**
  - Install script / symlink setup instructions.
  - SemVer release `0.1.0`.
