# The fonts style.css names: Oxanium for text, Orbitron for the clock and
# workspaces. Shared by the home-manager module and nix run .#waybar-preview.
pkgs:
pkgs.google-fonts.override {
  fonts = [
    "Oxanium"
    "Orbitron"
  ];
}
