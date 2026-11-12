#!/usr/bin/env bash
# bashman doctor: toolchain diagnostics
set -eou pipefail

C_BOLD="\033[1m"
C_GREEN="\033[32m"
C_RED="\033[31m"
C_YELLOW="\033[33m"
C_GRAY="\033[90m"
C_RESET="\033[0m"

check_binary() {
  local bin_name="$1"
  if command -v "$bin_name" >/dev/null 2>&1; then
    local bin_path
    bin_path=$(command -v "$bin_name")
    printf "  %b✓%b %-8s [%s]\n" "$C_GREEN" "$C_RESET" "$bin_name" "$bin_path"
    return 0
  else
    printf "  %b✗%b %-8s [Not Found]\n" "$C_RED" "$C_RESET" "$bin_name"
    return 1
  fi
}

run_doctor() {
  printf "\n%bbashman Toolchain Diagnostics%b\n" "$C_BOLD" "$C_RESET"
  printf "============================\n\n"

  printf "%b[Foundational Engine - Portable Base]%b\n" "$C_BOLD" "$C_RESET"
  local found_missing=0
  check_binary "curl" || found_missing=$((found_missing + 1))
  check_binary "jq" || found_missing=$((found_missing + 1))
  check_binary "awk" || found_missing=$((found_missing + 1))

  printf "\n%b[Accelerated Engine - Modern Rust Tools]%b\n" "$C_BOLD" "$C_RESET"
  local accel_missing=0
  check_binary "xh" || accel_missing=$((accel_missing + 1))
  check_binary "sd" || accel_missing=$((accel_missing + 1))
  check_binary "bat" || accel_missing=$((accel_missing + 1))

  printf "\n%bEngine Status:%b\n" "$C_BOLD" "$C_RESET"
  if [[ "$found_missing" -eq 0 && "$accel_missing" -eq 0 ]]; then
    printf "  %bTier 1 (Maximum Acceleration)%b: xh + sd + bat active.\n" "$C_GREEN" "$C_RESET"
  elif [[ "$found_missing" -eq 0 ]]; then
    printf "  %bTier 2 (Foundational Fallback)%b: curl + jq + awk active.\n" "$C_YELLOW" "$C_RESET"
    printf "  %bTip: Install xh, sd, and bat for accelerated terminal formatting.%b\n" "$C_GRAY" "$C_RESET"
  else
    printf "  %bCritical Failure%b: Missing foundational dependencies (curl, jq, or awk).\n" "$C_RED" "$C_RESET"
    return 127
  fi

  return 0
}
