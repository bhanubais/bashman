#!/usr/bin/env bash
# Test Suite: Foundational Dispatcher & Dry-Run Pipeline
set -eou pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$DIR/.." && pwd)"

source "$DIR/test_harness.bash"

SANDBOX=$(mktemp -d 2>/dev/null || mktemp -d -t 'bashman-test')
trap 'rm -rf "$SANDBOX"' EXIT

printf "\n=== Running Dispatcher & Dry-Run Test Suite ===\n\n"

DISPATCHER_LIB="$PROJECT_ROOT/lib/dispatcher.sh"

if [[ ! -f "$DISPATCHER_LIB" ]]; then
  assert_eq "file_exists" "file_missing" "dispatcher.sh module exists"
  report_results
  exit 1
fi

# shellcheck source=../lib/dispatcher.sh
source "$DISPATCHER_LIB"

# Test 1: Dry-run output inspection via CLI
cat <<'EOF' > "$SANDBOX/create_item.http"
POST https://api.example.com/v1/items HTTP/1.1
Content-Type: application/json
Authorization: Bearer test-secret

{
  "item_id": 42,
  "label": "Widget"
}
EOF

output=$("$PROJECT_ROOT/bin/bashman" run --dry-run "$SANDBOX/create_item.http" 2>&1)
assert_contains "$output" "[DRY-RUN]" "CLI --dry-run flag outputs dry-run banner"
assert_contains "$output" "POST https://api.example.com/v1/items" "Dry-run displays method and target URL"
assert_contains "$output" "Content-Type: application/json" "Dry-run displays headers"
assert_contains "$output" '"item_id": 42' "Dry-run displays request body"

# Test 2: Dry-run with cascading environment interpolation
cat <<'EOF' > "$SANDBOX/.env"
HOST=api.example.com
KEY=base_key
EOF

cat <<'EOF' > "$SANDBOX/.env.prod"
HOST=prod.example.com
KEY=prod_secret_123
EOF

cat <<'EOF' > "$SANDBOX/templated.http"
GET https://{{HOST}}/v1/secure
X-Api-Key: {{KEY}}
EOF

(
  cd "$SANDBOX"
  output=$("$PROJECT_ROOT/bin/bashman" run --env prod --dry-run "templated.http" 2>&1)
  assert_contains "$output" "https://prod.example.com/v1/secure" "Dry-run interpolates target environment URL"
  assert_contains "$output" "X-Api-Key: prod_secret_123" "Dry-run interpolates target environment headers"
)

# Test 3: Metadata extraction and formatting
meta_raw=$(printf '{"status": "ok"}\n__BASHMAN_META__:200:0.125s\n')
parse_curl_output "$meta_raw"
assert_eq "200" "$EXTRACTED_HTTP_CODE" "Dispatcher extracts 200 HTTP status code"
assert_eq "0.125s" "$EXTRACTED_TIME_TOTAL" "Dispatcher extracts execution duration"
assert_eq '{"status": "ok"}' "$EXTRACTED_RESPONSE_BODY" "Dispatcher extracts clean body separated from metadata"

# Test 4: Format status badge
badge_200=$(format_status_badge "200")
assert_contains "$badge_200" "200 OK" "Status badge formats 200 OK"

badge_404=$(format_status_badge "404")
assert_contains "$badge_404" "404 Not Found" "Status badge formats 404 Not Found"

report_results
