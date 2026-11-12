# Current Task: Milestone 4 - Foundational Dispatcher & Presentation Pipeline (Step A Verified)

## Objective
Implement request execution via foundational `curl` and presentation pipeline:
1. `bin/bashman run --dry-run <file.http>`: Parse request, interpolate environment, and format request preview without network execution.
2. `lib/dispatcher.sh`:
   - `dispatch_curl`: Construct curl arguments (`-X`, `-H`, `--data-binary @-`, `-w "\n__BASHMAN_META__:%{http_code}:%{time_total}s\n"`).
   - `parse_curl_output`: Delimit HTTP status, total time, and response body.
   - `format_status_badge`: ANSI color-coded status badges (`[200 OK]`, `[404 Not Found]`, `[500 Server Error]`).
   - `format_response_body`: Pipe formatted JSON through `jq .` with raw fallback.

## Step A (Red Phase) Status
- Suite: [`tests/test_dispatcher_and_dryrun.sh`](file:///E:/Project/bashman/tests/test_dispatcher_and_dryrun.sh)
- Verified RED: Fails on missing `lib/dispatcher.sh`.

## Awaiting Confirmation
Waiting for user confirmation to proceed to Step B (Implementation).
