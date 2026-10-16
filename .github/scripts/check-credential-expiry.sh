#!/usr/bin/env bash
# Warns before CI credentials expire.
#
# Usage: check-credential-expiry.sh NAME...
#
# For each NAME (a secret's name), reads its expiry date (DD-MM-YYYY) from
# the environment variable NAME_EXPIRES, which the workflow fills from the
# repository variable of the same name. Writes a markdown report and sets
# these step outputs:
#   attention   number of credentials expiring within WARN_DAYS, expired,
#               or without a valid date
#   invalid     number of credentials whose date is missing or malformed
#   report_file path to the markdown report
# Backticks in the printf formats below are markdown, not command substitution.
# shellcheck disable=SC2016
set -euo pipefail

warn_days="${WARN_DAYS:-21}"
today="$(date -u +%Y-%m-%d)"
today_epoch="$(date -u -d "$today" +%s)"

report="$(mktemp)"
attention=0
invalid=0

{
  printf '| Secret | Expires | Days left | Status |\n'
  printf '|---|---|---|---|\n'
} > "$report"

for name in "$@"; do
  var="${name}_EXPIRES"
  value="${!var:-}"

  # date(1) can't parse DD-MM-YYYY, so reorder it to YYYY-MM-DD first
  if [[ ! "$value" =~ ^([0-9]{2})-([0-9]{2})-([0-9]{4})$ ]] \
    || ! expiry_epoch="$(date -u -d "${BASH_REMATCH[3]}-${BASH_REMATCH[2]}-${BASH_REMATCH[1]}" +%s 2>/dev/null)"; then
    echo "::error::repository variable ${var} is missing or not a DD-MM-YYYY date (got: '${value}')"
    printf '| `%s` | `%s` | | ❓ set the `%s` repository variable (DD-MM-YYYY) |\n' \
      "$name" "${value:-unset}" "$var" >> "$report"
    attention=$((attention + 1))
    invalid=$((invalid + 1))
    continue
  fi

  days=$(((expiry_epoch - today_epoch) / 86400))
  if ((days < 0)); then
    status="🔴 expired"
    echo "::warning::${name} expired on ${value}"
    attention=$((attention + 1))
  elif ((days <= warn_days)); then
    status="🟠 rotate now"
    echo "::warning::${name} expires on ${value} (${days} days)"
    attention=$((attention + 1))
  else
    status="✅ ok"
  fi
  printf '| `%s` | %s | %s | %s |\n' "$name" "$value" "$days" "$status" >> "$report"
done

cat "$report"
{
  echo "attention=${attention}"
  echo "invalid=${invalid}"
  echo "report_file=${report}"
} >> "${GITHUB_OUTPUT:-/dev/null}"
