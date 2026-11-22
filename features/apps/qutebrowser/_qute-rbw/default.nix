# qute-rbw: qutebrowser's Bitwarden login filler (see qute-rbw.py), with
# each OS's own picker and clipboard tools.
{
  lib,
  pkgs,
  rbw,
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  tools =
    if isDarwin then
      {
        picker = [
          (lib.getExe pkgs.choose-gui)
          "-i" # print the chosen line's index
          "-a" # rank matches near the start higher
          "-n"
          "12"
          "-w"
          "50"
          "-p"
          "Bitwarden"
        ];
        clipCopy = [ "/usr/bin/pbcopy" ];
        clipPaste = [ "/usr/bin/pbpaste" ];
        # pbcopy with empty input leaves the clipboard empty
        clipClear = [ "/usr/bin/pbcopy" ];
        onUnlock = [ ];
      }
    else
      {
        picker = [
          (lib.getExe pkgs.fuzzel)
          "--dmenu"
          "--index"
          "--prompt"
          "Bitwarden ❯ "
        ];
        clipCopy = [ "${pkgs.wl-clipboard}/bin/wl-copy" ];
        clipPaste = [
          "${pkgs.wl-clipboard}/bin/wl-paste"
          "--no-newline"
        ];
        clipClear = [
          "${pkgs.wl-clipboard}/bin/wl-copy"
          "--clear"
        ];
        # Refreshes waybar's custom/rbw module (features/desktop/waybar)
        onUnlock = [
          "${pkgs.procps}/bin/pkill"
          "-RTMIN+8"
          "waybar"
        ];
      };

  script =
    builtins.replaceStrings
      [
        "@rbw@"
        "@fillJs@"
        "@picker@"
        "@clipCopy@"
        "@clipPaste@"
        "@clipClear@"
        "@onUnlock@"
      ]
      [
        (lib.getExe rbw)
        "${./fill.js}"
        (builtins.toJSON tools.picker)
        (builtins.toJSON tools.clipCopy)
        (builtins.toJSON tools.clipPaste)
        (builtins.toJSON tools.clipClear)
        (builtins.toJSON tools.onUnlock)
      ]
      (builtins.readFile ./qute-rbw.py);
in
pkgs.writers.writePython3Bin "qute-rbw" {
  libraries = [ pkgs.python3Packages.publicsuffixlist ];
  # Line length is left to the formatter
  flakeIgnore = [ "E501" ];
} script
