{
  config,
  inputs,
  infraLib,
  ...
}:
let
  inherit (config.infra) hosts;

  mkDarwinHost =
    host:
    let
      packages = infraLib.pkgsFor host.system;
    in
    inputs.nix-darwin.lib.darwinSystem {
      inherit (host) system;

      specialArgs = {
        inherit inputs;
        inherit (host) hostname system vars;
        inherit (packages) pkgs-stable;
      };

      modules =
        host.systemProfiles
        ++ host.modules
        ++ [ { nixpkgs.config.allowUnfree = true; } ]
        ++ [
          inputs.sops-nix.darwinModules.sops
        ]
        ++ infraLib.mkHomeManagerModule {
          platformModule = inputs.home-manager.darwinModules.home-manager;
          inherit host;
          hmExtra = {
            backupFileExtension = "before-nix";
          };
          extraSpecialArgs = {
            inherit (packages) pkgs-stable;
          };
        };
    };

  darwinHosts = infraLib.filterHosts "darwin" hosts;
in
{
  flake.darwinConfigurations = infraLib.mapHosts mkDarwinHost darwinHosts;
}
