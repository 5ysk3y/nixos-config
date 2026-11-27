# Neon Mono: a monospaced copy of Oxanium, for Waybar's scrolling media
# title (see _neon-mono.py). Installed by _theme-fonts.nix.
#
# A modified font stays under Oxanium's SIL Open Font License 1.1, and
# each copy must carry the copyright notice and license. The font keeps
# them in its metadata, and OFL.txt ships beside it.
pkgs:
let
  oxanium = pkgs.google-fonts.override { fonts = [ "Oxanium" ]; };
  python = pkgs.python3.withPackages (ps: [ ps.fonttools ]);
in
pkgs.runCommand "neon-mono"
  {
    nativeBuildInputs = [ python ];
    meta.license = pkgs.lib.licenses.ofl;
  }
  ''
    mkdir -p $out/share/fonts/truetype $out/share/doc/neon-mono
    python3 ${./_neon-mono.py} \
      '${oxanium}/share/fonts/truetype/Oxanium[wght].ttf' \
      $out/share/fonts/truetype/NeonMono-Regular.ttf
    cp ${oxanium.src}/ofl/oxanium/OFL.txt $out/share/doc/neon-mono/OFL.txt
  ''
