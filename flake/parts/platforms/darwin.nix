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
    inputs.nix-darwin.lib.darwinSystem {
      inherit (host) system;

      specialArgs = {
        inherit inputs;
        inherit (host) hostname system vars;
      };

      modules =
        host.systemProfiles
        ++ host.modules
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
