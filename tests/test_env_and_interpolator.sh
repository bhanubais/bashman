#!/usr/bin/env bash
# Test Suite: Environment Loader & Safe Variable Interpolator
set -eou pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$DIR/.." && pwd)"

source "$DIR/test_harness.bash"

# Isolated test sandbox
SANDBOX=$(mktemp -d 2>/dev/null || mktemp -d -t 'bashman-test')
trap 'rm -rf "$SANDBOX"' EXIT

printf "\n=== Running Env Loader & Interpolator Test Suite ===\n\n"

# Setup test .env files
cat <<'EOF' > "$SANDBOX/.env"
BASE_URL=https://api.base.example.com
PORT=8080
SHARED_SECRET=base_secret
SPECIAL_TOKEN=secret/token&val=1$foo"bar
EOF

cat <<'EOF' > "$SANDBOX/.env.staging"
PORT=9090
SHARED_SECRET=staging_override
EOF

# Ensure interpolator module exists
INTERPOLATOR_LIB="$PROJECT_ROOT/lib/interpolator.sh"

if [[ ! -f "$INTERPOLATOR_LIB" ]]; then
  assert_eq "file_exists" "file_missing" "interpolator.sh module exists"
  report_results
  exit 1
fi

# shellcheck source=../lib/interpolator.sh
source "$INTERPOLATOR_LIB"

# Test 1: Load base .env variables
load_environment "$SANDBOX" ""
assert_eq "https://api.base.example.com" "${BASE_URL:-}" "Base environment loads BASE_URL"
assert_eq "8080" "${PORT:-}" "Base environment loads PORT"
assert_eq "base_secret" "${SHARED_SECRET:-}" "Base environment loads SHARED_SECRET"

# Test 2: Cascading override with target environment
load_environment "$SANDBOX" "staging"
assert_eq "https://api.base.example.com" "${BASE_URL:-}" "Cascaded environment retains non-overridden BASE_URL"
assert_eq "9090" "${PORT:-}" "Staging overrides PORT"
assert_eq "staging_override" "${SHARED_SECRET:-}" "Staging overrides SHARED_SECRET"

# Test 3: Safe literal interpolation with special characters (/, &, $, ")
load_environment "$SANDBOX" ""
input_template='{"url": "{{BASE_URL}}", "auth": "{{SPECIAL_TOKEN}}"}'
interpolated=$(interpolate_template "$input_template")
expected='{"url": "https://api.base.example.com", "auth": "secret/token&val=1$foo"bar"}'
assert_eq "$expected" "$interpolated" "Interpolation handles special characters without regex corruption"

# Test 4: Unbound variable detection throws error
input_template='Authorization: Bearer {{UNDEFINED_TOKEN}}'
set +e
output=$(interpolate_template "$input_template" 2>&1)
code=$?
set -e
assert_exit_code 1 "$code" "Unbound variable triggers exit code 1"
assert_contains "$output" "UNDEFINED_TOKEN" "Error specifies the unbound variable name"

report_results
