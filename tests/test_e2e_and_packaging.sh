#!/usr/bin/env bash
# Test Suite: End-to-End Edge Cases & Release Packaging
set -eou pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$DIR/.." && pwd)"
BASHMAN="$PROJECT_ROOT/bin/bashman"

source "$DIR/test_harness.bash"

SANDBOX=$(mktemp -d 2>/dev/null || mktemp -d -t 'bashman-test')
trap 'rm -rf "$SANDBOX"' EXIT

printf "\n=== Running E2E & Packaging Test Suite ===\n\n"

# Test 1: Documentation exists
if [[ ! -f "$PROJECT_ROOT/README.md" ]]; then
  assert_eq "file_exists" "file_missing" "README.md documentation exists"
else
  readme_content=$(cat "$PROJECT_ROOT/README.md")
  assert_contains "$readme_content" "bashman" "README documents bashman"
  assert_contains "$readme_content" "Quick Start" "README contains Quick Start guide"
fi

# Test 2: Execution from arbitrary directory
(
  cd "$SANDBOX"
  output=$("$BASHMAN" --version 2>&1)
  assert_contains "$output" "0.1.0" "Executable operates correctly from external directories"
)

# Test 3: Non-existent .http file halts with exit 1
set +e
output=$("$BASHMAN" run "$SANDBOX/does_not_exist.http" 2>&1)
code=$?
set -e
assert_exit_code 1 "$code" "Missing .http file triggers exit code 1"
assert_contains "$output" "not found" "Error states request file not found"

# Test 4: Request with unbound variable halts before dispatching
cat <<'EOF' > "$SANDBOX/unbound.http"
POST https://api.example.com/items
Authorization: Bearer {{NON_EXISTENT_SECRET}}

{"key": "value"}
EOF

set +e
output=$("$BASHMAN" run "$SANDBOX/unbound.http" 2>&1)
code=$?
set -e
assert_exit_code 1 "$code" "Unbound variable in request halts with exit code 1"
assert_contains "$output" "NON_EXISTENT_SECRET" "Error identifies unbound variable"

# Test 5: End-to-end dry-run with full interpolation
cat <<'EOF' > "$SANDBOX/.env"
HOST=example.org
EOF

cat <<'EOF' > "$SANDBOX/.env.custom"
HOST=custom.example.org
TOKEN=tok_987654321
EOF

cat <<'EOF' > "$SANDBOX/valid.http"
POST https://{{HOST}}/api/resource HTTP/1.1
Authorization: Bearer {{TOKEN}}
Content-Type: application/json

{"hello": "world"}
EOF

(
  cd "$SANDBOX"
  output=$("$BASHMAN" run --env custom --dry-run "valid.http" 2>&1)
  assert_contains "$output" "https://custom.example.org/api/resource" "E2E dry-run outputs interpolated URL"
  assert_contains "$output" "Authorization: Bearer tok_987654321" "E2E dry-run outputs interpolated header"
  assert_contains "$output" '{"hello": "world"}' "E2E dry-run outputs body"
)

report_results
