{ pkgs, nvd-summary }:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  rebuild =
    if isDarwin then
      ''darwin-rebuild build --flake "$CONFIG" --option eval-cache false --show-trace''
    else
      ''nixos-rebuild --flake "$CONFIG" build --option eval-cache false --show-trace'';

  # No exact darwin equivalent of systemd-inhibit's --mode=block/--why semantics;
  # caffeinate -is is the closest analogue (idle + AC-power system sleep, released
  # automatically when the wrapped command exits, exit code passed through).
  inhibit =
    if isDarwin then
      "caffeinate -is"
    else
      ''systemd-inhibit --no-pager --no-legend --mode=block --who="''${USER:-$(id -un)}" --why='NixOS System Building' '';
in
pkgs.writeShellApplication {
  name = "nix-build-system";
  runtimeInputs = [ nvd-summary ];
  text = ''
    CONFIG="''${NIXOS_CONFIG:-$HOME/nixos-config}"
    OUTFILE="$HOME/changes_$(date +%d-%m-%y).out"
    cd "$CONFIG"
    echo "Beginning build. This may take some time."
    echo ""
    ${inhibit} ${rebuild}
    echo ""
    echo "Build complete. Providing result:"
    echo ""
    rm -rf ~/changes_*
    nvd-summary /run/current-system "$CONFIG"/result > "$OUTFILE"
    rm "$CONFIG"/result
    cat "$OUTFILE"
    echo "Result has been stored in $OUTFILE. Finished"
  '';
}
