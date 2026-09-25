{
  lib,
  inputs,
  ...
}:
let
  username = "rickie";

  # Per-host values handed to every module as the `vars` special arg.
  mkVars =
    system:
    let
      isDarwin = builtins.match ".*-darwin" system != null;
      homePrefix = if isDarwin then "/Users" else "/home";
    in
    {
      inherit username;
      secretsPath = toString inputs.nix-secrets;
      syncthingPath = "${homePrefix}/${username}/Sync";
      age.keyFile =
        if isDarwin then
          "${homePrefix}/${username}/Library/Application Support/sops/age/keys.txt"
        else
          "/var/lib/age/keys.txt";
    };
in
{
  # Hosts register themselves: each hosts/<class>/<host>/default.nix sets
  # infra.hosts.<host> (paths there are relative to that host's directory, and
  # profiles are referenced by name via config.flake.modules).
  options.infra = {
    # Profiles: plain `{ imports = [ … ]; }` modules grouping features, set by
    # profiles/**. Kept as raw values (not flake.modules) on purpose — the
    # module system orders definitions by import depth, and flake.modules'
    # wrapping would nest every feature deeper and reorder merged lists
    # (firewall rules, systemPackages) relative to the host's own modules.
    profiles = lib.mkOption {
      type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.raw);
      default = { };
    };

    hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, config, ... }:
          {
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
                default = name;
              };

              system = lib.mkOption {
                type = lib.types.str;
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
                default = [
                  config.systemModule
                  config.overlaysModule
                ];
              };

              systemProfiles = lib.mkOption {
                type = lib.types.listOf lib.types.raw;
                description = "Profiles, by name: e.g. with config.infra.profiles.nixos; [ nixos desktop ].";
              };

              homeProfiles = lib.mkOption {
                type = lib.types.listOf lib.types.raw;
                default = [ ];
              };

              vars = lib.mkOption {
                type = lib.types.lazyAttrsOf lib.types.anything;
                readOnly = true;
                default = mkVars config.system;
              };
            };
          }
        )
      );
    };
  };

  config = {
    _module.args.infraLib = {
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

    };

  };
}
