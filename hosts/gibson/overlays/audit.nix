# Audit metadata for temporary overlays — managed by flake/parts/exports/overlay-audits.nix
# Do not use owner/repo#number syntax anywhere in this file — see audit-overlays.yaml for why.
#
{
  bitwarden-desktop = {
    description = "Override electron_39 with electron_39-bin to unblock bitwarden-desktop build";
    notes = "Also remove permittedInsecurePackages entry from hosts/gibson/system.nix.";
    strategy = "nixpkgs-issue";
    systems = [ "x86_64-linux" ];
    trackingIssues = [
      {
        number = 526914;
        repo = "NixOS/nixpkgs";
      }
    ];
  };

  hyprland = {
    attr = "hyprland.version";
    description = "Pin hyprland to 0.55.4 while nixpkgs-unstable propagates via Hydra";
    notes = "xdg-desktop-portal-hyprland override is a coupled removal — remove both blocks together.";
    strategy = "nixpkgs-version";
    systems = [ "x86_64-linux" ];
    threshold = "0.55.4";
  };

  mpv-unwrapped = {
    attr = "mpv-unwrapped.version";
    description = "Backport fence-sync fix milestoned for mpv 0.42.0";
    notes = "mpv override is a coupled removal — remove both blocks together.";
    strategy = "nixpkgs-version";
    systems = [ "x86_64-linux" ];
    threshold = "0.42.0";
  };

  waybar = {
    attr = "waybar.version";
    description = "Pin waybar to git-0594574 pending next tagged release";
    notes = "Also remove waybar-patched flake input from flake.nix. Release cadence has been strictly minor bumps since 0.11.0.";
    strategy = "nixpkgs-version";
    systems = [ "x86_64-linux" ];
    threshold = "0.16.0";
  };

}
