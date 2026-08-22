{ pkgs }:
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
  runtimeInputs = with pkgs; [
    nvd
    gawk
    gnused
  ];
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
    nvd diff /run/current-system "$CONFIG"/result > "$OUTFILE"
    #Cleanup
    awk -i inplace '{$0=gensub(/\s*\S+/,"",2)}1' "$OUTFILE"
    sed -i -e '1,2d' -e 's/Version/Changed\/Updated:/g' -e 's/Added/\nAdded:/g' -e 's/Removed/\nRemoved:/g' -e '$d' "$OUTFILE"
    rm "$CONFIG"/result
    cat "$OUTFILE"
    echo "Result has been stored in $OUTFILE. Finished"
  '';
}
