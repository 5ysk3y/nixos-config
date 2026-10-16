{ inputs, ... }:
{
  # The home module installs pkgs.xivlauncher-rb, which this repo's own
  # overlay provides. Applied here, at system level, because with
  # home-manager.useGlobalPkgs an overlay set in a Home Manager module has
  # no effect.
  nixpkgs.overlays = [ inputs.self.overlays.default ];

  hardware.xone.enable = true;

  programs = {
    dconf.enable = true;
    gamescope.enable = true;
    steam.enable = true;

    gamemode = {
      enable = true;
      enableRenice = true;
    };
  };
}
