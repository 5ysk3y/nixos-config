# rbw, the Bitwarden CLI that qutebrowser and waybar use, on Linux and macOS.
#
# rbw reads one config.json holding the server, the account email and the
# pinentry program that asks for the master password. The server and email
# are a sops secret, but the pinentry differs per OS and so can't live in it.
# The rbw wrapped here merges the secret with this host's settings into
# config.json each time it runs, writing only when the result changed.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  # Where rbw looks for config.json: its own choice of directory per OS
  configDir =
    if isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/rbw"
    else
      "${config.xdg.configHome}/rbw";

  # Settings that belong to this host rather than to the account. A native
  # dialog on each OS, so unlocking works without a terminal.
  hostSettings = (pkgs.formats.json { }).generate "rbw-host-settings.json" {
    pinentry = if isDarwin then lib.getExe pkgs.pinentry_mac else "${pinentryQt}";
  };

  # Qt reads the theme stylix sets (qtct and Kvantum) from these variables.
  # rbw-agent starts the pinentry with only a few display variables of the
  # caller's, so the dialog sets them itself.
  qtTheme = lib.filterAttrs (
    name: _:
    lib.elem name [
      "QT_QPA_PLATFORMTHEME"
      "QT_STYLE_OVERRIDE"
      "QT_PLUGIN_PATH"
      "QML2_IMPORT_PATH"
    ]
  ) config.systemd.user.sessionVariables;

  pinentryQt = pkgs.writeShellScript "pinentry-qt" ''
    ${lib.concatStrings (
      lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg (toString value)}\n") qtTheme
    )}
    exec ${pkgs.pinentry-qt}/bin/pinentry-qt "$@"
  '';

  secret = config.sops.secrets."services/rbw/config".path;

  rbw = pkgs.symlinkJoin {
    name = "rbw-${pkgs.rbw.version}";
    inherit (pkgs.rbw) version meta;
    paths = [ pkgs.rbw ];
    postBuild = ''
      rm "$out/bin/rbw"
      cp ${rbwWrapper}/bin/rbw "$out/bin/rbw"
    '';
  };

  rbwWrapper = pkgs.writeShellApplication {
    name = "rbw";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      config_dir=${lib.escapeShellArg configDir}
      config_file="$config_dir/config.json"

      # Before sops-nix has decrypted the secret, rbw runs on whatever
      # config it already has.
      if [ -r ${lib.escapeShellArg secret} ]; then
        if merged=$(jq -S -s '.[0] * .[1]' ${lib.escapeShellArg secret} ${hostSettings} 2>/dev/null) \
          && [ "$merged" != "$(cat "$config_file" 2>/dev/null)" ]; then
          mkdir -p "$config_dir"
          chmod 700 "$config_dir"
          # mktemp creates the file readable by its owner only. mv replaces
          # config.json itself, even where it is still an old symlink.
          tmp=$(mktemp "$config_dir/.config.json.XXXXXX")
          printf '%s\n' "$merged" >"$tmp"
          mv -f "$tmp" "$config_file"
        fi
      fi

      export RBW_AGENT="''${RBW_AGENT:-${pkgs.rbw}/bin/rbw-agent}"
      exec ${pkgs.rbw}/bin/rbw "$@"
    '';
  };
in
{
  sops.secrets."services/rbw/config" = { };

  programs.rbw = {
    enable = true;
    package = rbw;
  };
}
