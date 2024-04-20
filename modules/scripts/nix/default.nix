{ pkgs }:

pkgs.writeShellApplication {
    name = "queryUpdates";
    runtimeInputs = with pkgs; [ coreutils findutils ];
    text = ''
HM_LAST=$(find /home/rickie/.local/state/nix/profiles/ -type d -o -type l 2>/dev/null | sort -h | tail -2 | head -1)
HM_CURRENT="/home/rickie/.local/state/nix/profiles/home-manager"

SYSTEM_LAST=$(find /nix/var/nix/profiles/ -type d -o -type l 2>/dev/null | sort -h | tail -2 | head -1)
SYSTEM_CURRENT="/nix/var/nix/profiles/system"

echo "Updated system pkgs from the last rebuild:"
echo ""
nix store diff-closures "$SYSTEM_LAST" "$SYSTEM_CURRENT"
echo ""
echo "Updated home-manager pkgs from the last rebuild:"
echo ""
nix store diff-closures "$HM_LAST" "$HM_CURRENT"
    '';
}
