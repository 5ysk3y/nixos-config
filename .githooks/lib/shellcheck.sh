#!/usr/bin/env bash
# Runs shellcheck on every tracked shell script: *.sh files, and anything
# else whose first line is a bash or sh shebang (the git hooks). Scripts
# that are only sourced carry a `# shellcheck shell=bash` line instead of a
# shebang. Shell embedded in Nix strings isn't covered here.
# writeShellApplication already runs shellcheck on those when it builds.
#
# Used by .githooks/pre-commit (with --cached: checks the staged scripts)
# and the CI lint job (checks the checkout).
set -euo pipefail

cached=false
[ "${1:-}" = "--cached" ] && cached=true

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

# Prints the first line of a tracked file, staged or checked out
first_line() {
  if $cached; then git show ":$1" | head -n 1; else head -n 1 -- "$1"; fi
}

is_shell() {
  case "$1" in
    *.sh) return 0 ;;
  esac
  first_line "$1" | grep -qE '^#!.*[/ ](ba)?sh([[:space:]]|$)'
}

scripts=()
while IFS= read -r -d '' f; do
  is_shell "$f" && scripts+=("$f")
done < <(if $cached; then git diff --cached -z --name-only --diff-filter=ACMR; else git ls-files -z; fi)

if (( ${#scripts[@]} == 0 )); then
  echo "  no shell scripts to check"
  exit 0
fi

# -x with SCRIPTDIR lets `source` lines resolve relative to each script
args=(-x --source-path=SCRIPTDIR)

if $cached; then
  # Lint the staged contents. Every tracked file is copied from the index
  # into a mirror of the repo, so a staged script can still follow a
  # `source` of one that isn't staged.
  mirror=$(mktemp -d "${TMPDIR:-/tmp}/shellcheck.XXXXXX")
  trap 'rm -rf "$mirror"' EXIT
  git checkout-index -a --prefix="$mirror/"
  cd "$mirror"
fi

if nix run --inputs-from "$repo_root" nixpkgs#shellcheck -- "${args[@]}" "${scripts[@]}"; then
  echo "  all shell scripts pass shellcheck ✓"
else
  echo "Fix the shellcheck findings above, or add a" >&2
  echo "'# shellcheck disable=SCxxxx' line saying why the code is right." >&2
  exit 1
fi
