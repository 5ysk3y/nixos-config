{
  config,
  inputs,
  repoLib,
  ...
}:
let
  inherit (config.repo) hosts;

  mkNixosHost =
    host:
    let
      packages = repoLib.pkgsFor host.system;
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit (host) system;

      specialArgs = {
        inherit inputs;
        inherit (host) hostname system vars;
        inherit (packages) pkgs-stable pkgs-old;
      };

      modules =
        host.modules
        ++ [
          inputs.sops-nix.nixosModules.sops
        ]
        ++ repoLib.mkHomeManagerModule {
          platformModule = inputs.home-manager.nixosModules.home-manager;
          inherit host;
          extraSpecialArgs = {
            inherit (packages) pkgs-stable pkgs-old;
          };
        };
    };

  nixosHosts = repoLib.filterHosts "nixos" hosts;
in
{
  flake.nixosConfigurations = repoLib.mapHosts mkNixosHost nixosHosts;
}
