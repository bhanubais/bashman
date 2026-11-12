#!/usr/bin/env bash
# Test Suite: CLI Routing, Options & Doctor Command
set -eou pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$DIR/.." && pwd)"
BASHMAN="$PROJECT_ROOT/bin/bashman"

source "$DIR/test_harness.bash"

printf "\n=== Running CLI & Doctor Test Suite ===\n\n"

# Test 1: --help displays usage and returns 0
output=$("$BASHMAN" --help 2>&1 || true)
assert_contains "$output" "Usage:" "CLI --help displays usage"
assert_contains "$output" "doctor" "CLI --help lists doctor command"
assert_contains "$output" "run" "CLI --help lists run command"

# Test 2: --version displays SemVer 0.1.0 and returns 0
output=$("$BASHMAN" --version 2>&1 || true)
assert_contains "$output" "0.1.0" "CLI --version reports version 0.1.0"

# Test 3: doctor runs diagnostic check and returns status
output=$("$BASHMAN" doctor 2>&1 || true)
assert_contains "$output" "Foundational Engine" "Doctor checks foundational engine"
assert_contains "$output" "curl" "Doctor checks curl"
assert_contains "$output" "jq" "Doctor checks jq"
assert_contains "$output" "awk" "Doctor checks awk"
assert_contains "$output" "Accelerated Engine" "Doctor checks accelerated engine"
assert_contains "$output" "xh" "Doctor checks xh"
assert_contains "$output" "sd" "Doctor checks sd"
assert_contains "$output" "bat" "Doctor checks bat"

# Test 4: Unknown flag/command produces error and exits 2
set +e
output=$("$BASHMAN" --nonexistent 2>&1)
code=$?
set -e
assert_exit_code 2 "$code" "CLI returns exit code 2 on unknown option"
assert_contains "$output" "Unknown option" "CLI outputs error message on unknown option"

# Test 5: 'run' without file parameter returns error and exits 2
set +e
output=$("$BASHMAN" run 2>&1)
code=$?
set -e
assert_exit_code 2 "$code" "CLI 'run' without file returns exit code 2"
assert_contains "$output" "missing" "CLI 'run' reports missing request file"

report_results
