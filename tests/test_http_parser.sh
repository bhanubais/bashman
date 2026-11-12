#!/usr/bin/env bash
# Test Suite: Single-Request .http Parser
set -eou pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$DIR/.." && pwd)"

source "$DIR/test_harness.bash"

SANDBOX=$(mktemp -d 2>/dev/null || mktemp -d -t 'bashman-test')
trap 'rm -rf "$SANDBOX"' EXIT

printf "\n=== Running .http Parser Test Suite ===\n\n"

PARSER_LIB="$PROJECT_ROOT/lib/http_parser.sh"

if [[ ! -f "$PARSER_LIB" ]]; then
  assert_eq "file_exists" "file_missing" "http_parser.sh module exists"
  report_results
  exit 1
fi

# shellcheck source=../lib/http_parser.sh
source "$PARSER_LIB"

# Test 1: Full POST request with headers and multiline JSON body
cat <<'EOF' > "$SANDBOX/post_user.http"
# Comment line to ignore
// Another comment style to ignore
POST https://api.example.com/v1/users HTTP/1.1
Content-Type: application/json
Authorization: Bearer my-secret-token
X-Custom-Header: value with spaces

{
  "name": "Jane Doe",
  "active": true,
  "roles": ["admin", "developer"]
}
EOF

parse_http_file "$SANDBOX/post_user.http"
assert_eq "POST" "$PARSED_METHOD" "Parser extracts POST method"
assert_eq "https://api.example.com/v1/users" "$PARSED_URL" "Parser extracts clean URL without HTTP version"
assert_eq "3" "${#PARSED_HEADERS[@]}" "Parser extracts all 3 headers"
assert_eq "Content-Type: application/json" "${PARSED_HEADERS[0]}" "Parser preserves header 1"
assert_eq "Authorization: Bearer my-secret-token" "${PARSED_HEADERS[1]}" "Parser preserves header 2"
assert_eq "X-Custom-Header: value with spaces" "${PARSED_HEADERS[2]}" "Parser preserves header 3"

expected_body=$(printf '{\n  "name": "Jane Doe",\n  "active": true,\n  "roles": ["admin", "developer"]\n}')
assert_eq "$expected_body" "$PARSED_BODY" "Parser preserves multiline body and indentation exactly"

# Test 2: Implicit GET method when method is omitted
cat <<'EOF' > "$SANDBOX/simple_get.http"
https://api.example.com/health
Accept: application/json
EOF

parse_http_file "$SANDBOX/simple_get.http"
assert_eq "GET" "$PARSED_METHOD" "Parser defaults to GET method"
assert_eq "https://api.example.com/health" "$PARSED_URL" "Parser extracts target URL"
assert_eq "1" "${#PARSED_HEADERS[@]}" "Parser extracts single header"
assert_eq "" "$PARSED_BODY" "Parser detects empty body"

# Test 3: Windows CRLF line endings
printf "POST https://api.example.com/test\r\nContent-Type: text/plain\r\n\r\nhello world\r\n" > "$SANDBOX/crlf.http"
parse_http_file "$SANDBOX/crlf.http"
assert_eq "POST" "$PARSED_METHOD" "CRLF file parsed with correct method"
assert_eq "https://api.example.com/test" "$PARSED_URL" "CRLF stripped from URL"
assert_eq "Content-Type: text/plain" "${PARSED_HEADERS[0]}" "CRLF stripped from headers"
assert_eq "hello world" "$PARSED_BODY" "CRLF stripped from body trailing line"

# Test 4: Empty file produces error
touch "$SANDBOX/empty.http"
set +e
output=$(parse_http_file "$SANDBOX/empty.http" 2>&1)
code=$?
set -e
assert_exit_code 1 "$code" "Empty file returns exit code 1"
assert_contains "$output" "empty" "Error message indicates empty file"

report_results
