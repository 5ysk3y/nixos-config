{
  config,
  lib,
  inputs,
  infraLib,
  ...
}:
let
  inherit (config.infra) hosts;

  mkNixosHost =
    host:
    let
      packages = infraLib.pkgsFor host.system;
      # kind = "nixos-minimal" hosts get neither sops-nix nor Home Manager —
      # see flake/parts/hosts/registry.nix for why this is a distinct kind
      # rather than a per-host toggle.
      hasSecretsAndHome = host.kind == "nixos";
    in
    inputs.nixpkgs.lib.nixosSystem {
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
        ++ lib.optionals hasSecretsAndHome [
          inputs.sops-nix.nixosModules.sops
        ]
        ++ lib.optionals hasSecretsAndHome (
          infraLib.mkHomeManagerModule {
            platformModule = inputs.home-manager.nixosModules.home-manager;
            inherit host;
            hmExtra = {
              backupFileExtension = "before-nix";
            };
            extraSpecialArgs = {
              inherit (packages) pkgs-stable;
            };
          }
        );
    };

  nixosHosts = infraLib.filterHosts [ "nixos" "nixos-minimal" ] hosts;
in
{
  flake.nixosConfigurations = infraLib.mapHosts mkNixosHost nixosHosts;
}
