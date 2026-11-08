{ lib, pkgs, ... }:
let
  label = "system/org.nixos.linux-builder";
  linux-builder = pkgs.writeShellScriptBin "linux-builder" ''
    case "''${1:-}" in
      start)  sudo launchctl kickstart ${label} ;;
      stop)   sudo launchctl kill SIGTERM ${label} ;;
      status) sudo launchctl print ${label} | grep -E '^\s*state =' ;;
      *) echo "usage: linux-builder start|stop|status" >&2; exit 64 ;;
    esac
  '';
in
{
  nix.linux-builder = {
    enable = true;
    package = pkgs.darwin.linux-builder-vz;
    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    ephemeral = true;
    maxJobs = 2;
    config.virtualisation = {
      cores = 4;
      darwin-builder.memorySize = 4 * 1024;
    };
  };

  # Declared, but not started at boot or kept alive for resource
  # purposes.
  launchd.daemons.linux-builder.serviceConfig = {
    RunAtLoad = lib.mkForce false;
    KeepAlive = lib.mkForce false;
  };

  system.activationScripts.extraActivation.text = lib.mkAfter ''
    if ! /usr/bin/arch -x86_64 /usr/bin/true 2>/dev/null; then
      echo "linux-builder: Rosetta not found, installing..." >&2
      /usr/sbin/softwareupdate --install-rosetta --agree-to-license \
        || echo "linux-builder: WARNING: Rosetta install failed; the builder will refuse to start until it is installed" >&2
    fi
  '';

  environment.systemPackages = [ linux-builder ];
}
