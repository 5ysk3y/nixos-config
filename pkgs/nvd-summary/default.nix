{ pkgs }:
# `nvd diff` between two system closures, tidied for reading and pasting:
# section headings renamed, nvd's #NN index column dropped, and (unless
# --all) [C] lines hidden when only the number of copies of each version
# changed, e.g. `bash 5.3p20 x3 -> 5.3p20 x2`. Shared by nix-build-system
# and the full-build CI job, so both print the same thing.
pkgs.writeShellApplication {
  name = "nvd-summary";
  runtimeInputs = with pkgs; [
    nvd
    gawk
  ];
  text = ''
    all=0
    if [ "''${1:-}" = "--all" ]; then
      all=1
      shift
    fi
    if [ "$#" -ne 2 ]; then
      echo "usage: nvd-summary [--all] OLD NEW" >&2
      exit 2
    fi

    nvd --color never diff "$1" "$2" | gawk -v all="$all" '
      # The distinct versions on one side of " -> ", ignoring " xN" counts
      function versions(side, set,   n, parts, i, v) {
        delete set
        n = split(side, parts, /, /)
        for (i = 1; i <= n; i++) {
          v = parts[i]
          sub(/ x[0-9]+$/, "", v)
          set[v] = 1
        }
      }
      function same(a, b,   k) {
        for (k in a) if (!(k in b)) return 0
        for (k in b) if (!(k in a)) return 0
        return 1
      }
      # Section headings are held back until a line under them is printed,
      # so a section whose lines were all hidden disappears with them
      function emit(line) {
        if (pending != "") {
          if (printed) print ""
          print pending
          pending = ""
        }
        print line
        printed = 1
      }

      /^(<<<|>>>) / { next }
      /^Version changes:$/          { pending = "Changed/Updated:"; next }
      /^Selection state changes:$/  { pending = "Selection changes:"; next }
      /^Added packages:$/           { pending = "Added:"; next }
      /^Removed packages:$/         { pending = "Removed:"; next }
      /^Closure size: / {
        closure = $0
        next
      }
      /^\[[A-Z].\] +#[0-9]+ / {
        $0 = gensub(/^(\[[A-Z].\]) +#[0-9]+/, "\\1", 1)
        if (!all && substr($0, 2, 1) == "C") {
          body = $0
          sub(/^\[C.\] +[^ ]+ +/, "", body)
          if (split(body, sides, / -> /) == 2) {
            versions(sides[1], left)
            versions(sides[2], right)
            if (same(left, right)) {
              hidden++
              next
            }
          }
        }
        emit($0)
        next
      }
      { emit($0) }

      END {
        if (closure != "") {
          if (printed) print ""
          print closure
        }
        if (hidden) {
          printf "%d changes where only the number of copies changed are hidden (--all shows them).\n", hidden
        }
      }
    '
  '';
}
