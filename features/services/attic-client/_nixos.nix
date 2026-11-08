{
  config,
  pkgs,
  ...
}:
let
  atticConfig = import ./_config.nix {
    inherit pkgs;
    tokenFile = config.sops.secrets."services/attic/token".path;
  };

  # Both units run as attic-watch-store, with its config and state
  serviceDefaults = {
    User = "attic-watch-store";
    Group = "attic-watch-store";
    StateDirectory = "attic-watch-store";
    Environment = [
      "HOME=%S/attic-watch-store"
      "XDG_CONFIG_HOME=${atticConfig}"
    ];
  };

  sleepTargets = [
    "suspend.target"
    "hibernate.target"
    "hybrid-sleep.target"
    "suspend-then-hibernate.target"
  ];
in
{
  users.groups.attic-watch-store = { };
  users.users.attic-watch-store = {
    isSystemUser = true;
    group = "attic-watch-store";
  };

  sops.secrets."services/attic/token" = {
    owner = config.users.users.attic-watch-store.name;
  };

  # Both units push only paths cache.nixos.org doesn't serve (attic's
  # upstream filter, so no --ignore-upstream-cache-filter), one NAR at a
  # time. atticd writes every chunk to SQLite, which takes one writer at
  # once; anything more, and upstream paths it needn't hold, made uploads
  # fail with "database is locked". Upstream paths come from
  # cache.nixos.org instead.
  systemd = {
    services = {
      attic-watch-store = {
        description = "Push new Nix store paths to attic";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = serviceDefaults // {
          Type = "simple";
          ExecStart = "${pkgs.attic-client}/bin/attic watch-store -j 1 home:home-cache";
          Restart = "on-failure";
          RestartSec = 10;
        };
      };

      # watch-store tries each new path once: an upload cut off by sleep, or
      # made while attic was unreachable, is never retried. This catches up by
      # pushing the running system's closure; attic asks the server which
      # paths are missing and uploads only those, so a complete cache costs
      # one query. Started after every resume, daily, and by `rebuild`
      # (features/core/home/_zsh.nix). An interrupted run is finished by the
      # next, so it never holds off sleep.
      attic-push-system = {
        description = "Push the running system's closure to attic";
        # Wanted by and ordered after the sleep targets: runs on resume
        wantedBy = sleepTargets;
        after = [ "network-online.target" ] ++ sleepTargets;
        wants = [ "network-online.target" ];
        # The network can still be coming up just after resume
        startLimitBurst = 5;
        startLimitIntervalSec = 600;
        serviceConfig = serviceDefaults // {
          Type = "oneshot";
          ExecStart = "${pkgs.attic-client}/bin/attic push -j 1 home:home-cache /run/current-system";
          Restart = "on-failure";
          RestartSec = 30;
          TimeoutStartSec = "2h";
        };
      };
    };

    timers = {
      attic-push-system = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
      };
    };
  };
}
