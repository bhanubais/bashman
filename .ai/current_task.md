# Current Task: Milestone 3 - Single-Request .http Parser (Step A Verified + IDE Lints Cleared)

## Objective
Implement strict RFC single-request `.http` parser capable of splitting:
1. Method & Request URL (defaulting to GET if method omitted).
2. Header block up to first empty line (skipping `#` and `//` comments).
3. Raw multiline body stream with indentation and character preservation.
4. Windows CRLF sanitization.

## IDE Inspection Remediation Completed
- `bin/bashman`: Staged variables `ENV_NAME` and `DRY_RUN` annotated with `# shellcheck disable=SC2034` (scheduled for consumption in Milestone 4 request dispatcher).
- `tests/test_harness.bash`: Utilized `BOLD` format token in test result summary banner.
- `tests/test_env_and_interpolator.sh`: Added `# shellcheck source=../lib/interpolator.sh` directive.
- `tests/test_http_parser.sh`: Added `# shellcheck source=../lib/http_parser.sh` directive.
- `lib/doctor.sh`: Refactored to structured ANSI escape constants and `%b` format specifiers.

## Step A (Red Phase) Status
- Suite: [`tests/test_http_parser.sh`](file:///E:/Project/bashman/tests/test_http_parser.sh)
- Verified RED: Fails on missing `lib/http_parser.sh`.

## Awaiting Confirmation
Waiting for user confirmation to proceed to Step B (Implementation).
