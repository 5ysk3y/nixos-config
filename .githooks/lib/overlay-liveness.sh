#!/usr/bin/env bash
# Shared overlay-liveness-checking logic.
#
# Sourced by both .githooks/pre-commit and .github/workflows/audit-overlays.yaml
# so the actual evalHosts/evalAttr resolution and nix-eval check exists in
# exactly one place. A future fix to this logic (see: the qtwebengine
# evalAttr-defaulting incident) only needs to happen once, and both callers
# get it automatically rather than risking silent drift between two
# hand-copied implementations.
#
# This file intentionally does NOT include the GitHub issue/PR
# tracking-status checks (check_github_items etc.) — those only make sense
# in CI, calling out to the GitHub API on a schedule. Running that against
# every local commit would be slow and pointless. Only the part that's
# genuinely identical in both contexts — "does this override still
# evaluate" — lives here.

# resolve_config_namespace: determines whether a host lives under
# nixosConfigurations or darwinConfigurations, by probing both.
# Prints the namespace to stdout, empty if neither matches.
resolve_config_namespace() {
  local host="$1"
  if nix eval --json ".#nixosConfigurations.${host}" --apply 'x: true' >/dev/null 2>&1; then
    echo "nixosConfigurations"
  elif nix eval --json ".#darwinConfigurations.${host}" --apply 'x: true' >/dev/null 2>&1; then
    echo "darwinConfigurations"
  else
    echo ""
  fi
}

# check_override_evaluates: attempts to force derivation construction for
# the overridden package, independent of tracking-issue status. This catches
# breakage like a renamed .override argument that a closed upstream issue
# would never surface.
# Returns 0 = still evaluates fine, 1 = broken, prints error tail on failure.
check_override_evaluates() {
  local config_ns="$1" host="$2" eval_attr="$3"
  local err_log
  err_log="$(mktemp)"
  if nix eval --raw --inputs-from . \
      ".#${config_ns}.${host}.pkgs.${eval_attr}.drvPath" \
      >/dev/null 2>"$err_log"; then
    rm -f "$err_log"
    return 0
  else
    tail -n 6 "$err_log" | tr '\n' ' ' | sed 's/  */ /g'
    rm -f "$err_log"
    return 1
  fi
}

# check_entry_liveness: given the full overlayAudits JSON, a host_key and id,
# resolves evalHosts/evalAttr (with the same defaulting rules in both
# callers) and runs check_override_evaluates against each real target.
#
# For every target, invokes the named callback function as:
#   "$callback" <host_key> <id> <target_host> <eval_attr> <result> <detail>
# where <result> is one of: pass | fail | skip
#
# This lets each caller decide how to report/accumulate results (plain
# stdout + exit code for the hook; markdown report lines + a BROKEN_IDS
# array for CI) without duplicating the resolution/eval logic itself.
check_entry_liveness() {
  local audit_json="$1" host_key="$2" id="$3" callback="$4"
  local entry default_ns eval_hosts_json eval_attr

  entry=$(echo "$audit_json" | jq -c --arg h "$host_key" --arg id "$id" '.[$h][$id]')
  default_ns=$(resolve_config_namespace "$host_key")

  eval_hosts_json=$(echo "$entry" | jq -c '.evalHosts // empty')
  local eval_hosts=()
  if [ -n "$eval_hosts_json" ] && [ "$eval_hosts_json" != "null" ]; then
    mapfile -t eval_hosts < <(echo "$eval_hosts_json" | jq -r '.[]')
  elif [ -n "$default_ns" ]; then
    eval_hosts=("$host_key")
  fi

  eval_attr=$(echo "$entry" | jq -r '.evalAttr // empty')
  if [ -z "$eval_attr" ]; then
    eval_attr="$id"
    echo "  WARNING: evalAttr not set for ${host_key}/${id} — defaulting to '${eval_attr}' (verify this matches the actual overridden path, especially for nested/scoped overrides)" >&2
  fi

  if [ ${#eval_hosts[@]} -eq 0 ]; then
    "$callback" "$host_key" "$id" "" "$eval_attr" "skip" \
      "no evalHosts (and '${host_key}' isn't a resolvable config) — liveness check skipped"
    return 0
  fi

  for target_host in "${eval_hosts[@]}"; do
    [ -z "$target_host" ] && continue
    local target_ns="$default_ns"
    if [ "$target_host" != "$host_key" ] || [ -z "$target_ns" ]; then
      target_ns=$(resolve_config_namespace "$target_host")
    fi
    if [ -z "$target_ns" ]; then
      "$callback" "$host_key" "$id" "$target_host" "$eval_attr" "skip" \
        "could not resolve config namespace for evalHosts entry '${target_host}'"
      continue
    fi

    local eval_error=""
    if eval_error=$(check_override_evaluates "$target_ns" "$target_host" "$eval_attr"); then
      "$callback" "$host_key" "$id" "$target_host" "$eval_attr" "pass" ""
    else
      "$callback" "$host_key" "$id" "$target_host" "$eval_attr" "fail" "$eval_error"
    fi
  done
}
