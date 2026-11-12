#!/usr/bin/env bash
# bashman: Request Dispatcher & Presentation Pipeline
set -eou pipefail

C_BOLD="\033[1m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_RED="\033[31m"
C_CYAN="\033[36m"
C_GRAY="\033[90m"
C_RESET="\033[0m"

# Global extracted response variables
# shellcheck disable=SC2034
EXTRACTED_HTTP_CODE=""
# shellcheck disable=SC2034
EXTRACTED_TIME_TOTAL=""
# shellcheck disable=SC2034
EXTRACTED_RESPONSE_BODY=""

can_use_accelerated_engine() {
  command -v xh >/dev/null 2>&1
}

format_status_badge() {
  local code="$1"
  local text="HTTP $code"
  local color="$C_RESET"

  case "$code" in
    200) text="200 OK"; color="$C_GREEN" ;;
    201) text="201 Created"; color="$C_GREEN" ;;
    204) text="204 No Content"; color="$C_GREEN" ;;
    301) text="301 Moved Permanently"; color="$C_CYAN" ;;
    302) text="302 Found"; color="$C_CYAN" ;;
    304) text="304 Not Modified"; color="$C_CYAN" ;;
    400) text="400 Bad Request"; color="$C_YELLOW" ;;
    401) text="401 Unauthorized"; color="$C_YELLOW" ;;
    403) text="403 Forbidden"; color="$C_YELLOW" ;;
    404) text="404 Not Found"; color="$C_YELLOW" ;;
    422) text="422 Unprocessable Entity"; color="$C_YELLOW" ;;
    429) text="429 Too Many Requests"; color="$C_YELLOW" ;;
    500) text="500 Internal Server Error"; color="$C_RED" ;;
    502) text="502 Bad Gateway"; color="$C_RED" ;;
    503) text="503 Service Unavailable"; color="$C_RED" ;;
    504) text="504 Gateway Timeout"; color="$C_RED" ;;
    *)
      if [[ "$code" =~ ^2 ]]; then color="$C_GREEN"
      elif [[ "$code" =~ ^3 ]]; then color="$C_CYAN"
      elif [[ "$code" =~ ^4 ]]; then color="$C_YELLOW"
      elif [[ "$code" =~ ^5 ]]; then color="$C_RED"
      fi
      ;;
  esac

  printf "%b[%s]%b" "$color" "$text" "$C_RESET"
}

parse_curl_output() {
  local raw_output="$1"
  local marker="__BASHMAN_META__:"

  if [[ "$raw_output" != *"$marker"* ]]; then
    EXTRACTED_HTTP_CODE="000"
    EXTRACTED_TIME_TOTAL="0.000s"
    EXTRACTED_RESPONSE_BODY="$raw_output"
    return 0
  fi

  # Split body and metadata marker
  local body_part="${raw_output%%"$marker"*}"
  # Trim trailing newline from body
  EXTRACTED_RESPONSE_BODY="${body_part%$'\n'}"

  local meta_part="${raw_output#*"$marker"}"
  meta_part="${meta_part%%$'\n'}"
  meta_part="${meta_part%%$'\r'}"

  EXTRACTED_HTTP_CODE="${meta_part%%:*}"
  EXTRACTED_TIME_TOTAL="${meta_part#*:}"
}

format_response_body() {
  local body="$1"
  [[ -z "$body" ]] && return 0

  # Accelerated presentation via bat if installed
  if command -v bat >/dev/null 2>&1; then
    printf "%s" "$body" | bat -l json --style=plain --paging=never 2>/dev/null && return 0
  fi

  # Foundational presentation via jq if installed and valid JSON
  if command -v jq >/dev/null 2>&1; then
    if printf "%s" "$body" | jq . >/dev/null 2>&1; then
      printf "%s" "$body" | jq .
      return 0
    fi
  fi

  # Fallback: print raw body
  printf "%s\n" "$body"
}

execute_dry_run() {
  local method="$1"
  local url="$2"
  local -n headers_ref="$3"
  local body="$4"

  printf "\n%b[DRY-RUN] Request Preview%b\n" "$C_BOLD" "$C_RESET"
  printf "=========================\n"
  printf "  %bMethod:%b  %s\n" "$C_BOLD" "$C_RESET" "$method"
  printf "  %bTarget:%b  %s %s\n" "$C_BOLD" "$C_RESET" "$method" "$url"

  if [[ "${#headers_ref[@]}" -gt 0 ]]; then
    printf "  %bHeaders:%b\n" "$C_BOLD" "$C_RESET"
    for hdr in "${headers_ref[@]}"; do
      printf "    - %s\n" "$hdr"
    done
  fi

  if [[ -n "$body" ]]; then
    printf "  %bPayload:%b\n" "$C_BOLD" "$C_RESET"
    printf "%s\n" "$body"
  fi
  printf "\n"
}

dispatch_curl() {
  local method="$1"
  local url="$2"
  local -n headers_ref="$3"
  local body="$4"

  local curl_args=("-s" "-S" "-X" "$method" "$url")

  for hdr in "${headers_ref[@]}"; do
    curl_args+=("-H" "$hdr")
  done

  curl_args+=("-w" "\n__BASHMAN_META__:%{http_code}:%{time_total}s\n")

  local raw_response
  if [[ -n "$body" ]]; then
    curl_args+=("--data-binary" "@-")
    raw_response=$(printf "%s" "$body" | curl "${curl_args[@]}" 2>&1 || true)
  else
    raw_response=$(curl "${curl_args[@]}" 2>&1 || true)
  fi

  parse_curl_output "$raw_response"

  local badge
  badge=$(format_status_badge "$EXTRACTED_HTTP_CODE")
  printf "\n%s  %b[%s]%b\n\n" "$badge" "$C_GRAY" "$EXTRACTED_TIME_TOTAL" "$C_RESET"

  format_response_body "$EXTRACTED_RESPONSE_BODY"
}

dispatch_xh() {
  local method="$1"
  local url="$2"
  local -n headers_ref="$3"
  local body="$4"

  local xh_args=("--print=hb" "$method" "$url")

  for hdr in "${headers_ref[@]}"; do
    xh_args+=("$hdr")
  done

  local raw_response
  if [[ -n "$body" ]]; then
    raw_response=$(printf "%s" "$body" | xh "${xh_args[@]}" --raw="$body" 2>&1 || true)
  else
    raw_response=$(xh "${xh_args[@]}" 2>&1 || true)
  fi

  # Parse HTTP status code from first line (e.g. HTTP/1.1 200 OK)
  local first_line
  first_line=$(printf "%s" "$raw_response" | head -n 1)
  local http_code="200"
  if [[ "$first_line" =~ HTTP/[0-9.]+[[:space:]]+([0-9]{3}) ]]; then
    http_code="${BASH_REMATCH[1]}"
  fi

  # Separate headers from body (separated by blank line)
  local response_body=""
  local in_body=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%$'\r'}"
    if [[ "$in_body" -eq 1 ]]; then
      if [[ -z "$response_body" ]]; then
        response_body="$line"
      else
        response_body=$(printf "%s\n%s" "$response_body" "$line")
      fi
    elif [[ -z "$line" ]]; then
      in_body=1
    fi
  done <<< "$raw_response"

  local badge
  badge=$(format_status_badge "$http_code")
  printf "\n%s  %b[accelerated]%b\n\n" "$badge" "$C_GREEN" "$C_RESET"

  format_response_body "$response_body"
}

dispatch_request() {
  local method="$1"
  local url="$2"
  local headers_name="$3"
  local body="$4"

  if can_use_accelerated_engine; then
    dispatch_xh "$method" "$url" "$headers_name" "$body"
  else
    dispatch_curl "$method" "$url" "$headers_name" "$body"
  fi
}
