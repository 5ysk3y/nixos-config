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
                "nixos-minimal" # No home-manager/secrets/yubikey config
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
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = "Not required for kind = \"nixos-minimal\" — those hosts get no Home Manager module at all.";
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
              default = [ ];
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

      # `kinds` may be a single kind string or a list of kinds (e.g. both
      # "nixos" and "nixos-minimal" build through the same nixosSystem path).
      filterHosts =
        kinds: hosts:
        let
          kindList = if builtins.isList kinds then kinds else [ kinds ];
        in
        lib.filterAttrs (_: v: builtins.elem v.kind kindList) hosts;
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
                {
                  home.enableNixpkgsReleaseCheck = false;
                  stylix.overlays.enable = lib.mkForce false;
                }
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

      mkResticBackup =
        {
          paths,
          repository,
          passwordFile,
          backupPrepareCommand ? null,
          extraOptions ? [ ],
          timerConfig ? {
            OnCalendar = "03:00";
          },
          pruneOpts ? [
            "--keep-daily 7"
            "--keep-weekly 4"
            "--keep-monthly 6"
          ],
        }:
        {
          inherit
            paths
            repository
            passwordFile
            extraOptions
            timerConfig
            pruneOpts
            ;
        }
        // lib.optionalAttrs (backupPrepareCommand != null) { inherit backupPrepareCommand; };
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
