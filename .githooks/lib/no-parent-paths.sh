#!/usr/bin/env bash
# Fails if any tracked .nix file references a parent directory ("../").
# Modules, profiles and hosts are referenced by name (config.flake.modules,
# infra.hosts) and flake.nix is the only place top-level directories are named,
# so the tree can be reorganised without breaking the wiring. Paths within a
# directory ("./foo") are fine — they move with it.
#
# Used by .githooks/pre-commit (with --cached: checks what's being committed)
# and the CI lint job (checks the checkout). Extra args go to `git grep`.
set -euo pipefail

if matches=$(git grep -n -F "$@" '../' -- '*.nix'); then
  echo "Parent-directory (../) paths found in Nix files — reference the module/profile/host by name instead:" >&2
  echo "$matches" >&2
  exit 1
fi
echo "  no ../ paths in Nix files ✓"
