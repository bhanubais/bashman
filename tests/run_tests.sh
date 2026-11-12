#!/usr/bin/env bash
# bashman test runner
set -eou pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FAILED=0
for test_file in "$DIR"/test_*.sh; do
  if [[ -f "$test_file" ]]; then
    printf "\n-> Running %s...\n" "$(basename "$test_file")"
    if ! bash "$test_file"; then
      FAILED=1
    fi
  fi
done

if [[ "$FAILED" -ne 0 ]]; then
  printf "\n\033[31mSuite FAILED\033[0m\n"
  exit 1
fi

printf "\n\033[32mAll test suites PASSED!\033[0m\n"
exit 0
