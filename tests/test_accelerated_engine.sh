#!/usr/bin/env bash
# Test Suite: Accelerated Engine Routing (xh + bat)
set -eou pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$DIR/.." && pwd)"

source "$DIR/test_harness.bash"

SANDBOX=$(mktemp -d 2>/dev/null || mktemp -d -t 'bashman-test')
trap 'rm -rf "$SANDBOX"' EXIT

printf "\n=== Running Accelerated Engine Test Suite ===\n\n"

# shellcheck source=../lib/dispatcher.sh
source "$PROJECT_ROOT/lib/dispatcher.sh"

MOCK_BIN="$SANDBOX/mock_bin"
mkdir -p "$MOCK_BIN"

# Create mock 'xh' binary
cat <<'EOF' > "$MOCK_BIN/xh"
#!/usr/bin/env bash
printf "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"engine\": \"xh_mock\", \"received\": \"$*\"}\n"
EOF
chmod +x "$MOCK_BIN/xh"

# Create mock 'bat' binary
cat <<'EOF' > "$MOCK_BIN/bat"
#!/usr/bin/env bash
printf "[BAT_HIGHLIGHTED]\n"
cat
EOF
chmod +x "$MOCK_BIN/bat"

ORIG_PATH="$PATH"

# Test 1: Function detects accelerated capability
if ! declare -F can_use_accelerated_engine >/dev/null 2>&1; then
  assert_eq "function_exists" "function_missing" "can_use_accelerated_engine function declared"
  report_results
  exit 1
fi

export PATH="$MOCK_BIN:$ORIG_PATH"
assert_eq "0" "$(can_use_accelerated_engine && echo 0 || echo 1)" "Detects xh acceleration when present on PATH"

# Test 2: Routing through accelerated engine dispatches via xh
headers=("Authorization: Bearer token123" "Content-Type: application/json")
output=$(dispatch_request "POST" "https://api.example.com/items" headers '{"test": true}')
assert_contains "$output" "xh_mock" "Request routes through xh when accelerated engine is available"
assert_contains "$output" "[BAT_HIGHLIGHTED]" "Response body pipes through bat when bat is available"

# Test 3: Fallback to curl when xh is absent from PATH
export PATH="$ORIG_PATH"
empty_headers=()
output=$(dispatch_request "GET" "https://httpbin.org/status/200" empty_headers "" 2>&1 || true)
assert_contains "$output" "200" "Fallback engine executes through curl"

report_results
