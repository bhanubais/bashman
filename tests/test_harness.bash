#!/usr/bin/env bash
# bashman test assertion library
set -eou pipefail

TEST_COUNT=0
TEST_PASSED=0
TEST_FAILED=0

BOLD="\033[1m"
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

assert_eq() {
  local expected="$1"
  local actual="$2"
  local msg="$3"
  TEST_COUNT=$((TEST_COUNT + 1))

  if [[ "$expected" == "$actual" ]]; then
    TEST_PASSED=$((TEST_PASSED + 1))
    printf "  ${GREEN}✓${RESET} %s\n" "$msg"
  else
    TEST_FAILED=$((TEST_FAILED + 1))
    printf "  ${RED}✗${RESET} %s\n" "$msg"
    printf "    Expected: '%s'\n" "$expected"
    printf "    Actual:   '%s'\n" "$actual"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="$3"
  TEST_COUNT=$((TEST_COUNT + 1))

  if [[ "$haystack" == *"$needle"* ]]; then
    TEST_PASSED=$((TEST_PASSED + 1))
    printf "  ${GREEN}✓${RESET} %s\n" "$msg"
  else
    TEST_FAILED=$((TEST_FAILED + 1))
    printf "  ${RED}✗${RESET} %s\n" "$msg"
    printf "    Expected to contain: '%s'\n" "$needle"
    printf "    Received:            '%s'\n" "$haystack"
  fi
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local msg="$3"
  TEST_COUNT=$((TEST_COUNT + 1))

  if [[ "$expected" -eq "$actual" ]]; then
    TEST_PASSED=$((TEST_PASSED + 1))
    printf "  ${GREEN}✓${RESET} %s\n" "$msg"
  else
    TEST_FAILED=$((TEST_FAILED + 1))
    printf "  ${RED}✗${RESET} %s\n" "$msg"
    printf "    Expected exit code: %d\n" "$expected"
    printf "    Actual exit code:   %d\n" "$actual"
  fi
}

report_results() {
  printf "\n%bTest Summary:%b %d total, %d passed, %d failed\n" "$BOLD" "$RESET" "$TEST_COUNT" "$TEST_PASSED" "$TEST_FAILED"
  if [[ "$TEST_FAILED" -gt 0 ]]; then
    return 1
  fi
  return 0
}
