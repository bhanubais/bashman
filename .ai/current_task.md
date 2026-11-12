# Current Task: Milestone 5 - Accelerated Dispatcher & Terminal UI (Step A Verified)

## Objective
Implement dynamic upgrade to compiled Rust utilities (`xh`, `bat`) when detected on `$PATH`:
1. `can_use_accelerated_engine`: Inspect `$PATH` for `xh`.
2. `dispatch_xh`:
   - Pass headers in `Header:Value` format.
   - Stream raw body payload.
   - Parse status line and time.
3. `format_response_body`: Route through `bat -l json --style=plain` when `bat` is available.
4. `dispatch_request`: Unified router selecting `dispatch_xh` when accelerated, or falling back to `dispatch_curl`.

## Step A (Red Phase) Status
- Suite: [`tests/test_accelerated_engine.sh`](file:///E:/Project/bashman/tests/test_accelerated_engine.sh)
- Verified RED: Fails on missing `can_use_accelerated_engine` and `dispatch_request`.

## Awaiting Confirmation
Waiting for user confirmation to proceed to Step B (Implementation).
