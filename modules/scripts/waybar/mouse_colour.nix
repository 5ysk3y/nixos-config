{ pkgs }:

pkgs.writeShellApplication {
    name = "mouse_colour";
    runtimeInputs = with pkgs; [ rivalcfg ];
    text = ''
rivalcfg d reactive -a 0000ff --top-color 0000ff --middle-color 0000ff --bottom-color 0000ff -s 800 -t 0 -T 1
    '';
}
