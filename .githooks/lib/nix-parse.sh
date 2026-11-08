#!/usr/bin/env bash
# Fails if any tracked .nix file doesn't parse, which includes using a
# variable that isn't in scope: a module that drops `lib` from its
# arguments but still uses it. Neither nixfmt nor statix reports that, and
# it needs no flake inputs, so it runs before anything is evaluated. Names
# inside a `with` are only resolved at evaluation, so those aren't checked.
#
# Used by .githooks/pre-commit (with --cached: checks the staged contents)
# and the CI lint job (checks the checkout).
set -euo pipefail

cached=false
[ "${1:-}" = "--cached" ] && cached=true

failed=0
while IFS= read -r -d '' file; do
  if $cached; then
    # Staged files only, as they'll be committed
    output=$(git show ":$file" | nix-instantiate --parse - 2>&1 >/dev/null) || {
      echo "$file:" >&2
      echo "$output" >&2
      failed=1
    }
  else
    output=$(nix-instantiate --parse "$file" 2>&1 >/dev/null) || {
      echo "$output" >&2
      failed=1
    }
  fi
done < <(if $cached; then git diff --cached -z --name-only --diff-filter=ACMR -- '*.nix'; else git ls-files -z -- '*.nix'; fi)

if [ "$failed" -ne 0 ]; then
  echo "Nix files that don't parse, or use undefined variables, are listed above." >&2
  exit 1
fi
echo "  all Nix files parse ✓"
