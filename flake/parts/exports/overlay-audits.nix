{
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (config.repo) hosts;

  # Validate strategy-specific required fields at eval time.
  # This means `nix eval .#overlayAudits` fails loudly with a clear message
  # if an audit entry is structurally wrong, rather than silently producing
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

  # Every entry in an overlay-entries.nix `tracked` list must declare either
  # `exempt = true` (a conscious, visible opt-out) or `meta` (real audit
  # metadata). Without this assertion, an entry with neither would still
  # apply its override completely normally via default.nix's composition —
  # it just wouldn't show up in flake.overlayAudits at all, silently
  # invisible to both the liveness check and CI. This is what actually makes
  # "there's no third way for an override to exist untracked" true, rather
  # than just a convention someone has to remember to follow.
  validateTrackedList =
    hostKey: tracked:
    let
      checkEntry =
        e:
        lib.assertMsg ((e.exempt or false) || (e ? meta))
          "overlayAudits: ${hostKey} / ${e.id or "<unknown>"} has neither 'exempt = true' nor 'meta' — every tracked overlay entry must declare one or the other";
    in
    assert lib.all checkEntry tracked;
    tracked;

  # Single source of truth: host.overlaysModule + "/overlay-entries.nix".
  # The same file that builds nixpkgs.overlays for that host. Every entry in
  # its `tracked` list is either `exempt = true` or carries `meta`; we
  # extract `meta` from the latter here. validateTrackedList enforces that
  # every entry actually declares one or the other before we even get to
  # filtering — an entry with neither fails eval loudly rather than silently
  # falling through unnoticed.
  #
  # Only `inputs` is passed here, not `pkgs` — metadata extraction (id, meta,
  # exempt) never forces evaluation of the `overlay` function bodies, so a
  # host whose overlay-entries.nix also wants a real `pkgs` (e.g. for
  # deriving `system`) still works correctly here via laziness; it only
  # needs the real value when actually building, which happens through that
  # host's own default.nix, not through this metadata-only import.
  readHostAudits =
    hostKey: host:
    let
      entriesFile = host.overlaysModule + "/overlay-entries.nix";
    in
    if builtins.pathExists entriesFile then
      let
        entries = import entriesFile { inherit inputs; };
        tracked = validateTrackedList hostKey (entries.tracked or [ ]);
        withMeta = builtins.filter (e: e ? meta) tracked;
      in
      lib.listToAttrs (
        map (e: {
          name = e.id;
          value = validateEntry hostKey e.id e.meta;
        }) withMeta
      )
    else
      { };

  # Aggregate per-host audit metadata across all hosts.
  # Keyed by hostname so the CI script can report which host each overlay belongs to.
  hostAudits = lib.mapAttrs readHostAudits hosts;

  # Hook for the system-wide overlay at features/system/core/overlays. This
  # file is imported transitively via systemProfiles and is not reachable
  # through host.overlaysModule, so it's wired in explicitly here with the
  # same treatment, including the same validateTrackedList assertion.
  systemEntriesFile = ./../../../features/system/core/overlays/_overlay-entries.nix;
  systemAudits =
    if builtins.pathExists systemEntriesFile then
      let
        entries = import systemEntriesFile { inherit inputs; };
        tracked = validateTrackedList "features/system/core/overlays" (entries.tracked or [ ]);
        withMeta = builtins.filter (e: e ? meta) tracked;
      in
      {
        "features/system/core/overlays" = lib.listToAttrs (
          map (e: {
            name = e.id;
            value = validateEntry "features/system/core/overlays" e.id e.meta;
          }) withMeta
        );
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

            evalAttr = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = ''
                Nix attribute path (relative to pkgs) to evaluate for the liveness
                check — i.e. does this override still evaluate against the current
                locked nixpkgs at all, independent of tracking-issue/PR/version
                status. Use a dotted path for nested/scoped overrides
                (e.g. "qt6.qtwebengine"). Defaults to the entry's own id when unset.
              '';
            };

            evalHosts = lib.mkOption {
              type = lib.types.nullOr (lib.types.listOf lib.types.str);
              default = null;
              description = ''
                Explicit list of hosts to run the liveness check against.
                Required for shared/cross-host entries (e.g. under
                features/system/core/overlays) where the entry's own grouping key
                isn't itself a host name. Defaults to just the entry's own host
                when unset and that key resolves to a real host.
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
      Audit metadata for temporary overlays, sourced directly from each
      host's overlays/overlay-entries.nix (and the system-wide
      features/system/core/overlays/_overlay-entries.nix) — the same file
      that builds nixpkgs.overlays. Every entry in that file's `tracked` list
      must declare either `exempt = true` or `meta`, enforced by an eval-time
      assertion, so a temporary override can't silently exist untracked.
      Keyed by hostname (or system path), then by overlay id. Consumed by
      the audit-overlays CI workflow and the pre-commit hook via
      `nix eval .#overlayAudits --json`.
    '';
  };

  config.flake.overlayAudits = hostAudits // systemAudits;
}
