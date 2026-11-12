# Test-Driven Development (TDD) Protocols

## 1. Red-Green-Refactor Lifecycle
1. **Red (Depth First):** Write comprehensive test assertions covering both happy paths and edge cases (empty inputs, missing files, malformed syntax). Run the test harness and verify it fails as expected.
2. **Green (Minimalist Implementation):** Implement only the code required to make the failing assertions pass. Avoid speculative logic or premature optimizations.
3. **Refactor (Clean Code):** Clean up the implementation adhering to `@.ai/skills/bash-standards.md`. Re-run the full test suite to guarantee zero regression.

## 2. Test Harness Requirements
- Must run cleanly with zero external npm/cargo/pip dependencies. A lightweight Bash-based test framework (`test_assert`, `assert_equals`, `assert_exit_code`).
- Output format: TAP-compatible or clear colored output (`PASS: <test_name>`, `FAIL: <test_name>`).
- Tests must be completely isolated and must clean up any temporary directories (`mktemp -d`) via `trap 'rm -rf "$TEST_TMP"' EXIT`.

## 3. Commit Discipline
- Never commit broken tests.
- When a feature passes its test suite, suggest a precise, semantic Git commit message in the format:
  `feat(<scope>): <description>` or `test(<scope>): <description>`.
