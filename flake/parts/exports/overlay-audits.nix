{ lib, config, ... }:
let
  inherit (config.repo) hosts;

  # Validate strategy-specific required fields at eval time.
  # This means `nix eval .#overlayAudits` fails loudly with a clear message
  # if an audit.nix entry is structurally wrong, rather than silently producing
  # a bad result that only surfaces when CI runs.
  validateEntry =
    hostKey: id: entry:
    let
      inherit (entry) strategy;
      loc = "${hostKey} / ${id}";

      assertVersionFields = lib.assertMsg (
        entry.threshold != null
      ) "overlayAudits: ${loc} uses nixpkgs-version but is missing required field 'threshold'";

      assertIssueFields = lib.assertMsg (
        entry.trackingIssues != [ ]
      ) "overlayAudits: ${loc} uses nixpkgs-issue but 'trackingIssues' is empty";

      assertPRFields = lib.assertMsg (
        entry.trackingPRs != [ ]
      ) "overlayAudits: ${loc} uses nixpkgs-pr but 'trackingPRs' is empty";

      valid =
        if strategy == "nixpkgs-version" then
          assertVersionFields
        else if strategy == "nixpkgs-issue" then
          assertIssueFields
        else if strategy == "nixpkgs-pr" then
          assertPRFields
        else
          true;
    in
    assert valid;
    entry;

  # Read audit.nix from a host's overlays directory if it exists.
  # host.overlaysModule is the directory path (e.g. hosts/gibson/overlays),
  # so we append /audit.nix to get the sibling file.
  readHostAudits =
    hostKey: host:
    let
      auditFile = host.overlaysModule + "/audit.nix";
      raw = if builtins.pathExists auditFile then import auditFile else { };
    in
    lib.mapAttrs (id: entry: validateEntry hostKey id entry) raw;

  # Aggregate per-host audit metadata across all hosts.
  # Keyed by hostname so the CI script can report which host each overlay belongs to.
  hostAudits = lib.mapAttrs readHostAudits hosts;

  # Hook for the system-wide overlay at features/system/core/overlays.nix.
  # This file is imported transitively via systemProfiles and is not reachable
  # through host.overlaysModule. Wire it explicitly here so it gets the same
  # treatment when populated.
  systemAuditFile = ./../../../features/system/core/overlays/audit.nix;
  systemAudits =
    if builtins.pathExists systemAuditFile then
      let
        raw = import systemAuditFile;
      in
      {
        "features/system/core/overlays" = lib.mapAttrs (id: entry: validateEntry "system" id entry) raw;
      }
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
              description = ''
                nixpkgs legacyPackages attribute path for version eval (nixpkgs-version only).
                Defaults to <id>.version if unset — only specify when non-standard
                (e.g. linuxPackages.nvidiaPackages.new_feature.version).
              '';
            };

            threshold = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Minimum version to consider overlay obsolete (nixpkgs-version only).";
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
