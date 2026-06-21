# Audit metadata for temporary overlays in hosts/gibson/overlays/default.nix.
# Each key must match the overlay identifier used in default.nix.
# Read by flake/parts/exports/overlay-audits.nix and consumed by the
# audit-overlays CI workflow. See flake.overlayAudits for option definitions.
{
  hyprland = {
    strategy = "nixpkgs-version";
    description = "Pin hyprland to 0.55.4 while nixpkgs-unstable propagates via Hydra";
    systems = [ "x86_64-linux" ];
    attr = "hyprland.version";
    threshold = "0.55.4";
    notes = "xdg-desktop-portal-hyprland override is a coupled removal — remove both blocks together.";
  };

  mpv-unwrapped = {
    strategy = "nixpkgs-version";
    description = "Backport fence-sync fix (mpv-player/mpv#17303), milestoned for mpv 0.42.0";
    systems = [ "x86_64-linux" ];
    attr = "mpv-unwrapped.version";
    threshold = "0.42.0";
    notes = "mpv override is a coupled removal — remove both blocks together.";
  };

  waybar = {
    strategy = "nixpkgs-version";
    description = "Pin waybar to git-0594574 (Alexays/Waybar#5013 merged) pending next tagged release";
    systems = [ "x86_64-linux" ];
    attr = "waybar.version";
    threshold = "0.16.0";
    notes = "Also remove waybar-patched flake input from flake.nix. Release cadence has been strictly minor bumps since 0.11.0.";
  };

  nvidia-modprobe = {
    strategy = "nixpkgs-version";
    description = "Keep nvidia-modprobe in sync with pinned driver 610.43.02 (NixOS/nixpkgs#524509)";
    systems = [ "x86_64-linux" ];
    attr = "linuxPackages.nvidiaPackages.new_feature.version";
    threshold = "610.43.02";
    notes = "COUPLED REMOVAL: hosts/gibson/hardware-configuration.nix mkDriver block for nvidia610 must also be removed. Both pin driver version 610.43.02.";
  };

  bitwarden-desktop = {
    strategy = "nixpkgs-issue";
    description = "Override electron_39 with electron_39-bin to unblock bitwarden-desktop build";
    systems = [ "x86_64-linux" ];
    trackingIssues = [
      {
        repo = "NixOS/nixpkgs";
        number = 526914;
      }
    ];
    notes = "Also remove permittedInsecurePackages entry from hosts/gibson/system.nix.";
  };

  lutris = {
    strategy = "nixpkgs-issue";
    description = "Disable openldap doCheck inside lutris FHS env to unblock builds";
    systems = [ "x86_64-linux" ];
    trackingIssues = [
      {
        repo = "NixOS/nixpkgs";
        number = 513245;
      }
      {
        repo = "NixOS/nixpkgs";
        number = 514113;
      }
    ];
    notes = "Both issues must be closed before removing this overlay.";
  };
}
