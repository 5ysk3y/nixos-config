#!/usr/bin/env bash
# Names the tracked overlays behind a failed full build, so a red weekly
# flake.lock PR says which override to fix or remove on its branch.
# Run by .github/workflows/ci-full-build.yml after the build step fails:
#   name-overlay-failures.sh <host> <build log>
# Can also be run locally against a saved `nix build -L` log.
#
# Reads Nix's own failure lines from the log and compares the failed
# derivations with each tracked overlay's package (its evalAttr) on <host>.
# When no derivation failed, the build broke during evaluation, so it runs
# the same liveness check as the overlay audit for this host's entries.
# Reporting only: it never changes the build's result.
set -euo pipefail

host="$1"
log="$2"

GITHUB_WORKSPACE="${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel)}"
GITHUB_STEP_SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

# shellcheck source=.githooks/lib/overlay-liveness.sh
source "${GITHUB_WORKSPACE}/.githooks/lib/overlay-liveness.sh"

ns=$(resolve_config_namespace "$host")
if [ -z "$ns" ]; then
  echo "::warning::name-overlay-failures: '${host}' is not a NixOS or darwin configuration"
  exit 0
fi

# Failed derivations, split into those whose own builder failed and those
# that only failed because a dependency did. Handles both the current
# "Cannot build '…'. / Reason: …" form and the older one-line forms.
mapfile -t failures < <(awk '
  match($0, /Cannot build \047\/nix\/store\/[^\047]+\.drv\047/) {
    pending = substr($0, RSTART + 14, RLENGTH - 15); next
  }
  pending != "" && /Reason:/ {
    print ((/dependenc/ ? "dep" : "own") "\t" pending); pending = ""; next
  }
  match($0, /builder for \047\/nix\/store\/[^\047]+\.drv\047 failed/) {
    s = substr($0, RSTART + 13); print "own\t" substr(s, 1, index(s, "\047") - 1); next
  }
  match($0, /dependencies of derivation \047\/nix\/store\/[^\047]+\.drv\047 failed/) {
    s = substr($0, RSTART + 28); print "dep\t" substr(s, 1, index(s, "\047") - 1)
  }
' "$log" | sort -u)

# Tracked entries that apply to this host: group, id, evalAttr, strategy,
# description, notes. evalHosts defaults to the entry's own group, as in
# the liveness check.
audit_json=$(nix eval --json .#overlayAudits)
mapfile -t entries < <(jq -r --arg h "$host" '
  to_entries[] | .key as $g | .value | to_entries[]
  | select((.value.evalHosts // [$g]) | index($h))
  | [$g, .key, (.value.evalAttr // .key), .value.strategy,
     .value.description, (.value.notes // "")] | @tsv
' <<<"$audit_json")

report=()
matched=0

add_match() {
  local group="$1" id="$2" attr="$3" strategy="$4" description="$5" notes="$6" how="$7"
  matched=$((matched + 1))
  # A dependency failure may well be upstream rather than this override,
  # so it's a warning; the override's own build failing is an error.
  local level=error
  [[ "$how" == *dependencies* ]] && level=warning
  echo "::${level} title=Overlay ${group} / ${id}::${attr} ${how} on ${host}. Check this override on the PR branch."
  report+=("- 🔴 **${group} / ${id}** (\`${attr}\`) ${how}")
  report+=("    - ${description} (${strategy})")
  [ -n "$notes" ] && report+=("    - 📎 ${notes}")
  return 0
}

if [ "${#failures[@]}" -gt 0 ]; then
  for e in "${entries[@]}"; do
    IFS=$'\t' read -r group id attr strategy description notes <<<"$e"
    drv=$(nix eval --raw ".#${ns}.${host}.pkgs.${attr}.drvPath" 2>/dev/null) || continue
    for f in "${failures[@]}"; do
      [ "${f#*$'\t'}" = "$drv" ] || continue
      if [ "${f%%$'\t'*}" = own ]; then
        add_match "$group" "$id" "$attr" "$strategy" "$description" "$notes" "failed to build"
      else
        add_match "$group" "$id" "$attr" "$strategy" "$description" "$notes" \
          "failed because one of its dependencies did"
      fi
    done
  done
else
  # No derivation failed, so evaluation did. Find the overrides that no
  # longer evaluate.
  for e in "${entries[@]}"; do
    IFS=$'\t' read -r group id attr strategy description notes <<<"$e"
    if ! detail=$(check_override_evaluates "$ns" "$host" "$attr"); then
      add_match "$group" "$id" "$attr" "$strategy" "$description" "$notes" \
        "no longer evaluates: \`${detail}\`"
    fi
  done
fi

{
  printf '## Overlays behind the %s build failure\n\n' "$host"
  if [ "$matched" -gt 0 ]; then
    printf '%s\n' "${report[@]}"
    printf '\nUpdate or remove these entries on this branch, so the fix lands with the lock update.\n'
  else
    printf 'No tracked overlay matches the failure, so it is most likely upstream, or in a permanent or exempt override.\n'
  fi
  own=()
  for f in "${failures[@]}"; do
    [ "${f%%$'\t'*}" = own ] && own+=("${f#*$'\t'}")
  done
  if [ "${#own[@]}" -gt 0 ]; then
    printf '\nDerivations whose own build failed:\n\n'
    printf -- "- \`%s\`\n" "${own[@]}"
  fi
} >>"$GITHUB_STEP_SUMMARY"
