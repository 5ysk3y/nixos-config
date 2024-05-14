{ pkgs }:

pkgs.writeShellApplication {
    name = "check_rbw";
    runtimeInputs = with pkgs; [ rbw coreutils ];
    text = ''
if ! rbw unlocked 2>/dev/null
then
    echo ""
else
    echo ""
fi
    '';
}
