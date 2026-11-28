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

# mapfile, and "${arr[@]}" on an empty array under set -u, need bash 4.4+.
# macOS's /bin/bash is 3.2, so CI runs this under nixpkgs' bash.
if [ "${BASH_VERSINFO[0]}" -lt 4 ] ||
  { [ "${BASH_VERSINFO[0]}" -eq 4 ] && [ "${BASH_VERSINFO[1]}" -lt 4 ]; }; then
  echo "::error::name-overlay-failures: needs bash 4.4 or later, got ${BASH_VERSION}" >&2
  exit 1
fi

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

# Failed derivations, one per line as <kind>\t<drv>[\t<detail>]:
#   own  - its own builder failed
#   dep  - it only failed because a dependency did
#   here - this machine can't build it at all (wrong platform or missing
#          system features). Nix only builds what no cache had, so this
#          means no substituter has it either. <detail> is what it needs.
# Handles the current "Cannot build '…'. / Reason: …" form and the older
# one-line forms.
mapfile -t failures < <(awk '
  function flush_here() {
    if (here != "") print "here\t" here "\t" here_detail
    here = ""; here_detail = ""
  }
  match($0, /Cannot build \047\/nix\/store\/[^\047]+\.drv\047/) {
    flush_here()
    pending = substr($0, RSTART + 14, RLENGTH - 15); next
  }
  pending != "" && /Reason:/ {
    if (/platform mismatch|missing system features|required system or feature not available/) {
      here = pending
    } else {
      print ((/dependenc/ ? "dep" : "own") "\t" pending)
    }
    pending = ""; next
  }
  here != "" && /Required (system|features):/ {
    sub(/^.*Required /, ""); here_detail = (here_detail == "" ? $0 : here_detail "; " $0); next
  }
  here != "" && /Current system:|Available features:|Output paths:/ { flush_here(); next }
  match($0, /a \047[^\047]+\047 with features \{[^}]*\} is required to build \047\/nix\/store\/[^\047]+\.drv\047/) {
    s = substr($0, RSTART + 3, RLENGTH - 3)
    sys = substr(s, 1, index(s, "\047") - 1)
    d = substr(s, index(s, "required to build \047") + 19); d = substr(d, 1, length(d) - 1)
    print "here\t" d "\tsystem: \047" sys "\047"; next
  }
  match($0, /builder for \047\/nix\/store\/[^\047]+\.drv\047 failed/) {
    s = substr($0, RSTART + 13); print "own\t" substr(s, 1, index(s, "\047") - 1); next
  }
  match($0, /dependencies of derivation \047\/nix\/store\/[^\047]+\.drv\047 failed/) {
    s = substr($0, RSTART + 28); print "dep\t" substr(s, 1, index(s, "\047") - 1)
  }
  END { flush_here() }
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
      IFS=$'\t' read -r kind fdrv detail <<<"$f"
      [ "$fdrv" = "$drv" ] || continue
      case "$kind" in
        own)
          add_match "$group" "$id" "$attr" "$strategy" "$description" "$notes" "failed to build" ;;
        here)
          add_match "$group" "$id" "$attr" "$strategy" "$description" "$notes" \
            "can't be built on this runner (needs ${detail:-another platform}) and no cache has it" ;;
        *)
          add_match "$group" "$id" "$attr" "$strategy" "$description" "$notes" \
            "failed because one of its dependencies did" ;;
      esac
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

own=()
here=()
for f in "${failures[@]}"; do
  IFS=$'\t' read -r kind fdrv detail <<<"$f"
  case "$kind" in
    own) own+=("$fdrv") ;;
    here)
      here+=("\`${fdrv}\` (needs ${detail:-another platform})")
      echo "::error title=No cache has ${fdrv#/nix/store/*-}::${fdrv} needs ${detail:-another platform}, which this ${host} runner can't build, and no binary cache has it for the locked inputs."
      ;;
  esac
done

{
  printf '## Overlays behind the %s build failure\n\n' "$host"
  if [ "$matched" -gt 0 ]; then
    printf '%s\n' "${report[@]}"
    printf '\nUpdate or remove these entries on this branch, so the fix lands with the lock update.\n'
  else
    printf 'No tracked overlay matches the failure, so it is most likely upstream, or in a permanent or exempt override.\n'
  fi
  if [ "${#here[@]}" -gt 0 ]; then
    printf '\nDerivations that no binary cache had and this runner (%s) cannot build:\n\n' "$(uname -sm)"
    printf -- '- %s\n' "${here[@]}"
    printf '\nNix only builds what it could not download, so no configured cache had these for the locked inputs. Usually Hydra has not built them (or failed to) at the locked nixpkgs revision. A later lock update normally picks up a revision where it has.\n'
  fi
  if [ "${#own[@]}" -gt 0 ]; then
    printf '\nDerivations whose own build failed:\n\n'
    printf -- "- \`%s\`\n" "${own[@]}"
  fi
} >>"$GITHUB_STEP_SUMMARY"
