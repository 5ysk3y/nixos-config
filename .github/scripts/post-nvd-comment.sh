#!/usr/bin/env bash
# Posts (or updates in place) one PR comment with each host's nvd-summary
# output, as written by .github/actions/nvd-diff, and puts the unfiltered
# diffs in the job summary.
#
# Usage: post-nvd-comment.sh DIR
# Env:   GH_TOKEN REPO PR BASE_SHA RUN_URL HOSTS (space-separated, in order)
set -euo pipefail

dir=$1
: "${GH_TOKEN:?}" "${REPO:?}" "${PR:?}" "${BASE_SHA:?}" "${RUN_URL:?}" "${HOSTS:?}"
marker='<!-- nvd-diff -->'
# GitHub rejects comment bodies over 65536 characters; leave room for the
# headings and notes around the diffs.
budget=60000

count() { grep -c "^\[$1" "$2" || true; }

summary_line() {
  local f=$1
  printf '%s updated, %s downgraded, %s changed, %s added, %s removed' \
    "$(count U "$f")" "$(count D "$f")" "$(count C "$f")" \
    "$(count A "$f")" "$(count R "$f")"
}

read -r -a host_list <<<"$HOSTS"
present=()
for h in "${host_list[@]}"; do
  [ -f "$dir/$h.txt" ] && present+=("$h")
done
if [ "${#present[@]}" -eq 0 ]; then
  echo "No nvd diffs to post"
  exit 0
fi
per_host=$((budget / ${#present[@]}))

body=$(mktemp)
{
  echo "$marker"
  echo "### Package changes against \`main\` (\`${BASE_SHA:0:7}\`)"
  echo
  first=1
  for h in "${host_list[@]}"; do
    [ "$first" -eq 1 ] || echo '***'
    first=0
    if [ ! -f "$dir/$h.txt" ]; then
      echo "_No diff for \`$h\`: its build or diff step failed, see the [run]($RUN_URL)._"
      echo
      continue
    fi
    diff_text=$(cat "$dir/$h.txt")
    if [ "${#diff_text}" -gt "$per_host" ]; then
      # Cut at a line boundary rather than mid-line
      diff_text=$(head -c "$per_host" <<<"$diff_text" | sed '$d')
      diff_text+=$'\n'"… cut to fit the comment; the full diff is in the run summary."
    fi
    echo "<details>"
    echo "<summary><code>$(cat "$dir/$h.label")</code>: $(summary_line "$dir/$h.txt")</summary>"
    echo
    echo '```'
    printf '%s\n' "$diff_text"
    echo '```'
    echo
    echo "</details>"
    echo
  done
  echo "<sub>Changes where only the number of copies changed are hidden. Unfiltered diffs: [run summary]($RUN_URL).</sub>"
} >"$body"

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  for h in "${present[@]}"; do
    {
      echo "### $(cat "$dir/$h.label")"
      echo '```'
      cat "$dir/$h-full.txt"
      echo '```'
    } >>"$GITHUB_STEP_SUMMARY"
  done
fi

existing=$(gh api "repos/$REPO/issues/$PR/comments" --paginate \
  --jq ".[] | select(.user.login == \"github-actions[bot]\" and (.body | startswith(\"$marker\"))) | .id" |
  head -n 1)
if [ -n "$existing" ]; then
  gh api -X PATCH "repos/$REPO/issues/comments/$existing" -F "body=@$body" >/dev/null
  echo "Updated comment $existing"
else
  gh api -X POST "repos/$REPO/issues/$PR/comments" -F "body=@$body" >/dev/null
  echo "Posted a new comment"
fi
