{ lib, config, ... }:
let
  inherit (config.repo) hosts;

  # Read audit.nix from a host's overlays directory if it exists.
  # host.overlaysModule is the directory path (e.g. hosts/gibson/overlays),
  # so we append /audit.nix to get the sibling file.
  readHostAudits =
    host:
    let
      auditFile = host.overlaysModule + "/audit.nix";
    in
    if builtins.pathExists auditFile then import auditFile else { };

  # Aggregate per-host audit metadata across all hosts.
  # Keyed by hostname so the CI script can report which host each overlay belongs to.
  hostAudits = lib.mapAttrs (_name: readHostAudits) hosts;

  # Hook for the system-wide overlay at features/system/core/overlays.nix.
  # This file is imported transitively via systemProfiles and is not reachable
  # through host.overlaysModule. Wire it explicitly here so it gets the same
  # treatment when populated.
  systemAuditFile = ./../../../features/system/core/overlays/audit.nix;
  systemAudits =
    if builtins.pathExists systemAuditFile then
      { "features/system/core/overlays" = import systemAuditFile; }
    else
      { };

in
{
  options.flake.overlayAudits = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.attrsOf (
        lib.types.submodule {
          options = {
            strategy = lib.mkOption {
              type = lib.types.enum [
                "nixpkgs-version"
                "nixpkgs-issue"
                "nixpkgs-pr"
              ];
              description = "Detection strategy for overlay obsolescence.";
            };

            description = lib.mkOption {
              type = lib.types.str;
              description = "Human-readable description of what this overlay does and why.";
            };

            systems = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Systems this overlay applies to. Scopes nix eval to the correct platform.";
            };

            attr = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "nixpkgs legacyPackages attribute path for version eval (nixpkgs-version only).";
            };

            threshold = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Minimum version for the overlay to be considered obsolete (nixpkgs-version only).";
            };

            trackingIssues = lib.mkOption {
              type = lib.types.listOf (
                lib.types.submodule {
                  options = {
                    repo = lib.mkOption { type = lib.types.str; };
                    number = lib.mkOption { type = lib.types.int; };
                  };
                }
              );
              default = [ ];
              description = "GitHub issues that must ALL be closed (nixpkgs-issue only).";
            };

            trackingPRs = lib.mkOption {
              type = lib.types.listOf (
                lib.types.submodule {
                  options = {
                    repo = lib.mkOption { type = lib.types.str; };
                    number = lib.mkOption { type = lib.types.int; };
                  };
                }
              );
              default = [ ];
              description = "GitHub PRs that must ALL be merged (nixpkgs-pr only).";
            };

            notes = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Reviewer notes: coupled removals, related files, context.";
            };
          };
        }
      )
    );
    default = { };
    description = ''
      Audit metadata for temporary overlays, aggregated from each host's
      overlays/audit.nix and features/system/core/overlays/audit.nix.
      Keyed by hostname (or system path), then by overlay id.
      Consumed by the audit-overlays CI workflow via `nix eval .#overlayAudits --json`.
    '';
  };

  config.flake.overlayAudits = hostAudits // systemAudits;
}
