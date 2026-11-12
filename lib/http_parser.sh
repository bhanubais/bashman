#!/usr/bin/env bash
# bashman: Single-Request .http file parser
set -eou pipefail

# Global output variables populated by parse_http_file
# shellcheck disable=SC2034
PARSED_METHOD=""
# shellcheck disable=SC2034
PARSED_URL=""
# shellcheck disable=SC2034
PARSED_HEADERS=()
# shellcheck disable=SC2034
PARSED_BODY=""

parse_http_file() {
  local file_path="$1"

  if [[ ! -f "$file_path" ]]; then
    printf "[bashman] error: file '%s' not found\n" "$file_path" >&2
    return 1
  fi

  PARSED_METHOD=""
  PARSED_URL=""
  PARSED_HEADERS=()
  PARSED_BODY=""

  local state="REQUEST_LINE"
  local body_lines=()
  local found_request_line=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Strip carriage return (\r)
    line="${line%%$'\r'}"

    # Trim leading whitespace for comment check
    local trimmed_line="${line#"${line%%[![:space:]]*}"}"

    if [[ "$state" == "REQUEST_LINE" ]]; then
      # Skip empty lines and comment lines before the request line
      if [[ -z "$trimmed_line" || "$trimmed_line" =~ ^# || "$trimmed_line" =~ ^// ]]; then
        continue
      fi

      # Determine if line starts with an explicit HTTP verb
      local first_token rest_line
      first_token="${trimmed_line%% *}"

      case "$first_token" in
        GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS)
          PARSED_METHOD="$first_token"
          rest_line="${trimmed_line#"$first_token" }"
          # Trim leading whitespace from rest_line
          rest_line="${rest_line#"${rest_line%%[![:space:]]*}"}"
          ;;
        *)
          PARSED_METHOD="GET"
          rest_line="$trimmed_line"
          ;;
      esac

      # Extract URL and strip trailing HTTP/x.x protocol if present
      local target_url="${rest_line%% HTTP/*}"
      target_url="${target_url%% http/*}"
      # Trim trailing whitespace
      target_url="${target_url%"${target_url##*[![:space:]]}"}"

      PARSED_URL="$target_url"
      found_request_line=1
      state="HEADERS"
      continue
    fi

    if [[ "$state" == "HEADERS" ]]; then
      # Blank line signals end of headers and start of body
      if [[ -z "$trimmed_line" ]]; then
        state="BODY"
        continue
      fi

      # Skip comments within header block
      if [[ "$trimmed_line" =~ ^# || "$trimmed_line" =~ ^// ]]; then
        continue
      fi

      # Collect header line
      PARSED_HEADERS+=("$line")
      continue
    fi

    if [[ "$state" == "BODY" ]]; then
      body_lines+=("$line")
    fi
  done < "$file_path"

  if [[ "$found_request_line" -eq 0 || -z "$PARSED_URL" ]]; then
    printf "[bashman] error: file '%s' is empty or contains no valid HTTP request\n" "$file_path" >&2
    return 1
  fi

  # Reconstruct body preserving exact line breaks and indentation
  if [[ "${#body_lines[@]}" -gt 0 ]]; then
    local body_content=""
    for (( i=0; i<${#body_lines[@]}; i++ )); do
      if [[ "$i" -eq 0 ]]; then
        body_content="${body_lines[i]}"
      else
        body_content=$(printf "%s\n%s" "$body_content" "${body_lines[i]}")
      fi
    done
    PARSED_BODY="$body_content"
  else
    PARSED_BODY=""
  fi

  return 0
}
