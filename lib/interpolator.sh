#!/usr/bin/env bash
# bashman: Environment loader & Safe literal variable interpolator
set -eou pipefail

_source_env_file() {
  local file="$1"
  [[ ! -f "$file" ]] && return 0

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Strip Windows CRLF carriage returns
    line="${line%%$'\r'}"
    # Strip leading whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    # Skip empty lines and comment lines
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      local key="${BASH_REMATCH[1]}"
      local val="${BASH_REMATCH[2]}"
      # Remove surrounding quotes if paired
      if [[ "$val" =~ ^\"(.*)\"$ ]]; then
        val="${BASH_REMATCH[1]}"
      elif [[ "$val" =~ ^\'(.*)\'$ ]]; then
        val="${BASH_REMATCH[1]}"
      fi
      export "$key=$val"
    fi
  done < "$file"
}

load_environment() {
  local search_dir="${1:-.}"
  local env_name="${2:-}"

  # 1. Base .env
  local base_file="$search_dir/.env"
  if [[ -f "$base_file" ]]; then
    _source_env_file "$base_file"
  fi

  # 2. Target cascaded .env.<name>
  if [[ -n "$env_name" ]]; then
    local target_file="$search_dir/.env.$env_name"
    if [[ -f "$target_file" ]]; then
      _source_env_file "$target_file"
    else
      printf "[bashman] error: environment file '%s' not found\n" "$target_file" >&2
      return 1
    fi
  fi

  return 0
}

interpolate_template() {
  local content="$1"

  # Find all unique {{VAR}} placeholders
  # Using grep with POSIX regex
  local placeholders
  placeholders=$(printf "%s" "$content" | grep -o '{{[A-Za-z_][A-Za-z0-9_]*}}' | sort -u || true)

  if [[ -z "$placeholders" ]]; then
    printf "%s" "$content"
    return 0
  fi

  # Validate all variables are bound
  while IFS= read -r placeholder; do
    [[ -z "$placeholder" ]] && continue
    local var_name="${placeholder:2:-2}"
    if [[ -z "${!var_name+x}" ]]; then
      printf "[bashman] error: unbound variable '%s'\n" "$placeholder" >&2
      return 1
    fi
  done <<< "$placeholders"

  # Literal substitution loop using awk exact string concatenation
  # Immune to regex backreferences, '/', '&', '\', and '$'
  local current_content="$content"
  while IFS= read -r placeholder; do
    [[ -z "$placeholder" ]] && continue
    local var_name="${placeholder:2:-2}"
    local var_val="${!var_name}"

    current_content=$(awk -v find="$placeholder" -v repl="$var_val" '
      BEGIN {
        # Literal replacement using index and substr
        idx = 0
      }
      {
        line = $0
        res = ""
        while ((p = index(line, find)) > 0) {
          res = res substr(line, 1, p - 1) repl
          line = substr(line, p + length(find))
        }
        res = res line
        lines[NR] = res
      }
      END {
        for (i = 1; i <= NR; i++) {
          if (i < NR) {
            print lines[i]
          } else {
            printf "%s", lines[i]
          }
        }
      }
    ' <<< "$current_content")
  done <<< "$placeholders"

  printf "%s" "$current_content"
}
