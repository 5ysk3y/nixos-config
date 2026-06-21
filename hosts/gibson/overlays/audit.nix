# Audit metadata for temporary overlays — managed by flake/parts/exports/overlay-audits.nix
# Do not use owner/repo#number syntax anywhere in this file — see audit-overlays.yaml for why.
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

  lutris = {
    description = "Disable openldap doCheck inside lutris FHS env to unblock builds";
    notes = "Both issues must be closed before removing this overlay.";
    strategy = "nixpkgs-issue";
    systems = [ "x86_64-linux" ];
    trackingIssues = [
      {
        number = 513245;
        repo = "NixOS/nixpkgs";
      }
      {
        number = 514113;
        repo = "NixOS/nixpkgs";
      }
    ];
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

  nvidia-modprobe = {
    strategy = "nixpkgs-version";
    description = "Keep nvidia-modprobe in sync with pinned driver 610.43.02";
    systems = [ "x86_64-linux" ];
    attr = "linuxPackages.nvidiaPackages.new_feature.version";
    threshold = "610.43.02";
    notes = "COUPLED REMOVAL: hosts/gibson/hardware-configuration.nix mkDriver block for nvidia610 must also be removed. Both pin driver version 610.43.02.";
  };

}
