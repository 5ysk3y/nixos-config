# The fonts style.css names: Oxanium for text, Orbitron for the clock and
# workspaces, and Neon Mono (monospaced Oxanium) for the scrolling media
# title. Shared by the home-manager module and nix run .#waybar-preview.
pkgs:
pkgs.symlinkJoin {
  name = "waybar-theme-fonts";
  paths = [
    (pkgs.google-fonts.override {
      fonts = [
        "Oxanium"
        "Orbitron"
      ];
    })
    (import ./_neon-mono.nix pkgs)
  ];
}
