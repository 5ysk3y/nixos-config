# Usage: doom-prune-stale-repos <straight repos dir>
#
# Doom clones every straight.el repo shallow and single-branch, so each clone
# fetches only the branch that was the default when it was cloned. When an
# upstream renames or deletes that branch (MELPA and nongnu-elpa moving from
# master to main, for example), `git fetch origin` fails on every sync from
# then on. A fresh clone picks up the current default branch, so this removes
# each clone whose tracked branch is gone and leaves Doom to clone it again.
#
# A clone is removed only when the remote answers that the branch doesn't
# exist (ls-remote --exit-code returns 2), never on a network or auth error.
# Exits 0 if it removed anything, 1 if not, so the caller retries the sync
# only when something changed.

if [ "${1:-}" = "--check" ]; then
  repo=$2
  url=$(git -C "$repo" config --get remote.origin.url) || exit 0
  specs=$(git -C "$repo" config --get-all remote.origin.fetch) || exit 0
  # Single-branch clones have exactly one refspec:
  #   +refs/heads/<branch>:refs/remotes/origin/<branch>
  [ "$(printf '%s\n' "$specs" | wc -l)" -eq 1 ] || exit 0
  src=${specs#+}
  src=${src%%:*}
  case $src in
    refs/heads/*'*'*) exit 0 ;;
    refs/heads/*) branch=${src#refs/heads/} ;;
    *) exit 0 ;;
  esac
  rc=0
  GIT_TERMINAL_PROMPT=0 timeout 30 \
    git ls-remote --exit-code "$url" "refs/heads/$branch" >/dev/null 2>&1 || rc=$?
  if [ "$rc" -eq 2 ]; then
    printf '%s\0' "$repo"
  fi
  exit 0
fi

repos=${1:?usage: doom-prune-stale-repos <straight repos dir>}
[ -d "$repos" ] || exit 1

mapfile -d '' stale < <(
  find "$repos" -mindepth 1 -maxdepth 1 -type d -print0 |
    xargs -0 -r -n 1 -P 16 "$0" --check
)

if [ "${#stale[@]}" -eq 0 ]; then
  exit 1
fi

for repo in "${stale[@]}"; do
  echo "doom: $(basename "$repo") no longer has the branch it tracks upstream; removing it so Doom clones it again"
  rm -rf -- "$repo"
done
