{
  lib,
  config,
  pkgs,
  vars,
  hostname,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    mapAttrs
    filterAttrs
    optionalAttrs
    nameValuePair
    ;

  topology = import ./topology.nix;

  cfg = config.features.home.syncthing;

  host = if cfg.deviceName != null then cfg.deviceName else hostname;

  enabledFolders = filterAttrs (_: f: f.enable) cfg.folders;

  allPeerNames = lib.unique (lib.concatLists (lib.mapAttrsToList (_: f: f.peers) enabledFolders));

  peerDevices = mapAttrs (
    _: dev:
    {
      inherit (dev) id autoAcceptFolders introducer;
    }
    // optionalAttrs (dev ? addresses) {
      inherit (dev) addresses;
    }
  ) (filterAttrs (name: _: builtins.elem name allPeerNames) topology.devices);

  renderedFolders = lib.mapAttrs' (
    folderName: folderCfg:
    let
      topoFolder =
        topology.folders.${folderName}
          or (throw "Syncthing folder '${folderName}' not found in shared topology");

      missingPeers = builtins.filter (peer: !(topology.devices ? ${peer})) folderCfg.peers;
    in
    if missingPeers != [ ] then
      throw "Syncthing folder '${folderName}' on host '${host}' references unknown peer(s): ${builtins.concatStringsSep ", " missingPeers}"
    else
      nameValuePair folderCfg.path {
        inherit (topoFolder) id label;
        inherit (folderCfg) path type;
        devices = folderCfg.peers;
      }
  ) enabledFolders;
in
{

  imports = [
    ./linux-bootstrap.nix
  ];

  options.features.home.syncthing = {
    enable = mkEnableOption "Declarative Syncthing";

    deviceName = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Device name key used in shared Syncthing topology. Defaults to hostname.";
    };

    gui = {
      address = mkOption {
        type = types.str;
        default = "127.0.0.1:8384";
      };

      tls = mkOption {
        type = types.bool;
        default = true;
      };

      theme = mkOption {
        type = types.str;
        default = "dark";
      };

      user = mkOption {
        type = types.str;
        default = vars.username;
      };
    };

    folders = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkEnableOption "Syncthing folder ${name}" // {
                default = true;
              };

              path = mkOption {
                type = types.str;
                description = "Local path for Syncthing folder ${name}.";
              };

              type = mkOption {
                type = types.enum [
                  "sendreceive"
                  "receiveonly"
                  "sendonly"
                  "receiveencrypted"
                ];
                default = "sendreceive";
              };

              peers = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Device names from shared topology that this host shares folder ${name} with.";
              };

              bootstrap = {
                enable = mkOption {
                  type = types.bool;
                  default = false;
                };

                markerFile = mkOption {
                  type = types.str;
                  default = "${config.home.homeDirectory}/.local/state/syncthing-bootstrap/${name}.ready";
                };
              };
            };
          }
        )
      );
      default = { };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = topology.devices ? ${host};
          message = "features.home.syncthing.deviceName '${host}' must exist in shared Syncthing topology.";
        }
      ];

      home.packages = with pkgs; [
        syncthing
        curl
        jq
      ];

      services.syncthing = {
        enable = true;

        cert = config.sops.secrets."syncthing-cert".path;
        key = config.sops.secrets."syncthing-key".path;

        guiCredentials = {
          username = cfg.gui.user;
          passwordFile = config.sops.secrets."services/syncthing/pass".path;
        };

        guiAddress = cfg.gui.address;

        overrideFolders = true;
        overrideDevices = false;

        settings = {
          options = {
            urAccepted = -1;
            relaysEnabled = false;
            localAnnounceEnabled = true;
            globalAnnounceEnabled = false;
          };

          gui = {
            inherit (cfg.gui) tls theme;
          };

          devices = peerDevices;
          folders = renderedFolders;
        };
      };
    }

    (mkIf
      (!pkgs.stdenv.isLinux && builtins.any (f: f.bootstrap.enable) (builtins.attrValues enabledFolders))
      {
        assertions = [
          {
            assertion = false;
            message = "Syncthing bootstrap is enabled for this host, but only the Linux bootstrap helper exists currently.";
          }
        ];
      }
    )
  ]);
}
