{
  config,
  inputs,
  repoLib,
  ...
}:
let
  inherit (config.repo) hosts;

  mkDarwinHost =
    host:
    let
      packages = repoLib.pkgsFor host.system;
    in
    inputs.nix-darwin.lib.darwinSystem {
      inherit (host) system;

      specialArgs = {
        inherit inputs;
        inherit (host) hostname system vars;
        inherit (packages) pkgs-darwin;
      };

      modules =
        host.modules
        ++ repoLib.mkHomeManagerModule {
          platformModule = inputs.home-manager.darwinModules.home-manager;
          inherit host;
          hmExtra = {
            backupFileExtension = "before-nix";
          };
        };
    };

  darwinHosts = repoLib.filterHosts "darwin" hosts;
in
{
  flake.darwinConfigurations = repoLib.mapHosts mkDarwinHost darwinHosts;
}
