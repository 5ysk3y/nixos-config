{
  lib,
  inputs,
  ...
}:
let
  username = "rickie";
  mkVars = (import ../../lib/mk-vars.nix).perHost;
in
{
  options.repo = {
    hosts = lib.mkOption {
      readOnly = true;
      type = lib.types.attrsOf (
        lib.types.submodule (_: {
          options = {
            kind = lib.mkOption {
              type = lib.types.enum [
                "nixos"
                "darwin"
              ];
            };

            hostname = lib.mkOption {
              type = lib.types.str;
            };

            system = lib.mkOption {
              type = lib.types.str;
            };

            path = lib.mkOption {
              type = lib.types.path;
            };

            systemModule = lib.mkOption {
              type = lib.types.path;
            };

            homeModule = lib.mkOption {
              type = lib.types.path;
            };

            overlaysModule = lib.mkOption {
              type = lib.types.path;
            };

            modules = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              readOnly = true;
            };

            systemProfiles = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              readOnly = true;
            };

            homeProfiles = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              readOnly = true;
            };

            vars = lib.mkOption {
              type = lib.types.lazyAttrsOf lib.types.anything;
              readOnly = true;
            };
          };
        })
      );
    };
  };

  config = {
    _module.args.repoLib = {
      # pkgsFor provides supplementary package sets passed as specialArgs.
      # pkgs-stable: for packages that need pinning against the stable channel.
      # Add further sets here if a new supplementary channel input is introduced.
      pkgsFor = system: {
        pkgs-stable = import inputs.nixpkgs-stable {
          inherit system;
          config.allowUnfree = true;
        };
      };

      filterHosts = kind: hosts: lib.filterAttrs (_: v: v.kind == kind) hosts;
      mapHosts = f: hosts: lib.mapAttrs (_: f) hosts;

      mkHomeManagerModule =
        {
          platformModule,
          host,
          extraSpecialArgs ? { },
          hmExtra ? { },
        }:
        [
          platformModule
          {
            home-manager = {
              extraSpecialArgs = {
                inherit inputs;
                inherit (host) hostname vars;
              }
              // extraSpecialArgs;

              useGlobalPkgs = true;
              useUserPackages = true;

              sharedModules = [
                inputs.sops-nix.homeManagerModules.sops
                # Primary nixpkgs is nixos-unstable; home-manager tracks master
                # which matches unstable. The version mismatch warning fires as a
                # false positive because pkgs-stable (26.05) is also in scope.
                # Suppressing here rather than per-host since it applies globally.
                { home.enableNixpkgsReleaseCheck = false; }
              ];

              users.${host.vars.username} = {
                imports = host.homeProfiles ++ [
                  host.homeModule
                ];
              };
            }
            // hmExtra;
          }
        ];
    };

    repo.hosts = import ../../hosts {
      inherit
        inputs
        mkVars
        username
        ;
    };
  };
}
