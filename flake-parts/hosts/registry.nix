{
  lib,
  inputs,
  nixpkgsConfig,
  ...
}:
let
  username = "rickie";

  # Whether a nixpkgs-version entry's package has reached its threshold in
  # `prev`. Reads the same attribute the audit script checks (meta.attr,
  # else <id>.version), so the two agree on when an entry is obsolete.
  # Returns null for entries that can't retire themselves.
  versionRetired =
    e:
    if (e.meta.strategy or null) == "nixpkgs-version" then
      prev:
      let
        attr = if (e.meta.attr or null) != null then e.meta.attr else "${e.id}.version";
        current = lib.getAttrFromPath (lib.splitString "." attr) prev;
      in
      lib.versionAtLeast current e.meta.threshold
    else
      null;

  # A nixpkgs-version entry stops applying once nixpkgs reaches its
  # threshold, so a weekly flake.lock bump that ships the fix doesn't fail on
  # an override it no longer needs (a backported patch that no longer
  # applies, say). The audit still flags the entry as obsolete, and a warning
  # names it on every eval, until it's removed. An exempt entry with
  # `coupledTo = "<id>"` retires with that entry.
  #
  # The gate works per attribute: the attribute names stay whatever the
  # entry's overlay returns, and only their values switch back to `prev`.
  # Choosing between `{ }` and the overlay would make the fixed point's
  # attribute names depend on a package's version, which recurses.
  gateTracked =
    tracked:
    let
      byId = lib.listToAttrs (map (e: lib.nameValuePair e.id e) tracked);
      gate =
        e:
        let
          owner = if e ? coupledTo then byId.${e.coupledTo} else e;
          retired = versionRetired owner;
        in
        if retired == null then
          e.overlay
        else
          final: prev:
          let
            isRetired = retired prev;
          in
          lib.mapAttrs (
            name: value:
            if isRetired then
              lib.warn
                "overlay ${e.id}: nixpkgs has reached ${owner.meta.threshold}, so it no longer applies; remove it"
                prev.${name}
            else
              value
          ) (e.overlay final prev);
    in
    map gate tracked;

  # Applies an overlay-entries.nix: its permanent overlay, then every tracked
  # one, in order. Shared through infraLib with the features that own
  # overlay entries (core/system/overlays, apps/claude-desktop).
  overlaysModule =
    entriesFile:
    let
      entries = import entriesFile { inherit inputs; };
    in
    {
      _file = entriesFile;
      nixpkgs.overlays = [ entries.permanent ] ++ gateTracked entries.tracked;
    };

  # Per-host values handed to every module as the `vars` special arg.
  mkVars =
    system:
    let
      isDarwin = builtins.match ".*-darwin" system != null;
      homeDirectory = "${if isDarwin then "/Users" else "/home"}/${username}";
    in
    {
      inherit username homeDirectory;
      secretsPath = toString inputs.nix-secrets;
      syncthingPath = "${homeDirectory}/Sync";
      # Where this repo is cloned. bootstrap/README.md clones to the same
      # place — keep the two in step.
      configDir = "${homeDirectory}/nixos-config";
      age.keyFile =
        if isDarwin then
          "${homeDirectory}/Library/Application Support/sops/age/keys.txt"
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

              overlayEntries = lib.mkOption {
                type = lib.types.nullOr lib.types.path;
                default = null;
                description = ''
                  The host's overlay-entries.nix: its permanent overlay and its
                  tracked, audited ones (see flake-parts/exports/overlay-audits.nix).
                  Applied to the host's nixpkgs by the module below; null if the
                  host has none.
                '';
              };

              modules = lib.mkOption {
                type = lib.types.listOf lib.types.raw;
                readOnly = true;
                default = [
                  config.systemModule
                ]
                ++ lib.optional (config.overlayEntries != null) (overlaysModule config.overlayEntries);
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
      inherit overlaysModule;

      # pkgsFor provides supplementary package sets passed as specialArgs.
      # pkgs-stable: for packages that need pinning against the stable channel.
      # Add further sets here if a new supplementary channel input is introduced.
      pkgsFor = system: {
        pkgs-stable = import inputs.nixpkgs-stable {
          inherit system;
          config = nixpkgsConfig;
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
