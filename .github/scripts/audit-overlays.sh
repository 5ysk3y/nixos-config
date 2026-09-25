#!/usr/bin/env bash
# Overlay obsolescence/liveness audit — run by .github/workflows/audit-overlays.yaml.
# Kept as a standalone script so it can be shellchecked and run locally:
#   GH_TOKEN=$(gh auth token) .github/scripts/audit-overlays.sh
# Outside Actions, GITHUB_WORKSPACE defaults to the repo root and the
# step outputs are printed to stdout instead of $GITHUB_OUTPUT.
set -euo pipefail

GITHUB_WORKSPACE="${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel)}"
GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/stdout}"

# Liveness-check logic (resolve_config_namespace, check_override_evaluates,
# check_entry_liveness) is shared with the pre-commit hook via this file,
# so it exists in exactly one place rather than two hand-copied
# implementations that could drift.
# shellcheck source=.githooks/lib/overlay-liveness.sh
source "${GITHUB_WORKSPACE}/.githooks/lib/overlay-liveness.sh"

OBSOLETE_IDS=()
BROKEN_IDS=()
REPORT_LINES=()

# ----------------------------------------------------------------
# version_gte: returns 0 if $1 >= $2, 1 otherwise.
# Uses GNU sort -V (coreutils, available on ubuntu-latest).
# Handles dot-separated version strings including NVIDIA-style
# three-component versions (610.43.02).
# ----------------------------------------------------------------
version_gte() {
  local a="$1" b="$2"
  [ "$(printf '%s\n%s' "$a" "$b" | sort -V | head -n1)" = "$b" ]
}

# ----------------------------------------------------------------
# check_nixpkgs_version: evaluates nixpkgs#legacyPackages.<system>.<attr>
# and compares against threshold.
# Returns: 0 = obsolete, 1 = still needed, 2 = eval failed
# Prints the resolved current version to stdout on success.
# ----------------------------------------------------------------
check_nixpkgs_version() {
  local attr="$1" threshold="$2" system="$3"
  local current
  echo "    nix eval nixpkgs#legacyPackages.${system}.${attr} ..." >&2
  current=$(nix eval --raw --inputs-from . "nixpkgs#legacyPackages.${system}.${attr}" 2>/dev/null) || {
    echo "    WARNING: eval failed" >&2
    return 2
  }
  echo "    result: ${current}  (threshold: ${threshold})" >&2
  echo "$current"
  version_gte "$current" "$threshold"
}

# ------------------------------------------------------------------
# check_landed_in_nixpkgs: given a commit SHA from NixOS/nixpkgs,
# checks whether it's already an ancestor of the locked nixpkgs rev
# (i.e. actually present in what a system builds against, not
# just merged somewhere upstream).
# Returns 0 if landed, 1 if not.
# ------------------------------------------------------------------
check_landed_in_nixpkgs() {
  local commit_sha="$1"
  local cmp_status
  cmp_status=$(curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GH_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/NixOS/nixpkgs/compare/${LOCKED_NIXPKGS_REV}...${commit_sha}" \
    | jq -r '.status')
  echo "    compare ${LOCKED_NIXPKGS_REV}...${commit_sha}: ${cmp_status}" >&2
  case "$cmp_status" in
    identical|behind) return 0 ;;
    *) return 1 ;;
  esac
}

# ------------------------------------------------------------------
# find_closing_commit: uses the closedByPullRequestsReferences
# GraphQL field to find the merge commit of the PR that closed this
# issue. This is more reliable than the REST timeline API's `closed`
# event, which only carries a commit_id for issues closed via
# "Fixes #N" keyword syntax — not for manual closure with a linked
# PR (GitHub's "closed this as completed in #N" UI action).
# Prints the merge commit SHA to stdout if found, empty otherwise.
# ------------------------------------------------------------------
find_closing_commit() {
  local repo="$1" number="$2"
  local owner_part repo_part gql_response commit
  owner_part="${repo%%/*}"
  repo_part="${repo##*/}"
  gql_response=$(gh api graphql \
    -F owner="${owner_part}" \
    -F repo="${repo_part}" \
    -F issue="${number}" \
    -f query='
      query ($owner: String!, $repo: String!, $issue: Int!) {
        repository(owner: $owner, name: $repo) {
          issue(number: $issue) {
            closedByPullRequestsReferences(first: 10) {
              nodes { merged mergeCommit { oid } }
            }
          }
        }
      }')
  commit=$(printf '%s' "$gql_response" | jq -r '[.data.repository.issue.closedByPullRequestsReferences.nodes[] | select(.merged == true) | .mergeCommit.oid] | last // empty')
  if [ -z "$commit" ]; then
    echo "    no merged closing PR found via closedByPullRequestsReferences" >&2
  fi
  echo "$commit"
}

# ----------------------------------------------------------------
# check_github_items: checks state of issues or PRs via REST API.
# item_type: "issue" or "pull"
# Prints one summary line per item to stdout (captured by caller).
# Returns: 0 if ALL items are resolved, 1 otherwise.
#
# BACKLINK PREVENTION:
# - Progress lines go to stderr only (never reach PR body)
# - Summary lines use redirect.github.com instead of github.com —
#   GitHub's documented mechanism for suppressing cross-repo backlinks:
#   docs.github.com/en/get-started/writing-on-github/
#   working-with-advanced-formatting/autolinked-references-and-urls
# - Link text uses plain words, never owner/repo#number syntax
# ----------------------------------------------------------------
check_github_items() {
  local items_json="$1" item_type="$2"
  local all_done=true
  while IFS= read -r item; do
    local repo number state merged merge_commit_sha api_response repo_short landed closing_commit reached_terminal_state
    repo=$(echo "$item" | jq -r '.repo')
    number=$(echo "$item" | jq -r '.number')
    repo_short="${repo##*/}"
    echo "    Checking ${repo} ${item_type} ${number} ..." >&2
    api_response=$(curl -fsSL \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${GH_TOKEN}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/repos/${repo}/${item_type}s/${number}")
    if [ "$item_type" = "pull" ]; then
      merged=$(echo "$api_response" | jq -r '.merged')
      state=$([ "$merged" = "true" ] && echo "merged" || echo "$(echo "$api_response" | jq -r '.state')")
      merge_commit_sha=$(echo "$api_response" | jq -r '.merge_commit_sha // empty')
    else
      state=$(echo "$api_response" | jq -r '.state')
    fi
    echo "    state: ${state}" >&2
    landed=""
    if [ "$item_type" = "pull" ] && [ "$state" = "merged" ] && [ "$repo" = "NixOS/nixpkgs" ] && [ -n "${merge_commit_sha:-}" ]; then
      if check_landed_in_nixpkgs "$merge_commit_sha"; then
        landed="yes"
      else
        landed="no"
      fi
    elif [ "$item_type" = "issue" ] && [ "$state" = "closed" ] && [ "$repo" = "NixOS/nixpkgs" ]; then
      closing_commit=$(find_closing_commit "$repo" "$number")
      if [ -n "$closing_commit" ]; then
        if check_landed_in_nixpkgs "$closing_commit"; then
          landed="yes"
        else
          landed="no"
        fi
      fi
    fi
    # Only append a landed-status suffix when the item has actually
    # reached closed/merged — otherwise the base state alone is the
    # correct, complete signal (nothing to verify yet).
    reached_terminal_state=false
    if [ "$item_type" = "pull" ] && [ "$state" = "merged" ]; then
      reached_terminal_state=true
    elif [ "$item_type" = "issue" ] && [ "$state" = "closed" ]; then
      reached_terminal_state=true
    fi
    # stdout only — this line is captured into REPORT_LINES via $()
    # Uses redirect.github.com (no backlink) and plain link text (no owner/repo#N)
    case "$landed" in
      yes) echo "[${repo_short} ${item_type} ${number}](https://redirect.github.com/${repo}/${item_type}s/${number}): \`${state}\` — landed in locked nixpkgs" ;;
      no)  echo "[${repo_short} ${item_type} ${number}](https://redirect.github.com/${repo}/${item_type}s/${number}): \`${state}\` — NOT yet landed in locked nixpkgs" ;;
      *)
        if [ "$reached_terminal_state" = true ]; then
          echo "[${repo_short} ${item_type} ${number}](https://redirect.github.com/${repo}/${item_type}s/${number}): \`${state}\` — landing status unverified"
        else
          echo "[${repo_short} ${item_type} ${number}](https://redirect.github.com/${repo}/${item_type}s/${number}): \`${state}\`"
        fi
        ;;
    esac
    if [ "$item_type" = "pull" ] && [ "$state" != "merged" ]; then
      all_done=false
    elif [ "$item_type" = "issue" ] && [ "$state" != "closed" ]; then
      all_done=false
    elif [ "$repo" = "NixOS/nixpkgs" ] && [ "$landed" != "yes" ]; then
      all_done=false
    fi
  done < <(echo "$items_json" | jq -c '.[]')
  [ "$all_done" = true ]
}

# ----------------------------------------------------------------
# Main loop — read audit metadata from flake output.
# Uses process substitution throughout to keep OBSOLETE_IDS,
# BROKEN_IDS and REPORT_LINES in the current shell (pipe-into-while
# runs a subshell and would silently discard all accumulated values).
# ----------------------------------------------------------------
echo "Evaluating flake.overlayAudits ..."
AUDIT_JSON=$(nix eval .#overlayAudits --json)

echo "Resolving locked nixpkgs revision ..."
LOCKED_NIXPKGS_REV=$(nix flake metadata --json | jq -r '.locks.nodes.nixpkgs.locked.rev')
echo "Locked nixpkgs rev: ${LOCKED_NIXPKGS_REV}"

# entry_broken is set by ci_liveness_callback (see below) for
# whichever entry is currently being processed by the main loop.
entry_broken=false
ci_liveness_callback() {
  local host_key="$1" id="$2" target_host="$3" eval_attr="$4" result="$5" detail="$6"
  case "$result" in
    fail)
      entry_broken=true
      REPORT_LINES+=("- 🔴 **${host_key} / ${id}** (on \`${target_host}\`): OVERRIDE BROKEN — evaluation fails against current locked nixpkgs, regardless of tracking status")
      REPORT_LINES+=("    \`\`\`")
      REPORT_LINES+=("    ${detail}")
      REPORT_LINES+=("    \`\`\`")
      ;;
    skip)
      REPORT_LINES+=("- ⚠️  **${host_key} / ${id}**: ${detail}")
      ;;
  esac
}

while IFS= read -r host_key; do
  echo ""
  echo "=== ${host_key} ==="

  while IFS= read -r id; do
    entry=$(echo "$AUDIT_JSON" | jq -c --arg h "$host_key" --arg id "$id" '.[$h][$id]')
    strategy=$(echo "$entry" | jq -r '.strategy')
    description=$(echo "$entry" | jq -r '.description')
    notes=$(echo "$entry" | jq -r '.notes // empty')
    echo ""
    echo "  [${id}] ${strategy}: ${description}"

    is_obsolete=false
    case "$strategy" in
      nixpkgs-version)
        attr=$(echo "$entry" | jq -r '.attr // empty')
        # Default attr to <id>.version when not explicitly set
        if [ -z "$attr" ]; then
          attr="${id}.version"
          echo "    attr not set — defaulting to ${attr}"
        fi
        threshold=$(echo "$entry" | jq -r '.threshold')
        all_met=true
        version_lines=()
        while IFS= read -r system; do
          current=""
          rc=0
          current=$(check_nixpkgs_version "$attr" "$threshold" "$system") || rc=$?
          case $rc in
            0) version_lines+=("    - ✅ \`${system}\`: \`${attr} = ${current}\` >= \`${threshold}\`") ;;
            1) version_lines+=("    - ⏳ \`${system}\`: \`${attr} = ${current}\` < \`${threshold}\`")
               all_met=false ;;
            2) version_lines+=("    - ⚠️  \`${system}\`: eval of \`${attr}\` failed — manual check required")
               all_met=false ;;
          esac
        done < <(echo "$entry" | jq -r '.systems[]')
        if [ "$all_met" = true ]; then
          is_obsolete=true
          REPORT_LINES+=("- ✅ **${host_key} / ${id}**: nixpkgs meets threshold \`>= ${threshold}\` on all declared systems")
        else
          REPORT_LINES+=("- ⏳ **${host_key} / ${id}**: threshold \`${threshold}\` not yet reached on all systems")
        fi
        for line in "${version_lines[@]}"; do
          REPORT_LINES+=("$line")
        done
        ;;
      nixpkgs-issue)
        items_json=$(echo "$entry" | jq -c '.trackingIssues')
        issue_output=""
        rc=0
        issue_output=$(check_github_items "$items_json" "issue") || rc=$?
        if [ $rc -eq 0 ]; then
          is_obsolete=true
          REPORT_LINES+=("- ✅ **${host_key} / ${id}**: all tracking issues closed")
        else
          REPORT_LINES+=("- ⏳ **${host_key} / ${id}**: tracking issue(s) still open")
        fi
        while IFS= read -r line; do
          REPORT_LINES+=("    - $line")
        done <<< "$issue_output"
        ;;
      nixpkgs-pr)
        items_json=$(echo "$entry" | jq -c '[.trackingPRs[] | .repo as $r | .numbers[] | {repo: $r, number: .}]')
        pr_output=""
        rc=0
        pr_output=$(check_github_items "$items_json" "pull") || rc=$?
        if [ $rc -eq 0 ]; then
          is_obsolete=true
          REPORT_LINES+=("- ✅ **${host_key} / ${id}**: all tracking PRs merged")
        else
          REPORT_LINES+=("- ⏳ **${host_key} / ${id}**: tracking PR(s) not yet merged")
        fi
        while IFS= read -r line; do
          REPORT_LINES+=("    - $line")
        done <<< "$pr_output"
        ;;
      *)
        echo "  WARNING: unknown strategy '${strategy}'"
        REPORT_LINES+=("- ⚠️  **${host_key} / ${id}**: unknown strategy \`${strategy}\` — update overlay-entries.nix")
        ;;
    esac

    # -- Liveness check: does the override still evaluate at all? --
    # Runs unconditionally, independent of the strategy result above
    # — the underlying tracked problem can be entirely unrelated to
    # why the override itself stopped working. Shared with the
    # pre-commit hook via check_entry_liveness (sourced above).
    entry_broken=false
    check_entry_liveness "$AUDIT_JSON" "$host_key" "$id" ci_liveness_callback
    if [ "$entry_broken" = true ]; then
      BROKEN_IDS+=("${host_key}::${id}")
    fi

    if [ "$is_obsolete" = true ]; then
      OBSOLETE_IDS+=("${host_key}::${id}")
      if [ -n "$notes" ]; then
        REPORT_LINES+=("    - 📎 **Note:** ${notes}")
      fi
    fi

    # Blank line between overlay entries for Markdown paragraph separation
    REPORT_LINES+=("")
  done < <(echo "$AUDIT_JSON" | jq -r --arg h "$host_key" '.[$h] | keys[]')
done < <(echo "$AUDIT_JSON" | jq -r 'keys[]')

# ----------------------------------------------------------------
# Emit outputs
# ----------------------------------------------------------------
echo ""
echo "Obsolete: ${OBSOLETE_IDS[*]:-none}"
echo "Broken: ${BROKEN_IDS[*]:-none}"

REPORT_FILE="$(mktemp)"
printf '%s\n' "${REPORT_LINES[@]}" > "$REPORT_FILE"

{
  echo "obsolete_count=${#OBSOLETE_IDS[@]}"
  echo "obsolete_ids=${OBSOLETE_IDS[*]:-}"
  echo "broken_count=${#BROKEN_IDS[@]}"
  echo "broken_ids=${BROKEN_IDS[*]:-}"
  echo "report_file=${REPORT_FILE}"
} >> "$GITHUB_OUTPUT"
