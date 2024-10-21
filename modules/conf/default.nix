{ config, lib, pkgs, home-manager, inputs, ... }:

let
    syncDir = "${config.home.homeDirectory}/Sync";
    draculaPath = builtins.toString inputs.qute-dracula.outPath;
in
{

options = {
    confSymlinks = {
        enable = lib.mkEnableOption "Enables default smymlinks.";

        configs = {
            gnupg = lib.mkOption {
                type = lib.types.bool;
            };

            openrgb = lib.mkOption {
                type = lib.types.bool;
            };

            wallpapers = lib.mkOption {
                type = lib.types.bool;
            };

            webcord = lib.mkOption {
                type = lib.types.bool;
            };

            ssh = lib.mkOption {
                type = lib.types.bool;
            };

            qpwgraph = lib.mkOption {
                type = lib.types.bool;
            };

            streamdeckui = lib.mkOption {
                type = lib.types.bool;
            };

            jellyfinShim = lib.mkOption {
                type = lib.types.bool;
            };
        };
    };
};

config = lib.mkIf config.confSymlinks.enable {

  ## Symlinks
  home.file."${config.home.homeDirectory}/.gnupg/pubring.kbx" = lib.mkIf config.confSymlinks.configs.gnupg {
    source = config.lib.file.mkOutOfStoreSymlink "${syncDir}/Files/nix/gnupg/pubring.kbx";
  };

  home.file."${config.xdg.configHome}/OpenRGB/MainBlue.orp" =  lib.mkIf config.confSymlinks.configs.openrgb {
    source = config.lib.file.mkOutOfStoreSymlink "${syncDir}/Files/nix/OpenRGB/MainBlue.orp";
  };

  home.file."${config.xdg.configHome}/mako/notification.wav" = lib.mkIf config.services.mako.enable {
    source = config.lib.file.mkOutOfStoreSymlink "${syncDir}/Files/nix/mako/notification.wav";
  };

  home.file."${config.xdg.configHome}/Wallpapers" = lib.mkIf config.confSymlinks.configs.wallpapers {
    source = config.lib.file.mkOutOfStoreSymlink "${syncDir}/Files/nix/Wallpapers";
    recursive = true;
  };

  home.file."${config.xdg.configHome}/obs-studio" = lib.mkIf config.programs.obs-studio.enable {
    source = config.lib.file.mkOutOfStoreSymlink "${syncDir}/Files/nix/obs-studio";
    recursive = true;
  };

  home.file."${config.xdg.configHome}/WebCord" = lib.mkIf config.confSymlinks.configs.webcord {
    source = config.lib.file.mkOutOfStoreSymlink "${syncDir}/Files/nix/WebCord";
    recursive = true;
  };

  home.file."${config.home.homeDirectory}/.ssh" = lib.mkIf config.confSymlinks.configs.ssh {
    source = config.lib.file.mkOutOfStoreSymlink "${syncDir}/Private/Keys";
    recursive = true;
  };

  home.file."${config.xdg.configHome}/qutebrowser/dracula" = lib.mkIf config.applications.qutebrowser {
    source = draculaPath;
    recursive = true;
  };

  ## Config Files
  
  ## Rofi-Wayland; for rofi-rbw qutebrowser script
  home.file."${config.xdg.configHome}/rofi/config.rasi" = {
      enable = lib.mkIf config.applications.qutebrowser true;
      text = ''
    * {
        /* Dracula theme colour palette */
        drac-bgd: #282a36;
        drac-cur: #44475a;
        drac-fgd: #f8f8f2;
        drac-cmt: #6272a4;
        drac-cya: #8be9fd;
        drac-grn: #50fa7b;
        drac-ora: #ffb86c;
        drac-pnk: #ff79c6;
        drac-pur: #bd93f9;
        drac-red: #ff5555;
        drac-yel: #f1fa8c;

        font: "Tamzen Bold 12";

        foreground: @drac-fgd;
        background-color: @drac-bgd;
        active-background: @drac-pnk;
        urgent-background: @drac-red;
        urgent-foreground: @drac-bgd;

        selected-background: @active-background;
        selected-urgent-background: @urgent-background;
        selected-active-background: @active-background;
        separatorcolor: @active-background;
        bordercolor: #6272a4;
    }

    #window {
        background-color: @background-color;
        border:           3;
        border-radius: 6;
        border-color: @bordercolor;
        padding:          5;
    }
    #mainbox {
        border:  0;
        padding: 5;
    }
    #message {
        border:       1px dash 0px 0px ;
        border-color: @separatorcolor;
        padding:      1px ;
    }
    #textbox {
        text-color: @foreground;
    }
    #listview {
        fixed-height: 0;
        border:       2px dash 0px 0px ;
        border-color: @bordercolor;
        spacing:      2px ;
        scrollbar:    false;
        padding:      2px 0px 0px ;
    }
    #element {
        border:  0;
        padding: 1px ;
    }
    #element.normal.normal {
        background-color: @background-color;
        text-color:       @foreground;
    }
    #element.normal.urgent {
        background-color: @urgent-background;
        text-color:       @urgent-foreground;
    }
    #element.normal.active {
        background-color: @active-background;
        text-color:       @background-color;
    }
    #element.selected.normal {
        background-color: @selected-background;
        text-color:       @foreground;
    }
    #element.selected.urgent {
        background-color: @selected-urgent-background;
        text-color:       @foreground;
    }
    #element.selected.active {
        background-color: @selected-active-background;
        text-color:       @background-color;
    }
    #element.alternate.normal {
        background-color: @background-color;
        text-color:       @foreground;
    }
    #element.alternate.urgent {
        background-color: @urgent-background;
        text-color:       @foreground;
    }
    #element.alternate.active {
        background-color: @active-background;
        text-color:       @foreground;
    }
    #scrollbar {
        width:        2px ;
        border:       0;
        handle-width: 8px ;
        padding:      0;
    }
    #sidebar {
        border:       2px dash 0px 0px ;
        border-color: @separatorcolor;
    }
    #button.selected {
        background-color: @selected-background;
        text-color:       @foreground;
    }
    #inputbar {
        spacing:    0;
        text-color: @foreground;
        padding:    1px ;
    }
    #case-indicator {
        spacing:    0;
        text-color: @foreground;
    }
    #entry {
        spacing:    0;
        text-color: @drac-cya;
    }
    #prompt {
        spacing:    0;
        text-color: @drac-grn;
    }
    #inputbar {
        children:   [ prompt,textbox-prompt-colon,entry,case-indicator ];
    }
    #textbox-prompt-colon {
        expand:     false;
        str:        ":";
        margin:     0px 0.3em 0em 0em ;
        text-color: @drac-grn;
    }
    element-text, element-icon {
        background-color: inherit;
        text-color: inherit;
    }
    '';
  };

  ## QPWGraph

  home.file."${config.xdg.configHome}/qpwgraph/default.qpwgraph" = lib.mkIf config.confSymlinks.configs.qpwgraph {
      text = ''
<!DOCTYPE patchbay>
<patchbay name="default" version="0.6.2">
 <items>
  <item node-type="pipewire" port-type="pipewire-audio">
   <output node="Chromium-2" port="Chromium:output_FR"/>
   <input node="Stream Audio - Music" port="Stream Audio - Music:playback_FR"/>
  </item>
  <item node-type="pipewire" port-type="pipewire-audio">
   <output node="World of Warcraft" port="World of Warcraft:output_FR"/>
   <input node="Stream Audio - Game" port="Stream Audio - Game:playback_FR"/>
  </item>
  <item node-type="pipewire" port-type="pipewire-audio">
   <output node="Chromium" port="Chromium:output_FL"/>
   <input node="Stream Audio - Music" port="Stream Audio - Music:playback_FL"/>
  </item>
  <item node-type="pipewire" port-type="pipewire-audio">
   <output node="Chromium" port="Chromium:output_FL"/>
   <input node="Stream Audio" port="Stream Audio:playback_FL"/>
  </item>
  <item node-type="pipewire" port-type="pipewire-audio">
   <output node="HDMI/External" port="HDMI/External:monitor_FR"/>
   <input node="Starship/Matisse HD Audio Controller Analog Stereo" port="ALC892 Analog:playback_FR"/>
  </item>
  <item node-type="pipewire" port-type="pipewire-audio">
   <output node="mpv" port="mpv:output_FL"/>
   <input node="HDMI/External" port="HDMI/External:playback_FL"/>
  </item>
  <item node-type="pipewire" port-type="pipewire-audio">
   <output node="Chromium-2" port="Chromium:output_FL"/>
   <input node="Stream Audio - Music" port="Stream Audio - Music:playback_FL"/>
  </item>
  <item node-type="pipewire" port-type="pipewire-audio">
   <output node="World of Warcraft" port="World of Warcraft:output_FL"/>
   <input node="Stream Audio - Game" port="Stream Audio - Game:playback_FL"/>
  </item>
  <item node-type="pipewire" port-type="pipewire-audio">
   <output node="Chromium" port="Chromium:output_FR"/>
   <input node="Stream Audio" port="Stream Audio:playback_FR"/>
  </item>
  <item node-type="pipewire" port-type="pipewire-audio">
   <output node="mpv" port="mpv:output_FR"/>
   <input node="HDMI/External" port="HDMI/External:playback_FR"/>
  </item>
  <item node-type="pipewire" port-type="pipewire-audio">
   <output node="HDMI/External" port="HDMI/External:monitor_FL"/>
   <input node="Navi 21/23 HDMI/DP Audio Controller Digital Stereo (HDMI 5)" port="BenQ EX2780Q:playback_FL"/>
  </item>
  <item node-type="pipewire" port-type="pipewire-audio">
   <output node="HDMI/External" port="HDMI/External:monitor_FL"/>
   <input node="Starship/Matisse HD Audio Controller Analog Stereo" port="ALC892 Analog:playback_FL"/>
  </item>
  <item node-type="pipewire" port-type="pipewire-audio">
   <output node="Chromium" port="Chromium:output_FR"/>
   <input node="Stream Audio - Music" port="Stream Audio - Music:playback_FR"/>
  </item>
  <item node-type="pipewire" port-type="pipewire-audio">
   <output node="Chromium" port="Chromium:output_FL"/>
   <input node="Stream Audio/Sink sink" port="Stream Audio/Sink sink:playback_FL"/>
  </item>
  <item node-type="pipewire" port-type="pipewire-audio">
   <output node="Chromium" port="Chromium:output_FR"/>
   <input node="Stream Audio/Sink sink" port="Stream Audio/Sink sink:playback_FR"/>
  </item>
  <item node-type="pipewire" port-type="pipewire-audio">
   <output node="HDMI/External" port="HDMI/External:monitor_FR"/>
   <input node="Navi 21/23 HDMI/DP Audio Controller Digital Stereo (HDMI 5)" port="BenQ EX2780Q:playback_FR"/>
  </item>
 </items>
</patchbay>
  '';
  };

  ## OpenRGB

home.file."${config.xdg.configHome}/OpenRGB/OpenRGB.json" = lib.mkIf config.confSymlinks.configs.openrgb {
      text = ''
{
    "AutoStart": {
        "client": "localhost:6742",
        "custom": "",
        "enabled": false,
        "host": "0.0.0.0",
        "port": "6742",
        "profile": "MainBlue",
        "setclient": false,
        "setcustom": false,
        "setminimized": false,
        "setprofile": false,
        "setserver": false,
        "setserverhost": false,
        "setserverport": false
    },
    "CorsairDominatorSettings": {
        "model": "CMT"
    },
    "Detectors": {
        "detectors": {
            "AMD Wraith Prism": true,
            "AOC AGON AMM700": true,
            "AOC GK500": true,
            "AOC GM500": true,
            "ASRock Deskmini Addressable LED Strip": true,
            "ASRock Motherboard SMBus Controllers": true,
            "ASRock Polychrome SMBus": true,
            "ASRock Polychrome USB": true,
            "ASUS AREZ Strix RX Vega 56 O8G": true,
            "ASUS Aura Addressable": true,
            "ASUS Aura Core": true,
            "ASUS Aura GPU": true,
            "ASUS Aura GPU (ENE)": true,
            "ASUS Aura Motherboard": true,
            "ASUS Aura SMBus DRAM": true,
            "ASUS Aura SMBus Motherboard": true,
            "ASUS Cerberus Mech": true,
            "ASUS GTX 1060 Strix": true,
            "ASUS GTX 1060 Strix 6G Gaming": true,
            "ASUS GTX 1070 Strix Gaming": true,
            "ASUS GTX 1070 Strix OC": true,
            "ASUS GTX 1080 Strix OC": true,
            "ASUS KO RTX 3060 O12G V2 GAMING": true,
            "ASUS KO RTX 3060 OC O12G GAMING": true,
            "ASUS KO RTX 3060Ti O8G GAMING": true,
            "ASUS KO RTX 3060Ti O8G V2 GAMING": true,
            "ASUS KO RTX 3070 O8G V2 GAMING": true,
            "ASUS ROG AURA Terminal": true,
            "ASUS ROG Ally": true,
            "ASUS ROG Balteus": true,
            "ASUS ROG Balteus Qi": true,
            "ASUS ROG Chakram (Wireless)": true,
            "ASUS ROG Claymore": true,
            "ASUS ROG Falchion (Wired)": true,
            "ASUS ROG Falchion (Wireless)": true,
            "ASUS ROG GTX 1660 Ti OC 6G": true,
            "ASUS ROG Gladius II": true,
            "ASUS ROG Gladius II Core": true,
            "ASUS ROG Gladius II Origin": true,
            "ASUS ROG Gladius II Origin COD": true,
            "ASUS ROG Gladius II Origin PNK LTD": true,
            "ASUS ROG Gladius II Wireless": true,
            "ASUS ROG Gladius III": true,
            "ASUS ROG Gladius III Wireless 2.4Ghz": true,
            "ASUS ROG Gladius III Wireless Bluetooth": true,
            "ASUS ROG Gladius III Wireless USB": true,
            "ASUS ROG Keris": true,
            "ASUS ROG Keris Wireless 2.4Ghz": true,
            "ASUS ROG Keris Wireless Bluetooth": true,
            "ASUS ROG Keris Wireless USB": true,
            "ASUS ROG PG32UQ": true,
            "ASUS ROG Pugio": true,
            "ASUS ROG Pugio II (Wired)": true,
            "ASUS ROG Pugio II (Wireless)": true,
            "ASUS ROG RTX 3080 10G GUNDAM EDITION": true,
            "ASUS ROG Ryuo AIO": true,
            "ASUS ROG STRIX 3060 12G GAMING": true,
            "ASUS ROG STRIX 3060 O12G GAMING": true,
            "ASUS ROG STRIX 3060 O12G V2 GAMING": true,
            "ASUS ROG STRIX 3060Ti O8G OC": true,
            "ASUS ROG STRIX 3060Ti O8G V2": true,
            "ASUS ROG STRIX 3070 O8G GAMING": true,
            "ASUS ROG STRIX 3070 O8G V2 GAMING": true,
            "ASUS ROG STRIX 3070 O8G V2 White": true,
            "ASUS ROG STRIX 3070 O8G White": true,
            "ASUS ROG STRIX 3070 OC": true,
            "ASUS ROG STRIX 3070Ti O8G GAMING": true,
            "ASUS ROG STRIX 3080 10G GAMING": true,
            "ASUS ROG STRIX 3080 10G V2 GAMING": true,
            "ASUS ROG STRIX 3080 O10G GAMING": true,
            "ASUS ROG STRIX 3080 O10G V2 GAMING": true,
            "ASUS ROG STRIX 3080 O10G V2 WHITE": true,
            "ASUS ROG STRIX 3080 O10G WHITE": true,
            "ASUS ROG STRIX 3080Ti O12G GAMING": true,
            "ASUS ROG STRIX 3090 24G GAMING": true,
            "ASUS ROG STRIX 3090 O24G GAMING": true,
            "ASUS ROG STRIX 3090 O24G GAMING White OC": true,
            "ASUS ROG STRIX LC 3080Ti O12G GAMING": true,
            "ASUS ROG STRIX LC RX 6800XT O16G GAMING": true,
            "ASUS ROG STRIX LC RX 6900XT O16G GAMING": true,
            "ASUS ROG STRIX LC RX 6900XT O16G GAMING TOP": true,
            "ASUS ROG STRIX LC RX 6950XT O16G GAMING": true,
            "ASUS ROG STRIX RTX 2060 EVO Gaming 6G": true,
            "ASUS ROG STRIX RTX 2060 O6G EVO Gaming": true,
            "ASUS ROG STRIX RTX 2060 O6G Gaming": true,
            "ASUS ROG STRIX RTX 2060S 8G Gaming": true,
            "ASUS ROG STRIX RTX 2060S A8G EVO Gaming": true,
            "ASUS ROG STRIX RTX 2060S A8G Gaming": true,
            "ASUS ROG STRIX RTX 2060S O8G Gaming": true,
            "ASUS ROG STRIX RTX 2070 A8G Gaming": true,
            "ASUS ROG STRIX RTX 2070 O8G Gaming": true,
            "ASUS ROG STRIX RTX 2070S 8G Gaming": true,
            "ASUS ROG STRIX RTX 2070S A8G Gaming": true,
            "ASUS ROG STRIX RTX 2070S O8G Gaming": true,
            "ASUS ROG STRIX RTX 2080 8G Gaming": true,
            "ASUS ROG STRIX RTX 2080 O8G Gaming": true,
            "ASUS ROG STRIX RTX 2080 O8G V2 Gaming": true,
            "ASUS ROG STRIX RTX 2080 Ti 11G Gaming": true,
            "ASUS ROG STRIX RTX 2080 Ti A11G Gaming": true,
            "ASUS ROG STRIX RTX 2080 Ti O11G Gaming": true,
            "ASUS ROG STRIX RTX 2080S A8G Gaming": true,
            "ASUS ROG STRIX RTX 2080S O8G Gaming": true,
            "ASUS ROG STRIX RTX 2080S O8G White": true,
            "ASUS ROG STRIX RTX 3080 12G": true,
            "ASUS ROG STRIX RTX 3080 O12G": true,
            "ASUS ROG STRIX RTX 3080 O12G EVA EDITION": true,
            "ASUS ROG STRIX RTX 4080 16G GAMING": true,
            "ASUS ROG STRIX RTX 4080 O16G GAMING": true,
            "ASUS ROG STRIX RTX 4090 24G GAMING": true,
            "ASUS ROG STRIX RTX 4090 O24G GAMING": true,
            "ASUS ROG STRIX RX 6700XT O12G GAMING": true,
            "ASUS ROG STRIX RX 6750XT O12G GAMING": true,
            "ASUS ROG STRIX RX 6800 O16G Gaming": true,
            "ASUS ROG STRIX RX470 O4G GAMING": true,
            "ASUS ROG STRIX RX470 O4G Gaming": true,
            "ASUS ROG STRIX RX480 Gaming OC": true,
            "ASUS ROG STRIX RX560 Gaming": true,
            "ASUS ROG Strix Claw": true,
            "ASUS ROG Strix Evolve": true,
            "ASUS ROG Strix Flare": true,
            "ASUS ROG Strix Flare CoD Black Ops 4 Edition": true,
            "ASUS ROG Strix Flare PNK LTD": true,
            "ASUS ROG Strix GTX 1050 O2G Gaming": true,
            "ASUS ROG Strix GTX 1050 TI 4G Gaming": true,
            "ASUS ROG Strix GTX 1050 TI O4G Gaming": true,
            "ASUS ROG Strix GTX 1650S OC 4G": true,
            "ASUS ROG Strix GTX 1660S O6G Gaming": true,
            "ASUS ROG Strix GTX1070 Ti 8G Gaming": true,
            "ASUS ROG Strix GTX1070 Ti A8G Gaming": true,
            "ASUS ROG Strix GTX1080 A8G Gaming": true,
            "ASUS ROG Strix GTX1080 O8G 11Gbps": true,
            "ASUS ROG Strix GTX1080 O8G Gaming": true,
            "ASUS ROG Strix GTX1080 Ti 11G Gaming": true,
            "ASUS ROG Strix GTX1080 Ti Gaming": true,
            "ASUS ROG Strix GTX1080 Ti O11G Gaming": true,
            "ASUS ROG Strix Impact": true,
            "ASUS ROG Strix Impact II": true,
            "ASUS ROG Strix Impact II Electro Punk": true,
            "ASUS ROG Strix Impact II Gundam": true,
            "ASUS ROG Strix Impact II Moonlight White": true,
            "ASUS ROG Strix Impact II Wireless 2.4 Ghz": true,
            "ASUS ROG Strix Impact II Wireless USB": true,
            "ASUS ROG Strix LC": true,
            "ASUS ROG Strix SCAR 15": true,
            "ASUS ROG Strix Scope": true,
            "ASUS ROG Strix Scope RX": true,
            "ASUS ROG Strix Scope RX TKL Wireless Deluxe": true,
            "ASUS ROG Strix Scope TKL": true,
            "ASUS ROG Strix Scope TKL PNK LTD": true,
            "ASUS ROG Strix XG279Q": true,
            "ASUS ROG Strix XG27AQ": true,
            "ASUS ROG Strix XG27AQM": true,
            "ASUS ROG Strix XG27W": true,
            "ASUS ROG Throne": true,
            "ASUS ROG Throne QI": true,
            "ASUS ROG Throne QI GUNDAM": true,
            "ASUS RX 5600XT Strix O6G Gaming": true,
            "ASUS RX 570 Strix O4G Gaming OC": true,
            "ASUS RX 570 Strix O8G Gaming OC": true,
            "ASUS RX 5700XT Strix 08G Gaming": true,
            "ASUS RX 5700XT Strix Gaming OC": true,
            "ASUS RX 580 Strix Gaming OC": true,
            "ASUS RX 580 Strix Gaming TOP": true,
            "ASUS RX 6800 TUF Gaming OC": true,
            "ASUS TUF 3060 O12G GAMING": true,
            "ASUS TUF 3060 O12G V2 GAMING": true,
            "ASUS TUF Gaming K1": true,
            "ASUS TUF Gaming K3": true,
            "ASUS TUF Gaming K5": true,
            "ASUS TUF Gaming K7": true,
            "ASUS TUF Gaming M3": true,
            "ASUS TUF Gaming M5": true,
            "ASUS TUF Laptop": true,
            "ASUS TUF Laptop Linux WMI": true,
            "ASUS TUF RTX 3060 Ti 8G Gaming OC": true,
            "ASUS TUF RTX 3060Ti O8G": true,
            "ASUS TUF RTX 3060Ti O8G OC": true,
            "ASUS TUF RTX 3070 8G GAMING": true,
            "ASUS TUF RTX 3070 O8G GAMING": true,
            "ASUS TUF RTX 3070 O8G V2 GAMING": true,
            "ASUS TUF RTX 3070Ti O8G GAMING": true,
            "ASUS TUF RTX 3070Ti O8G V2 GAMING": true,
            "ASUS TUF RTX 3080 10G GAMING": true,
            "ASUS TUF RTX 3080 O10G OC": true,
            "ASUS TUF RTX 3080 O10G V2 GAMING": true,
            "ASUS TUF RTX 3080 O12G GAMING": true,
            "ASUS TUF RTX 3080Ti 12G GAMING": true,
            "ASUS TUF RTX 3080Ti O12G GAMING": true,
            "ASUS TUF RTX 3090 O24G": true,
            "ASUS TUF RTX 3090 O24G OC": true,
            "ASUS TUF RTX 3090Ti O24G OC GAMING": true,
            "ASUS TUF RTX 4070 Ti 12G Gaming": true,
            "ASUS TUF RTX 4070 Ti O12G Gaming": true,
            "ASUS TUF RTX 4080 O16G GAMING": true,
            "ASUS TUF RTX 4080 O16G OC": true,
            "ASUS TUF RTX 4090 O24G": true,
            "ASUS TUF RTX 4090 O24G OC": true,
            "ASUS TUF RX 6700XT O12G GAMING": true,
            "ASUS TUF RX 6800XT O16G GAMING": true,
            "ASUS TUF RX 6900XT O16G GAMING": true,
            "ASUS TUF RX 6900XT T16G GAMING": true,
            "ASUS TUF RX 6950XT O16G GAMING": true,
            "ASUS Vega 64 Strix": true,
            "ASUS_TUF RX 6700XT O12G GAMING": true,
            "Acer Predator Gaming Mouse (Rival 300)": true,
            "Alienware AW510K": true,
            "Anne Pro 2": true,
            "Aorus CPU Coolers": true,
            "Asus ROG Chakram (Wired)": true,
            "Asus ROG Chakram Core": true,
            "Asus ROG Chakram X 2.4GHz": true,
            "Asus ROG Chakram X USB": true,
            "Asus ROG Spatha X 2.4GHz": true,
            "Asus ROG Spatha X USB": true,
            "BlinkyTape": true,
            "Bloody MP 50RS": true,
            "Bloody W60 Pro": true,
            "CRYORIG H7 Quad Lumi": true,
            "Cherry Keyboard CCF MX 1.0 TKL BL": true,
            "Cherry Keyboard CCF MX 1.0 TKL NBL": true,
            "Cherry Keyboard CCF MX 8.0 TKL BL": true,
            "Cherry Keyboard G80-3000 TKL NBL": true,
            "Cherry Keyboard G80-3000 TKL NBL KOREAN": true,
            "Cherry Keyboard G80-3000 TKL RGB": true,
            "Cherry Keyboard G80-3000N FL RGB": true,
            "Cherry Keyboard G80-3000N TKL RGB": true,
            "Cherry Keyboard MV BOARD 3.0 FL RGB": true,
            "Cherry Keyboard MX 1.0 FL BL": true,
            "Cherry Keyboard MX 1.0 FL NBL": true,
            "Cherry Keyboard MX 1.0 FL RGB": true,
            "Cherry Keyboard MX BOARD 1.0 TKL RGB": true,
            "Cherry Keyboard MX BOARD 10.0 FL RGB": true,
            "Cherry Keyboard MX BOARD 10.0N FL RGB": true,
            "Cherry Keyboard MX BOARD 2.0S FL NBL": true,
            "Cherry Keyboard MX BOARD 2.0S FL RGB": true,
            "Cherry Keyboard MX BOARD 2.0S FL RGB DE": true,
            "Cherry Keyboard MX BOARD 3.0S FL NBL": true,
            "Cherry Keyboard MX BOARD 3.0S FL RGB": true,
            "Cherry Keyboard MX BOARD 3.0S FL RGB KOREAN": true,
            "Cherry Keyboard MX BOARD 8.0 TKL RGB": true,
            "Cooler Master ARGB": true,
            "Cooler Master ARGB Gen 2 A1": true,
            "Cooler Master ARGB Gen 2 A1 V2": true,
            "Cooler Master MK570": true,
            "Cooler Master MK750": true,
            "Cooler Master MM530": true,
            "Cooler Master MM711": true,
            "Cooler Master MM720": true,
            "Cooler Master MM730": true,
            "Cooler Master MP750 Large": true,
            "Cooler Master MP750 Medium": true,
            "Cooler Master MP750 XL": true,
            "Cooler Master MasterKeys Pro L": true,
            "Cooler Master MasterKeys Pro L White": true,
            "Cooler Master MasterKeys Pro S": true,
            "Cooler Master RGB": true,
            "Cooler Master Radeon 6000 GPU": true,
            "Cooler Master Radeon 6900 GPU": true,
            "Cooler Master SK630": true,
            "Cooler Master SK650": true,
            "Cooler Master Small ARGB": true,
            "Cooler Master Smalll ARGB": true,
            "Corsair 1000D Obsidian": true,
            "Corsair Commander Core": true,
            "Corsair Commander Pro": true,
            "Corsair Dominator Platinum": true,
            "Corsair Glaive RGB": true,
            "Corsair Glaive RGB PRO": true,
            "Corsair H100i v2": true,
            "Corsair Harpoon RGB": true,
            "Corsair Harpoon RGB PRO": true,
            "Corsair Hydro H100i Platinum": true,
            "Corsair Hydro H100i Platinum SE": true,
            "Corsair Hydro H100i Pro XT": true,
            "Corsair Hydro H100i Pro XT v2": true,
            "Corsair Hydro H115i Platinum": true,
            "Corsair Hydro H115i Pro XT": true,
            "Corsair Hydro H150i Pro XT": true,
            "Corsair Hydro H60i Pro XT": true,
            "Corsair Hydro Series": true,
            "Corsair Ironclaw RGB": true,
            "Corsair Ironclaw Wireless": true,
            "Corsair Ironclaw Wireless (Wired)": true,
            "Corsair K100": true,
            "Corsair K55 RGB": true,
            "Corsair K55 RGB PRO": true,
            "Corsair K55 RGB PRO XT": true,
            "Corsair K57 RGB (Wired)": true,
            "Corsair K60 RGB PRO": true,
            "Corsair K60 RGB PRO Low Profile": true,
            "Corsair K65 LUX RGB": true,
            "Corsair K65 Mini": true,
            "Corsair K65 RGB": true,
            "Corsair K65 RGB RAPIDFIRE": true,
            "Corsair K68 RGB": true,
            "Corsair K70 LUX": true,
            "Corsair K70 LUX RGB": true,
            "Corsair K70 RGB": true,
            "Corsair K70 RGB MK.2": true,
            "Corsair K70 RGB MK.2 Low Profile": true,
            "Corsair K70 RGB MK.2 SE": true,
            "Corsair K70 RGB RAPIDFIRE": true,
            "Corsair K95 RGB": true,
            "Corsair K95 RGB PLATINUM": true,
            "Corsair K95 RGB PLATINUM XT": true,
            "Corsair LS100 Lighting Kit": true,
            "Corsair LT100": true,
            "Corsair Lighting Node Core": true,
            "Corsair Lighting Node Pro": true,
            "Corsair M55 RGB PRO": true,
            "Corsair M65": true,
            "Corsair M65 PRO": true,
            "Corsair M65 RGB Elite": true,
            "Corsair MM700": true,
            "Corsair MM800 RGB Polaris": true,
            "Corsair Nightsword": true,
            "Corsair SPEC OMEGA RGB": true,
            "Corsair ST100 RGB": true,
            "Corsair Sabre RGB": true,
            "Corsair Scimitar Elite RGB": true,
            "Corsair Scimitar PRO RGB": true,
            "Corsair Scimitar RGB": true,
            "Corsair Strafe": true,
            "Corsair Strafe MK.2": true,
            "Corsair Strafe Red": true,
            "Corsair Vengeance": true,
            "Corsair Vengeance Pro": true,
            "Cougar 700K EVO Gaming Keyboard": true,
            "Cougar Revenger ST": true,
            "Creative SoundBlasterX G6": true,
            "Crucial": true,
            "DMX": true,
            "Dark Project KD3B V2": true,
            "Das Keyboard Q4 RGB": true,
            "Das Keyboard Q5 RGB": true,
            "Das Keyboard Q5S RGB": true,
            "Debug Controllers": true,
            "Dell G Series LED Controller": true,
            "Ducky One 2 RGB TKL": true,
            "Ducky Shine 7/Ducky One 2 RGB": true,
            "Dygma Raise": true,
            "E1.31": true,
            "EK Loop Connect": true,
            "ENE SMBus DRAM": true,
            "EVGA GP102 GPU": true,
            "EVGA GPU": true,
            "EVGA GeForce RTX 2070 SUPER FTW3 Ultra": true,
            "EVGA GeForce RTX 2070 SUPER FTW3 Ultra+": true,
            "EVGA GeForce RTX 2070 SUPER XC Gaming": true,
            "EVGA GeForce RTX 2070 SUPER XC Ultra": true,
            "EVGA GeForce RTX 2070 SUPER XC Ultra+": true,
            "EVGA GeForce RTX 2070 XC Black": true,
            "EVGA GeForce RTX 2070 XC Gaming": true,
            "EVGA GeForce RTX 2070 XC OC": true,
            "EVGA GeForce RTX 2080 Black": true,
            "EVGA GeForce RTX 2080 SUPER FTW3 Hybrid OC": true,
            "EVGA GeForce RTX 2080 SUPER FTW3 Ultra": true,
            "EVGA GeForce RTX 2080 SUPER FTW3 Ultra Hydro Copper": true,
            "EVGA GeForce RTX 2080 SUPER XC Gaming": true,
            "EVGA GeForce RTX 2080 SUPER XC Ultra": true,
            "EVGA GeForce RTX 2080 XC Black": true,
            "EVGA GeForce RTX 2080 XC Gaming": true,
            "EVGA GeForce RTX 2080 XC Ultra Gaming": true,
            "EVGA GeForce RTX 2080Ti Black": true,
            "EVGA GeForce RTX 2080Ti FTW3 Ultra": true,
            "EVGA GeForce RTX 2080Ti XC HYBRID GAMING": true,
            "EVGA GeForce RTX 2080Ti XC HYDRO COPPER": true,
            "EVGA GeForce RTX 2080Ti XC Ultra": true,
            "EVGA GeForce RTX 3060TI FTW3 Gaming": true,
            "EVGA GeForce RTX 3060TI FTW3 Ultra": true,
            "EVGA GeForce RTX 3060TI FTW3 Ultra LHR": true,
            "EVGA GeForce RTX 3070 Black Gaming": true,
            "EVGA GeForce RTX 3070 FTW3 Ultra": true,
            "EVGA GeForce RTX 3070 FTW3 Ultra LHR": true,
            "EVGA GeForce RTX 3070 XC3 Gaming": true,
            "EVGA GeForce RTX 3070 XC3 Ultra": true,
            "EVGA GeForce RTX 3070 XC3 Ultra LHR": true,
            "EVGA GeForce RTX 3070Ti FTW3 Ultra": true,
            "EVGA GeForce RTX 3070Ti FTW3 Ultra v2": true,
            "EVGA GeForce RTX 3070Ti XC3 Gaming": true,
            "EVGA GeForce RTX 3070Ti XC3 Ultra": true,
            "EVGA GeForce RTX 3070Ti XC3 Ultra v2": true,
            "EVGA GeForce RTX 3080 FTW3 Gaming": true,
            "EVGA GeForce RTX 3080 FTW3 Ultra": true,
            "EVGA GeForce RTX 3080 FTW3 Ultra 12GB": true,
            "EVGA GeForce RTX 3080 FTW3 Ultra Hybrid": true,
            "EVGA GeForce RTX 3080 FTW3 Ultra Hybrid Gaming LHR": true,
            "EVGA GeForce RTX 3080 FTW3 Ultra Hybrid LHR": true,
            "EVGA GeForce RTX 3080 FTW3 Ultra Hydro Copper": true,
            "EVGA GeForce RTX 3080 FTW3 Ultra Hydro Copper 12G": true,
            "EVGA GeForce RTX 3080 FTW3 Ultra LHR": true,
            "EVGA GeForce RTX 3080 FTW3 Ultra v2 LHR": true,
            "EVGA GeForce RTX 3080 XC3 Black": true,
            "EVGA GeForce RTX 3080 XC3 Black LHR": true,
            "EVGA GeForce RTX 3080 XC3 Gaming": true,
            "EVGA GeForce RTX 3080 XC3 Gaming LHR": true,
            "EVGA GeForce RTX 3080 XC3 Ultra": true,
            "EVGA GeForce RTX 3080 XC3 Ultra 12G": true,
            "EVGA GeForce RTX 3080 XC3 Ultra Hybrid": true,
            "EVGA GeForce RTX 3080 XC3 Ultra Hybrid LHR": true,
            "EVGA GeForce RTX 3080 XC3 Ultra Hydro Copper": true,
            "EVGA GeForce RTX 3080 XC3 Ultra LHR": true,
            "EVGA GeForce RTX 3080Ti FTW3 Ultra": true,
            "EVGA GeForce RTX 3080Ti FTW3 Ultra Hybrid": true,
            "EVGA GeForce RTX 3080Ti FTW3 Ultra Hydro Copper": true,
            "EVGA GeForce RTX 3080Ti XC3 Gaming": true,
            "EVGA GeForce RTX 3080Ti XC3 Gaming Hybrid": true,
            "EVGA GeForce RTX 3080Ti XC3 Gaming Hydro Copper": true,
            "EVGA GeForce RTX 3080Ti XC3 Ultra Gaming": true,
            "EVGA GeForce RTX 3090 FTW3 Ultra": true,
            "EVGA GeForce RTX 3090 FTW3 Ultra Hybrid": true,
            "EVGA GeForce RTX 3090 FTW3 Ultra Hydro Copper": true,
            "EVGA GeForce RTX 3090 FTW3 Ultra v2": true,
            "EVGA GeForce RTX 3090 FTW3 Ultra v3": true,
            "EVGA GeForce RTX 3090 K|NGP|N Hybrid": true,
            "EVGA GeForce RTX 3090 K|NGP|N Hydro Copper": true,
            "EVGA GeForce RTX 3090 XC3 Black": true,
            "EVGA GeForce RTX 3090 XC3 Gaming": true,
            "EVGA GeForce RTX 3090 XC3 Ultra": true,
            "EVGA GeForce RTX 3090 XC3 Ultra Hybrid": true,
            "EVGA GeForce RTX 3090 XC3 Ultra Hydro Copper": true,
            "EVGA GeForce RTX 3090Ti FTW3 Black Gaming": true,
            "EVGA GeForce RTX 3090Ti FTW3 Gaming": true,
            "EVGA GeForce RTX 3090Ti FTW3 Ultra Gaming": true,
            "EVGA Pascal GPU": true,
            "EVGA X20 Gaming Mouse": true,
            "EVGA X20 USB Receiver": true,
            "EVGA Z15 Keyboard": true,
            "EVGA Z20 Keyboard": true,
            "EVision Keyboard 0C45:5004": true,
            "EVision Keyboard 0C45:5104": true,
            "EVision Keyboard 0C45:5204": true,
            "EVision Keyboard 0C45:652F": true,
            "EVision Keyboard 0C45:7698": true,
            "EVision Keyboard 0C45:8520": true,
            "EVision Keyboard 320F:5000": true,
            "EVision Keyboard 320F:502A": true,
            "EVision Keyboard 320F:5064": true,
            "ElgatoKeyLight": true,
            "Epomaker TH80 Pro (USB Cable)": true,
            "Epomaker TH80 Pro (USB Dongle)": true,
            "Espurna": true,
            "Everest GT-100 RGB": true,
            "FL ESPORTS F11": true,
            "FanBus": true,
            "Faustus": true,
            "GALAX RTX 2070 Super EX Gamer Black": true,
            "GaiZhongGai 17 PRO": true,
            "GaiZhongGai 17+4+Touch PRO": true,
            "GaiZhongGai 20 PRO": true,
            "GaiZhongGai 42 PRO": true,
            "GaiZhongGai 68+4 PRO": true,
            "GaiZhongGai Dial": true,
            "GaiZhongGai LightBoard": true,
            "GaiZhongGai RGB HUB Blue": true,
            "GaiZhongGai RGB HUB Green": true,
            "Gainward GPU": true,
            "Gainward GTX 1080 Phoenix": true,
            "Gainward GTX 1080 Ti Phoenix": true,
            "Gainward RTX 2070 Super Phantom": true,
            "Gainward RTX 2080 Phoenix GS": true,
            "Gainward RTX 3070 Phoenix": true,
            "Gainward RTX 3070 Ti Phoenix": true,
            "Gainward RTX 3080 Phoenix": true,
            "Gainward RTX 3080 Ti Phoenix": true,
            "Gainward RTX 3090 Phoenix": true,
            "Galax GPU": true,
            "Genesis Thor 300": true,
            "Gigabyte AORUS RTX2060 SUPER 8G V1": true,
            "Gigabyte AORUS RTX2070 SUPER 8G": true,
            "Gigabyte AORUS RTX2070 XTREME 8G": true,
            "Gigabyte AORUS RTX2080 8G": true,
            "Gigabyte AORUS RTX2080 SUPER 8G": true,
            "Gigabyte AORUS RTX2080 SUPER 8G Rev 1.0": true,
            "Gigabyte AORUS RTX2080 SUPER Waterforce WB 8G": true,
            "Gigabyte AORUS RTX2080 Ti XTREME 11G": true,
            "Gigabyte AORUS RTX2080 XTREME 8G": true,
            "Gigabyte AORUS RTX3060 ELITE 12G": true,
            "Gigabyte AORUS RTX3060 ELITE 12G LHR": true,
            "Gigabyte AORUS RTX3060 ELITE 12G Rev a1": true,
            "Gigabyte AORUS RTX3060 Ti ELITE 8G LHR": true,
            "Gigabyte AORUS RTX3070 Ti MASTER 8G": true,
            "Gigabyte AORUS RTX3080 Ti XTREME WATERFORCE 12G": true,
            "Gigabyte AORUS RTX3080 XTREME WATERFORCE 10G Rev 2.0": true,
            "Gigabyte AORUS RTX3080 XTREME WATERFORCE WB 10G": true,
            "Gigabyte AORUS RTX3080 XTREME WATERFORCE WB 12G LHR": true,
            "Gigabyte AORUS RTX3090 XTREME WATERFORCE 24G": true,
            "Gigabyte AORUS RTX3090 XTREME WATERFORCE WB 24G": true,
            "Gigabyte AORUS RTX4080 MASTER 16G": true,
            "Gigabyte AORUS RTX4090 MASTER 24G": true,
            "Gigabyte Aorus M2": true,
            "Gigabyte GTX1050 Ti G1 Gaming": true,
            "Gigabyte GTX1050 Ti G1 Gaming (rev A1)": true,
            "Gigabyte GTX1060 G1 Gaming 6G": true,
            "Gigabyte GTX1060 G1 Gaming 6G OC": true,
            "Gigabyte GTX1060 Xtreme Gaming V1": true,
            "Gigabyte GTX1060 Xtreme Gaming v2": true,
            "Gigabyte GTX1070 G1 Gaming 8G V1": true,
            "Gigabyte GTX1070 Ti 8G Gaming": true,
            "Gigabyte GTX1070 Xtreme Gaming": true,
            "Gigabyte GTX1080 G1 Gaming": true,
            "Gigabyte GTX1080 Ti 11G": true,
            "Gigabyte GTX1080 Ti Gaming OC 11G": true,
            "Gigabyte GTX1080 Ti Gaming OC BLACK 11G": true,
            "Gigabyte GTX1080 Ti Xtreme Edition": true,
            "Gigabyte GTX1080 Ti Xtreme Waterforce Edition": true,
            "Gigabyte GTX1650 Gaming OC": true,
            "Gigabyte GTX1660 Gaming OC 6G": true,
            "Gigabyte GTX1660 SUPER Gaming OC": true,
            "Gigabyte RGB": true,
            "Gigabyte RGB Fusion": true,
            "Gigabyte RGB Fusion 2 DRAM": true,
            "Gigabyte RGB Fusion 2 SMBus": true,
            "Gigabyte RGB Fusion 2 USB": true,
            "Gigabyte RGB Fusion GPU": true,
            "Gigabyte RGB Fusion2 GPU": true,
            "Gigabyte RTX2060 Gaming OC": true,
            "Gigabyte RTX2060 Gaming OC PRO": true,
            "Gigabyte RTX2060 Gaming OC PRO V2": true,
            "Gigabyte RTX2060 Gaming OC PRO White": true,
            "Gigabyte RTX2060 SUPER Gaming": true,
            "Gigabyte RTX2060 SUPER Gaming OC": true,
            "Gigabyte RTX2060 SUPER Gaming OC 3X 8G V2": true,
            "Gigabyte RTX2060 SUPER Gaming OC 3X White 8G": true,
            "Gigabyte RTX2070 Gaming OC 8G": true,
            "Gigabyte RTX2070 Gaming OC 8GC": true,
            "Gigabyte RTX2070 Windforce 8G": true,
            "Gigabyte RTX2070S Gaming OC": true,
            "Gigabyte RTX2070S Gaming OC 3X": true,
            "Gigabyte RTX2070S Gaming OC 3X White": true,
            "Gigabyte RTX2080 Gaming OC 8G": true,
            "Gigabyte RTX2080 Ti GAMING OC 11G": true,
            "Gigabyte RTX2080S Gaming OC 8G": true,
            "Gigabyte RTX3050 Gaming OC 8G": true,
            "Gigabyte RTX3060 EAGLE 12G LHR V2": true,
            "Gigabyte RTX3060 EAGLE OC 12G": true,
            "Gigabyte RTX3060 EAGLE OC 12G V2": true,
            "Gigabyte RTX3060 Gaming OC 12G": true,
            "Gigabyte RTX3060 Gaming OC 12G (rev. 2.0)": true,
            "Gigabyte RTX3060 Ti EAGLE OC 8G": true,
            "Gigabyte RTX3060 Ti EAGLE OC 8G V2.0 LHR": true,
            "Gigabyte RTX3060 Ti GAMING OC 8G": true,
            "Gigabyte RTX3060 Ti GAMING OC LHR 8G": true,
            "Gigabyte RTX3060 Ti GAMING OC PRO 8G": true,
            "Gigabyte RTX3060 Ti Gaming OC 8G": true,
            "Gigabyte RTX3060 Ti Gaming OC PRO 8G LHR": true,
            "Gigabyte RTX3060 Ti Vision OC 8G": true,
            "Gigabyte RTX3060 Vision OC 12G": true,
            "Gigabyte RTX3060 Vision OC 12G LHR": true,
            "Gigabyte RTX3060 Vision OC 12G v3.0": true,
            "Gigabyte RTX3070 Eagle OC 8G": true,
            "Gigabyte RTX3070 Eagle OC 8G V2.0 LHR": true,
            "Gigabyte RTX3070 Gaming OC 8G": true,
            "Gigabyte RTX3070 Gaming OC 8G v3.0 LHR": true,
            "Gigabyte RTX3070 MASTER 8G": true,
            "Gigabyte RTX3070 MASTER 8G LHR": true,
            "Gigabyte RTX3070 Ti EAGLE 8G": true,
            "Gigabyte RTX3070 Ti Gaming OC 8G": true,
            "Gigabyte RTX3070 Ti Vision OC 8G": true,
            "Gigabyte RTX3070 Vision 8G": true,
            "Gigabyte RTX3070 Vision 8G V2.0 LHR": true,
            "Gigabyte RTX3080 EAGLE OC 10G": true,
            "Gigabyte RTX3080 Gaming OC 10G": true,
            "Gigabyte RTX3080 Gaming OC 12G": true,
            "Gigabyte RTX3080 Ti EAGLE 12G": true,
            "Gigabyte RTX3080 Ti EAGLE OC 12G": true,
            "Gigabyte RTX3080 Ti Gaming OC 12G": true,
            "Gigabyte RTX3080 Ti Vision OC 12G": true,
            "Gigabyte RTX3080 Vision OC 10G": true,
            "Gigabyte RTX3080 Vision OC 10G (REV 2.0)": true,
            "Gigabyte RTX3090 Gaming OC 24G": true,
            "Gigabyte RTX3090 VISION OC 24G ": true,
            "Gigabyte RTX4070Ti Gaming OC 12G": true,
            "Gigabyte RTX4080 AERO OC 16G": true,
            "Gigabyte RTX4080 Eagle OC 16G": true,
            "Gigabyte RTX4080 Gaming OC 16G": true,
            "Gigabyte RTX4090 GAMING OC 24G": true,
            "Gigabyte Radeon RX 6700 XT GAMING OC 12G": true,
            "Glorious Model D / D-": true,
            "Glorious Model D / D- Wireless": true,
            "Glorious Model O / O-": true,
            "Glorious Model O / O- Wireless": true,
            "HP Omen 30L": true,
            "Holtek Mousemat": true,
            "Holtek USB Gaming Mouse": true,
            "HyperX Alloy Elite 2": true,
            "HyperX Alloy Elite 2 (HP)": true,
            "HyperX Alloy Elite RGB": true,
            "HyperX Alloy FPS RGB": true,
            "HyperX Alloy Origins": true,
            "HyperX Alloy Origins (HP)": true,
            "HyperX Alloy Origins 60": true,
            "HyperX Alloy Origins 60 (HP)": true,
            "HyperX Alloy Origins 65 (HP)": true,
            "HyperX Alloy Origins Core": true,
            "HyperX Alloy Origins Core (HP)": true,
            "HyperX DRAM": true,
            "HyperX DuoCast": true,
            "HyperX Fury Ultra": true,
            "HyperX Pulsefire Core": true,
            "HyperX Pulsefire Dart (Wired)": true,
            "HyperX Pulsefire Dart (Wireless)": true,
            "HyperX Pulsefire FPS Pro": true,
            "HyperX Pulsefire Haste": true,
            "HyperX Pulsefire Mat": true,
            "HyperX Pulsefire Mat RGB Mouse Pad XL": true,
            "HyperX Pulsefire Raid": true,
            "HyperX Pulsefire Surge": true,
            "HyperX Quadcast S": true,
            "Intel Arc A770 Limited Edition": true,
            "Ionico Keyboard": true,
            "Ionico Light Bar": true,
            "JSAUX RGB Docking Station": true,
            "KFA2 RTX 2070 EX": true,
            "KFA2 RTX 2080 EX OC": true,
            "KFA2 RTX 2080 Super EX OC": true,
            "KFA2 RTX 2080 TI EX OC": true,
            "KasaSmart": true,
            "Keychron Gaming Keyboard 1": true,
            "LED Strip": true,
            "LIFX": true,
            "Lego Dimensions Toypad Base": true,
            "Lenovo": true,
            "Lenovo 5 2020": true,
            "Lenovo 5 2021": true,
            "Lenovo 5 2022": true,
            "Lenovo Ideapad 3-15ach6": true,
            "Lenovo Legion 7 gen 5": true,
            "Lenovo Legion 7 gen 6": true,
            "Lenovo Legion 7S gen 5": true,
            "Lenovo Legion 7S gen 6": true,
            "Lenovo Legion Y740": true,
            "Lian Li O11 Dynamic - Razer Edition": true,
            "Lian Li Uni Hub": true,
            "Lian Li Uni Hub - AL": true,
            "Lian Li Uni Hub - SL V2": true,
            "Lian Li Uni Hub - SL V2 v0.5": true,
            "Linux LED": true,
            "Logitech G Pro (HERO) Gaming Mouse": true,
            "Logitech G Pro Gaming Mouse": true,
            "Logitech G Pro RGB Mechanical Gaming Keyboard": true,
            "Logitech G Pro Wireless Gaming Mouse": true,
            "Logitech G Pro Wireless Gaming Mouse (wired)": true,
            "Logitech G203 Lightsync": true,
            "Logitech G203 Prodigy": true,
            "Logitech G213": true,
            "Logitech G303 Daedalus Apex": true,
            "Logitech G403 Hero": true,
            "Logitech G403 Prodigy Gaming Mouse": true,
            "Logitech G403 Wireless Gaming Mouse": true,
            "Logitech G403 Wireless Gaming Mouse (wired)": true,
            "Logitech G502 Hero Gaming Mouse": true,
            "Logitech G502 Proteus Spectrum Gaming Mouse": true,
            "Logitech G502 Wireless Gaming Mouse": true,
            "Logitech G502 Wireless Gaming Mouse (wired)": true,
            "Logitech G512": true,
            "Logitech G512 RGB": true,
            "Logitech G560 Lightsync Speaker": true,
            "Logitech G610 Orion": true,
            "Logitech G633 Gaming Headset": true,
            "Logitech G703 Hero Wireless Gaming Mouse": true,
            "Logitech G703 Hero Wireless Gaming Mouse (wired)": true,
            "Logitech G703 Wireless Gaming Mouse": true,
            "Logitech G703 Wireless Gaming Mouse (wired)": true,
            "Logitech G733 Gaming Headset": true,
            "Logitech G810 Orion Spectrum": true,
            "Logitech G813 RGB Mechanical Gaming Keyboard": true,
            "Logitech G815 RGB Mechanical Gaming Keyboard": true,
            "Logitech G900 Wireless Gaming Mouse": true,
            "Logitech G900 Wireless Gaming Mouse (wired)": true,
            "Logitech G903 Hero Wireless Gaming Mouse": true,
            "Logitech G903 Hero Wireless Gaming Mouse (wired)": true,
            "Logitech G903 Wireless Gaming Mouse": true,
            "Logitech G903 Wireless Gaming Mouse (wired)": true,
            "Logitech G910 Orion Spark": true,
            "Logitech G910 Orion Spectrum": true,
            "Logitech G915 Wireless RGB Mechanical Gaming Keyboard": true,
            "Logitech G915 Wireless RGB Mechanical Gaming Keyboard (Wired)": true,
            "Logitech G915TKL Wireless RGB Mechanical Gaming Keyboard": true,
            "Logitech G915TKL Wireless RGB Mechanical Gaming Keyboard (Wired)": true,
            "Logitech G933 Lightsync Headset": true,
            "Logitech G935 Gaming Headset": true,
            "Logitech Powerplay Mat": true,
            "Logitech X56 Rhino Hotas Joystick": true,
            "Logitech X56 Rhino Hotas Throttle": true,
            "MSI 3-Zone Laptop": true,
            "MSI GPU": true,
            "MSI GeForce GTX 1070 Gaming X": true,
            "MSI GeForce GTX 1660 Gaming X 6G": true,
            "MSI GeForce GTX 1660 Super Gaming 6G": true,
            "MSI GeForce GTX 1660 Super Gaming X 6G": true,
            "MSI GeForce GTX 1660Ti Gaming 6G": true,
            "MSI GeForce GTX 1660Ti Gaming X 6G": true,
            "MSI GeForce RTX 2060 Gaming Z 6G": true,
            "MSI GeForce RTX 2060 Super ARMOR OC": true,
            "MSI GeForce RTX 2060 Super Gaming X": true,
            "MSI GeForce RTX 2070 ARMOR": true,
            "MSI GeForce RTX 2070 ARMOR OC": true,
            "MSI GeForce RTX 2070 Gaming": true,
            "MSI GeForce RTX 2070 Gaming Z": true,
            "MSI GeForce RTX 2070 SUPER ARMOR OC": true,
            "MSI GeForce RTX 2070 Super Gaming": true,
            "MSI GeForce RTX 2070 Super Gaming Trio": true,
            "MSI GeForce RTX 2070 Super Gaming X": true,
            "MSI GeForce RTX 2070 Super Gaming X Trio": true,
            "MSI GeForce RTX 2070 Super Gaming Z Trio": true,
            "MSI GeForce RTX 2080 Duke 8G OC": true,
            "MSI GeForce RTX 2080 Gaming Trio": true,
            "MSI GeForce RTX 2080 Gaming X Trio": true,
            "MSI GeForce RTX 2080 Sea Hawk EK X": true,
            "MSI GeForce RTX 2080 Super Gaming X Trio": true,
            "MSI GeForce RTX 2080Ti 11G Gaming X Trio": true,
            "MSI GeForce RTX 2080Ti Gaming X Trio": true,
            "MSI GeForce RTX 2080Ti Gaming Z Trio": true,
            "MSI GeForce RTX 2080Ti Sea Hawk EK X": true,
            "MSI GeForce RTX 3050 Gaming X 8G": true,
            "MSI GeForce RTX 3060 12G Gaming X Trio": true,
            "MSI GeForce RTX 3060 12G Gaming X Trio LHR": true,
            "MSI GeForce RTX 3060 12G Gaming Z Trio": true,
            "MSI GeForce RTX 3060 12GB Gaming X Trio": true,
            "MSI GeForce RTX 3060 Gaming X 12G": true,
            "MSI GeForce RTX 3060 Gaming X 12G (GA104)": true,
            "MSI GeForce RTX 3060 Gaming X 12G LHR": true,
            "MSI GeForce RTX 3060 Ti 8GB Gaming X LHR": true,
            "MSI GeForce RTX 3060 Ti 8GB Gaming X Trio": true,
            "MSI GeForce RTX 3060 Ti 8GB Gaming X Trio LHR": true,
            "MSI GeForce RTX 3070 8GB Gaming Trio": true,
            "MSI GeForce RTX 3070 8GB Gaming X Trio": true,
            "MSI GeForce RTX 3070 8GB Suprim": true,
            "MSI GeForce RTX 3070 8GB Suprim X": true,
            "MSI GeForce RTX 3070 8GB Suprim X LHR": true,
            "MSI GeForce RTX 3070 Ti 8GB Gaming X Trio": true,
            "MSI GeForce RTX 3070 Ti Suprim X 8G": true,
            "MSI GeForce RTX 3080 10GB Gaming X Trio": true,
            "MSI GeForce RTX 3080 10GB Gaming Z Trio": true,
            "MSI GeForce RTX 3080 10GB Gaming Z Trio LHR": true,
            "MSI GeForce RTX 3080 12GB Gaming Z Trio LHR": true,
            "MSI GeForce RTX 3080 Suprim X 10G": true,
            "MSI GeForce RTX 3080 Suprim X 10G LHR": true,
            "MSI GeForce RTX 3080 Suprim X 12G LHR": true,
            "MSI GeForce RTX 3080 Ti Gaming X Trio 12G": true,
            "MSI GeForce RTX 3080 Ti Suprim X 12G": true,
            "MSI GeForce RTX 3090 24GB Gaming X Trio": true,
            "MSI GeForce RTX 3090 Suprim 24G": true,
            "MSI GeForce RTX 3090 Suprim X 24G": true,
            "MSI GeForce RTX 3090 Ti Gaming X Trio 24G": true,
            "MSI GeForce RTX 3090 Ti Suprim X 24G": true,
            "MSI GeForce RTX 4070 12GB Gaming X Trio": true,
            "MSI GeForce RTX 4070Ti 12GB Gaming X Trio": true,
            "MSI GeForce RTX 4070Ti 12GB Suprim X Trio": true,
            "MSI GeForce RTX 4080 16GB Gaming X Trio": true,
            "MSI GeForce RTX 4080 16GB Suprim X": true,
            "MSI GeForce RTX 4090 16GB Suprim X": true,
            "MSI GeForce RTX 4090 24GB Gaming X Trio": true,
            "MSI GeForce RTX 4090 24GB Suprim Liquid X": true,
            "MSI GeForce RTX 4090 24GB Suprim X": true,
            "MSI Mystic Light MS_1562": true,
            "MSI Mystic Light MS_1563": true,
            "MSI Mystic Light MS_1564": true,
            "MSI Mystic Light MS_1720": true,
            "MSI Mystic Light MS_7B12": true,
            "MSI Mystic Light MS_7B16": true,
            "MSI Mystic Light MS_7B17": true,
            "MSI Mystic Light MS_7B18": true,
            "MSI Mystic Light MS_7B50": true,
            "MSI Mystic Light MS_7B85": true,
            "MSI Mystic Light MS_7B93": true,
            "MSI Mystic Light MS_7C34": true,
            "MSI Mystic Light MS_7C35": true,
            "MSI Mystic Light MS_7C36": true,
            "MSI Mystic Light MS_7C37": true,
            "MSI Mystic Light MS_7C56": true,
            "MSI Mystic Light MS_7C59": true,
            "MSI Mystic Light MS_7C60": true,
            "MSI Mystic Light MS_7C67": true,
            "MSI Mystic Light MS_7C71": true,
            "MSI Mystic Light MS_7C73": true,
            "MSI Mystic Light MS_7C75": true,
            "MSI Mystic Light MS_7C76": true,
            "MSI Mystic Light MS_7C77": true,
            "MSI Mystic Light MS_7C79": true,
            "MSI Mystic Light MS_7C80": true,
            "MSI Mystic Light MS_7C81": true,
            "MSI Mystic Light MS_7C82": true,
            "MSI Mystic Light MS_7C83": true,
            "MSI Mystic Light MS_7C84": true,
            "MSI Mystic Light MS_7C86": true,
            "MSI Mystic Light MS_7C87": true,
            "MSI Mystic Light MS_7C90": true,
            "MSI Mystic Light MS_7C91": true,
            "MSI Mystic Light MS_7C92": true,
            "MSI Mystic Light MS_7C94": true,
            "MSI Mystic Light MS_7C95": true,
            "MSI Mystic Light MS_7C98": true,
            "MSI Mystic Light MS_7D03": true,
            "MSI Mystic Light MS_7D06": true,
            "MSI Mystic Light MS_7D07": true,
            "MSI Mystic Light MS_7D08": true,
            "MSI Mystic Light MS_7D09": true,
            "MSI Mystic Light MS_7D13": true,
            "MSI Mystic Light MS_7D15": true,
            "MSI Mystic Light MS_7D17": true,
            "MSI Mystic Light MS_7D18": true,
            "MSI Mystic Light MS_7D19": true,
            "MSI Mystic Light MS_7D20": true,
            "MSI Mystic Light MS_7D25": true,
            "MSI Mystic Light MS_7D27": true,
            "MSI Mystic Light MS_7D28": true,
            "MSI Mystic Light MS_7D29": true,
            "MSI Mystic Light MS_7D30": true,
            "MSI Mystic Light MS_7D31": true,
            "MSI Mystic Light MS_7D32": true,
            "MSI Mystic Light MS_7D36": true,
            "MSI Mystic Light MS_7D38": true,
            "MSI Mystic Light MS_7D41": true,
            "MSI Mystic Light MS_7D42": true,
            "MSI Mystic Light MS_7D43": true,
            "MSI Mystic Light MS_7D46": true,
            "MSI Mystic Light MS_7D50": true,
            "MSI Mystic Light MS_7D51": true,
            "MSI Mystic Light MS_7D52": true,
            "MSI Mystic Light MS_7D53": true,
            "MSI Mystic Light MS_7D54": true,
            "MSI Mystic Light MS_7D59": true,
            "MSI Mystic Light MS_7D67": true,
            "MSI Mystic Light MS_7D69": true,
            "MSI Mystic Light MS_7D70": true,
            "MSI Mystic Light MS_7D73": true,
            "MSI Mystic Light MS_7D75": true,
            "MSI Mystic Light MS_7D76": true,
            "MSI Mystic Light MS_7D77": true,
            "MSI Mystic Light MS_7D78": true,
            "MSI Mystic Light MS_7D86": true,
            "MSI Mystic Light MS_7D89": true,
            "MSI Mystic Light MS_7D91": true,
            "MSI Mystic Light MS_7E01": true,
            "MSI Mystic Light MS_7E06": true,
            "MSI Mystic Light MS_7E07": true,
            "MSI Mystic Light MS_B926": true,
            "MSI Optix controller": true,
            "MSI Radeon RX 6600 XT Gaming X": true,
            "MSI Radeon RX 6700 XT Gaming X": true,
            "MSI Radeon RX 6750 XT Gaming X Trio 12G": true,
            "MSI Radeon RX 6800 Gaming X Trio": true,
            "MSI Radeon RX 6800 Gaming Z Trio v1": true,
            "MSI Radeon RX 6800 XT Gaming X Trio": true,
            "MSI Radeon RX 6800 XT Gaming Z Trio": true,
            "MSI Radeon RX 6900 XT Gaming X Trio": true,
            "MSI Radeon RX 6900 XT Gaming Z Trio": true,
            "MSI Radeon RX 6950 XT Gaming X Trio": true,
            "MSI Vigor GK30 controller": true,
            "MSI-RGB": true,
            "Mountain Everest": true,
            "N5312A USB Optical Mouse": true,
            "NVIDIA RTX2060S": true,
            "NVIDIA RTX2080S": true,
            "NZXT Hue 2": true,
            "NZXT Hue 2 Ambient": true,
            "NZXT Hue 2 Motherboard": true,
            "NZXT Hue+": true,
            "NZXT Kraken M2": true,
            "NZXT Kraken X2": true,
            "NZXT Kraken X3": true,
            "NZXT Kraken X3 Series": true,
            "NZXT Kraken X3 Series RGB": true,
            "NZXT RGB & Fan Controller": true,
            "NZXT RGB Controller": true,
            "NZXT Smart Device V1": true,
            "NZXT Smart Device V2": true,
            "Nanoleaf": true,
            "Nollie 32CH": true,
            "Np93 ALPHA - Gaming Mouse": true,
            "Nvidia ESA - Dell XPS 730x": true,
            "OKS Optical Axis RGB": true,
            "OpenRazer": false,
            "PNY GPU": true,
            "PNY XLR8 OC EDITION RTX 2060": true,
            "PNY XLR8 Revel EPIC-X RTX 3060": true,
            "PNY XLR8 Revel EPIC-X RTX 3070": true,
            "PNY XLR8 Revel EPIC-X RTX 3070 LHR": true,
            "PNY XLR8 Revel EPIC-X RTX 3080": true,
            "PNY XLR8 Revel EPIC-X RTX 3090": true,
            "Palit 1080": true,
            "Palit 3060": true,
            "Palit 3060 LHR": true,
            "Palit 3060TI LHR": true,
            "Palit 3060Ti": true,
            "Palit 3070": true,
            "Palit 3070 LHR": true,
            "Palit 3070Ti": true,
            "Palit 3070Ti GamingPro": true,
            "Palit 3080": true,
            "Palit 3080 Gamerock": true,
            "Palit 3080 Gamerock LHR": true,
            "Palit 3080 GamingPro 12G": true,
            "Palit 3080 LHR": true,
            "Palit 3080Ti": true,
            "Palit 3080Ti Gamerock": true,
            "Palit 3090": true,
            "Palit 3090 Gamerock": true,
            "Palit 4070Ti Gamerock": true,
            "Palit 4090 Gamerock": true,
            "Palit GeForce RTX 3060 Ti Dual": true,
            "Patriot Viper": true,
            "Patriot Viper Steel": true,
            "Philips Hue": true,
            "Philips Wiz": true,
            "Razer Abyssus Elite D.Va Edition": true,
            "Razer Abyssus Essential": true,
            "Razer Base Station Chroma": true,
            "Razer Base Station V2 Chroma": true,
            "Razer Basilisk": true,
            "Razer Basilisk Essential": true,
            "Razer Basilisk Ultimate (Wired)": true,
            "Razer Basilisk Ultimate (Wireless)": true,
            "Razer Basilisk V2": true,
            "Razer Basilisk V3": true,
            "Razer Basilisk V3 Pro (Wired)": true,
            "Razer Basilisk V3 Pro (Wireless)": true,
            "Razer Blackwidow 2019": true,
            "Razer Blackwidow Chroma": true,
            "Razer Blackwidow Chroma Tournament Edition": true,
            "Razer Blackwidow Chroma V2": true,
            "Razer Blackwidow Elite": true,
            "Razer Blackwidow Overwatch": true,
            "Razer Blackwidow V3": true,
            "Razer Blackwidow V3 Mini (Wired)": true,
            "Razer Blackwidow V3 Mini (Wireless)": true,
            "Razer Blackwidow V3 Pro (Wired)": true,
            "Razer Blackwidow V3 Pro (Wireless)": true,
            "Razer Blackwidow V3 TKL": true,
            "Razer Blackwidow X Chroma": true,
            "Razer Blackwidow X Chroma Tournament Edition": true,
            "Razer Blade (2016)": true,
            "Razer Blade (Late 2016)": true,
            "Razer Blade 14 (2021)": true,
            "Razer Blade 14 (2022)": true,
            "Razer Blade 15 (2018 Advanced)": true,
            "Razer Blade 15 (2018 Base)": true,
            "Razer Blade 15 (2018 Mercury)": true,
            "Razer Blade 15 (2019 Advanced)": true,
            "Razer Blade 15 (2019 Base)": true,
            "Razer Blade 15 (2019 Mercury)": true,
            "Razer Blade 15 (2019 Studio)": true,
            "Razer Blade 15 (2020 Advanced)": true,
            "Razer Blade 15 (2020 Base)": true,
            "Razer Blade 15 (2021 Advanced)": true,
            "Razer Blade 15 (2021 Base)": true,
            "Razer Blade 15 (2022)": true,
            "Razer Blade 15 (Late 2020)": true,
            "Razer Blade 15 (Late 2021 Advanced)": true,
            "Razer Blade Pro (2016)": true,
            "Razer Blade Pro (2017 FullHD)": true,
            "Razer Blade Pro (2017)": true,
            "Razer Blade Pro (2019)": true,
            "Razer Blade Pro (Late 2019)": true,
            "Razer Blade Pro 17 (2020)": true,
            "Razer Blade Pro 17 (2021)": true,
            "Razer Blade Stealth (2016)": true,
            "Razer Blade Stealth (2017)": true,
            "Razer Blade Stealth (2019)": true,
            "Razer Blade Stealth (2020)": true,
            "Razer Blade Stealth (Late 2016)": true,
            "Razer Blade Stealth (Late 2017)": true,
            "Razer Blade Stealth (Late 2019)": true,
            "Razer Blade Stealth (Late 2020)": true,
            "Razer Book 13 (2020)": true,
            "Razer Charging Pad Chroma": true,
            "Razer Chroma Addressable RGB Controller": true,
            "Razer Chroma HDK": true,
            "Razer Chroma Mug Holder": true,
            "Razer Chroma PC Case Lighting Kit": true,
            "Razer Core": true,
            "Razer Core X": true,
            "Razer Cynosa Chroma": true,
            "Razer Cynosa Chroma V2": true,
            "Razer Cynosa Lite": true,
            "Razer Deathadder Chroma": true,
            "Razer Deathadder Elite": true,
            "Razer Deathadder Essential": true,
            "Razer Deathadder Essential V2": true,
            "Razer Deathadder Essential White Edition": true,
            "Razer Deathadder V2": true,
            "Razer Deathadder V2 Mini": true,
            "Razer Deathadder V2 Pro (Wired)": true,
            "Razer Deathadder V2 Pro (Wireless)": true,
            "Razer Deathstalker Chroma": true,
            "Razer Deathstalker V2": true,
            "Razer Deathstalker V2 Pro (Wired)": true,
            "Razer Deathstalker V2 Pro (Wireless)": true,
            "Razer Diamondback": true,
            "Razer Firefly": true,
            "Razer Firefly Hyperflux": true,
            "Razer Firefly V2": true,
            "Razer Goliathus": true,
            "Razer Goliathus Extended": true,
            "Razer Huntsman": true,
            "Razer Huntsman Elite": true,
            "Razer Huntsman Mini": true,
            "Razer Huntsman Tournament Edition": true,
            "Razer Huntsman V2": true,
            "Razer Huntsman V2 Analog": true,
            "Razer Huntsman V2 TKL": true,
            "Razer Kraken 7.1": true,
            "Razer Kraken 7.1 Chroma": true,
            "Razer Kraken 7.1 V2": true,
            "Razer Kraken Kitty Black Edition": true,
            "Razer Kraken Kitty Edition": true,
            "Razer Kraken Ultimate": true,
            "Razer Lancehead 2017 (Wired)": true,
            "Razer Lancehead 2017 (Wireless)": true,
            "Razer Lancehead 2019 (Wired)": true,
            "Razer Lancehead 2019 (Wireless)": true,
            "Razer Lancehead Tournament Edition": true,
            "Razer Laptop Stand Chroma": true,
            "Razer Laptop Stand Chroma V2": true,
            "Razer Leviathan V2 X": true,
            "Razer Mamba 2012 (Wired)": true,
            "Razer Mamba 2012 (Wireless)": true,
            "Razer Mamba 2015 (Wired)": true,
            "Razer Mamba 2015 (Wireless)": true,
            "Razer Mamba 2018 (Wired)": true,
            "Razer Mamba 2018 (Wireless)": true,
            "Razer Mamba Elite": true,
            "Razer Mamba Tournament Edition": true,
            "Razer Mouse Bungee V3 Chroma": true,
            "Razer Mouse Dock Chroma": true,
            "Razer Mouse Dock Pro": true,
            "Razer Naga Chroma": true,
            "Razer Naga Classic": true,
            "Razer Naga Epic Chroma": true,
            "Razer Naga Hex V2": true,
            "Razer Naga Left Handed": true,
            "Razer Naga Pro (Wired)": true,
            "Razer Naga Pro (Wireless)": true,
            "Razer Naga Trinity": true,
            "Razer Nommo Chroma": true,
            "Razer Nommo Pro": true,
            "Razer Orbweaver Chroma": true,
            "Razer Ornata Chroma": true,
            "Razer Ornata Chroma V2": true,
            "Razer Ornata V3": true,
            "Razer Ornata V3 Rev2": true,
            "Razer Ornata V3 X": true,
            "Razer Seiren Emote": true,
            "Razer Strider Chroma": true,
            "Razer Tartarus Chroma": true,
            "Razer Tartarus Pro": true,
            "Razer Tartarus V2": true,
            "Razer Thunderbolt 4 Dock Chroma": true,
            "Razer Tiamat 7.1 V2": true,
            "Razer Viper": true,
            "Razer Viper 8kHz": true,
            "Razer Viper Mini": true,
            "Razer Viper Ultimate (Wired)": true,
            "Razer Viper Ultimate (Wireless)": true,
            "Red Square Keyrox TKL": true,
            "Red Square Keyrox TKL Classic": true,
            "Redragon M602 Griffin": true,
            "Redragon M711 Cobra": true,
            "Redragon M715 Dagger": true,
            "Redragon M716 Inquisitor": true,
            "Redragon M808 Storm": true,
            "Redragon M908 Impact": true,
            "Roccat Burst Core": true,
            "Roccat Burst Pro": true,
            "Roccat Elo 7.1": true,
            "Roccat Horde Aimo": true,
            "Roccat Kone Aimo": true,
            "Roccat Kone Aimo 16K": true,
            "Roccat Kova": true,
            "Roccat Vulcan 120 Aimo": true,
            "Roccat Vulcan 120-Series Aimo": true,
            "SRGBMods LED Controller v1": true,
            "SRGBmods Pico LED Controller": true,
            "Sapphire GPU": true,
            "Sapphire RX 470/480 Nitro+": true,
            "Sapphire RX 5500 XT Nitro+": true,
            "Sapphire RX 570/580/590 Nitro+": true,
            "Sapphire RX 5700 (XT) Nitro+": true,
            "Sapphire RX 5700 XT Nitro+": true,
            "Sapphire RX 580 Nitro+ (2048SP)": true,
            "Sapphire RX 6600 XT Nitro+": true,
            "Sapphire RX 6700 XT Nitro+": true,
            "Sapphire RX 6750 XT Nitro+": true,
            "Sapphire RX 6800 Nitro+": true,
            "Sapphire RX 6800 XT Nitro+ SE": true,
            "Sapphire RX 6800 XT/6900 XT Nitro+": true,
            "Sapphire RX 6900 XT Nitro+ SE": true,
            "Sapphire RX 6900 XT Toxic": true,
            "Sapphire RX 6900 XT Toxic Limited Edition": true,
            "Sapphire RX 6950 XT Nitro+": true,
            "Sapphire RX 7900 XTX Nitro+": true,
            "Sapphire RX Vega 56/64 Nitro+": true,
            "Sinowealth Keyboard": true,
            "Sony DualSense": true,
            "Sony DualShock 4": true,
            "SteelSeries Aerox 3 Wired": true,
            "SteelSeries Aerox 9 Wired": true,
            "SteelSeries Apex (OG)/Apex Fnatic": true,
            "SteelSeries Apex 3": true,
            "SteelSeries Apex 3 TKL": true,
            "SteelSeries Apex 350": true,
            "SteelSeries Apex 5": true,
            "SteelSeries Apex 7": true,
            "SteelSeries Apex 7 TKL": true,
            "SteelSeries Apex M750": true,
            "SteelSeries Apex Pro": true,
            "SteelSeries Apex Pro TKL": true,
            "SteelSeries Arctis 5": true,
            "SteelSeries QCK Prism Cloth": true,
            "SteelSeries QCK Prism Cloth 3XL": true,
            "SteelSeries QCK Prism Cloth 4XL": true,
            "SteelSeries QCK Prism Cloth Medium": true,
            "SteelSeries QCK Prism Cloth XL": true,
            "SteelSeries QCK Prism Cloth XL CS:GO Neon Rider Ed.": true,
            "SteelSeries QCK Prism Cloth XL Destiny Ed.": true,
            "SteelSeries Rival 100": true,
            "SteelSeries Rival 100 DotA 2 Edition": true,
            "SteelSeries Rival 105": true,
            "SteelSeries Rival 106": true,
            "SteelSeries Rival 110": true,
            "SteelSeries Rival 3": true,
            "SteelSeries Rival 3 (Old Firmware)": true,
            "SteelSeries Rival 300": true,
            "SteelSeries Rival 300 Black Ops Edition": true,
            "SteelSeries Rival 300 CS:GO Fade Edition": true,
            "SteelSeries Rival 300 CS:GO Fade Edition (stm32)": true,
            "SteelSeries Rival 300 CS:GO Hyperbeast Edition": true,
            "SteelSeries Rival 300 Dota 2 Edition": true,
            "SteelSeries Rival 300 HP Omen Edition": true,
            "SteelSeries Rival 310": true,
            "SteelSeries Rival 310 CS:GO Howl Edition": true,
            "SteelSeries Rival 310 PUBG Edition": true,
            "SteelSeries Rival 600": true,
            "SteelSeries Rival 600 Dota 2 Edition": true,
            "SteelSeries Rival 650": true,
            "SteelSeries Rival 650 Wireless": true,
            "SteelSeries Rival 700": true,
            "SteelSeries Rival 710": true,
            "SteelSeries Sensei 310": true,
            "SteelSeries Sensei TEN": true,
            "SteelSeries Sensei TEN CS:GO Neon Rider Edition": true,
            "SteelSeries Siberia 350": true,
            "Strimer L Connect": true,
            "Tecknet M008": true,
            "Thermaltake Poseidon Z RGB": true,
            "Thermaltake Riing (PID 0x1FA5)": true,
            "Thermaltake Riing (PID 0x1FA6)": true,
            "Thermaltake Riing (PID 0x1FA7)": true,
            "Thermaltake Riing (PID 0x1FA8)": true,
            "Thermaltake Riing (PID 0x1FA9)": true,
            "Thermaltake Riing (PID 0x1FAA)": true,
            "Thermaltake Riing (PID 0x1FAB)": true,
            "Thermaltake Riing (PID 0x1FAC)": true,
            "Thermaltake Riing (PID 0x1FAD)": true,
            "Thermaltake Riing (PID 0x1FAE)": true,
            "Thermaltake Riing (PID 0x1FAF)": true,
            "Thermaltake Riing (PID 0x1FB0)": true,
            "Thermaltake Riing (PID 0x1FB1)": true,
            "Thermaltake Riing (PID 0x1FB2)": true,
            "Thermaltake Riing (PID 0x1FB3)": true,
            "Thermaltake Riing (PID 0x1FB4)": true,
            "Thermaltake Riing (PID 0x1FB5)": true,
            "Thermaltake Riing Quad (PID 0x2260)": true,
            "Thermaltake Riing Quad (PID 0x2261)": true,
            "Thermaltake Riing Quad (PID 0x2262)": true,
            "Thermaltake Riing Quad (PID 0x2263)": true,
            "Thermaltake Riing Quad (PID 0x2264)": true,
            "Thermaltake Riing Quad (PID 0x2265)": true,
            "Thermaltake Riing Quad (PID 0x2266)": true,
            "Thermaltake Riing Quad (PID 0x2267)": true,
            "Thermaltake Riing Quad (PID 0x2268)": true,
            "Thermaltake Riing Quad (PID 0x2269)": true,
            "Thermaltake Riing Quad (PID 0x226A)": true,
            "Thermaltake Riing Quad (PID 0x226B)": true,
            "Thermaltake Riing Quad (PID 0x226C)": true,
            "Thermaltake Riing Quad (PID 0x226D)": true,
            "Thermaltake Riing Quad (PID 0x226E)": true,
            "Thermaltake Riing Quad (PID 0x226F)": true,
            "Thermaltake Riing Quad (PID 0x2270)": true,
            "ThingM blink(1) mk2": true,
            "Trust GXT 114": true,
            "Trust GXT 180": true,
            "ViewSonic Monitor XG270QG": true,
            "Wooting Keyboard": true,
            "Wooting ONE Keyboard": true,
            "Wooting One (Classic)": true,
            "Wooting One (Legacy)": true,
            "Wooting One (None)": true,
            "Wooting One (Xbox)": true,
            "Wooting TWO Keyboard": true,
            "Wooting TWO Keyboard HE": true,
            "Wooting TWO Keyboard LE": true,
            "Wooting Two (Classic)": true,
            "Wooting Two (Legacy)": true,
            "Wooting Two (None)": true,
            "Wooting Two (Xbox)": true,
            "Wooting Two 60HE (ARM) (Classic)": true,
            "Wooting Two 60HE (ARM) (None)": true,
            "Wooting Two 60HE (ARM) (Xbox)": true,
            "Wooting Two 60HE (Classic)": true,
            "Wooting Two 60HE (None)": true,
            "Wooting Two 60HE (Xbox)": true,
            "Wooting Two HE (ARM) (Classic)": true,
            "Wooting Two HE (ARM) (None)": true,
            "Wooting Two HE (ARM) (Xbox)": true,
            "Wooting Two HE (Classic)": true,
            "Wooting Two HE (None)": true,
            "Wooting Two HE (Xbox)": true,
            "Wooting Two LE (Classic)": true,
            "Wooting Two LE (None)": true,
            "Wooting Two LE (Xbox)": true,
            "XPG Spectrix S40G": true,
            "Yeelight": true,
            "ZET Blade Optical": true,
            "ZET Fury Pro": true,
            "ZET GAMING Edge Air Elit": true,
            "ZET GAMING Edge Air Elit (Wireless)": true,
            "ZET GAMING Edge Air Pro": true,
            "ZET GAMING Edge Air Pro (Wireless)": true,
            "ZOTAC GAMING GeForce RTX 2070 SUPER Twin Fan": true,
            "ZOTAC GAMING GeForce RTX 3070 Ti Trinity OC": true,
            "ZOTAC GAMING GeForce RTX 3080 Ti AMP Holo": true,
            "ZOTAC GAMING GeForce RTX 3090 AMP Extreme Holo": true,
            "ZOTAC GAMING GeForce RTX 4090 AMP Extreme AIRO": true,
            "ZOTAC GAMING GeForce RTX 4090 Trinity OC": true,
            "Zalman Z Sync": true,
            "iGame GeForce RTX 2070 SUPER Advanced OC-V": true,
            "iGame GeForce RTX 3060 Advanced OC 12G L-V": true,
            "iGame GeForce RTX 3060 Ti Advanced OC-V": true,
            "iGame GeForce RTX 3060 Ti Ultra W OC LHR-V": true,
            "iGame GeForce RTX 3060 Ultra W OC 12G L-V": true,
            "iGame GeForce RTX 3070 Advanced OC-V": true,
            "iGame GeForce RTX 3070 Ti Advanced OC-V": true,
            "iGame GeForce RTX 3070 Ti Ultra W OC LHR": true,
            "iGame GeForce RTX 3070 Ultra W OC LHR": true,
            "iGame GeForce RTX 3080 Ti Advanced OC-V": true,
            "iGame GeForce RTX 4070 Ti Advanced OC-V": true,
            "iGame GeForce RTX 4080 Ultra W OC-V": true
        }
    },
    "Gigabyte RGB Fusion 2 SMBus": {
        "SupportedDevices": [
            "B450 AORUS ELITE",
            "B450 AORUS M",
            "B450 AORUS PRO WIFI-CF",
            "B450 AORUS PRO-CF",
            "B450 AORUS PRO-CF4",
            "B450 I AORUS PRO WIFI-CF",
            "B450M DS3H-CF",
            "X399 AORUS XTREME-CF",
            "X399 DESIGNARE EX-CF",
            "X470 AORUS GAMING 5 WIFI",
            "X470 AORUS GAMING 7 WIFI-CF",
            "X470 AORUS GAMING 7 WIFI-50-CF",
            "X470 AORUS ULTRA GAMING",
            "X470 AORUS ULTRA GAMING-CF",
            "Z370 AORUS Gaming 5-CF"
        ]
    },
    "Theme": {
        "theme": "dark"
    },
    "UserInterface": {
        "exit_profile": {
            "profile_name": "",
            "set_on_exit": false
        },
        "geometry": {
            "height": 0,
            "load_geometry": false,
            "save_on_exit": false,
            "width": 0,
            "x": 0,
            "y": 0
        },
        "greyscale_tray_icon": false,
        "language": "default",
        "minimize_on_close": false
    }
}
  '';
};

  ## jellyfin-mpv-shim

home.file."${config.xdg.configHome}/jellyfin-mpv-shim/conf.json" = lib.mkIf config.confSymlinks.configs.jellyfinShim {
    text = ''
{
    "allow_transcode_to_h265": false,
    "always_transcode": false,
    "audio_output": "hdmi",
    "auto_play": true,
    "check_updates": true,
    "client_uuid": "b90d46ea-bbf6-41dc-93d6-5663d76fe12a",
    "connect_retry_mins": 0,
    "direct_paths": false,
    "discord_presence": false,
    "display_mirroring": false,
    "enable_gui": true,
    "enable_osc": true,
    "force_audio_codec": null,
    "force_set_played": false,
    "force_video_codec": null,
    "fullscreen": true,
    "health_check_interval": 300,
    "idle_cmd": null,
    "idle_cmd_delay": 60,
    "idle_ended_cmd": null,
    "idle_when_paused": false,
    "ignore_ssl_cert": true,
    "kb_debug": "~",
    "kb_fullscreen": "f",
    "kb_kill_shader": "k",
    "kb_menu": "c",
    "kb_menu_down": "down",
    "kb_menu_esc": "esc",
    "kb_menu_left": "left",
    "kb_menu_ok": "enter",
    "kb_menu_right": "right",
    "kb_menu_up": "up",
    "kb_next": ">",
    "kb_pause": "space",
    "kb_prev": "<",
    "kb_stop": "q",
    "kb_unwatched": "u",
    "kb_watched": "w",
    "lang": null,
    "lang_filter": "und,eng,jpn,mis,mul,zxx",
    "lang_filter_audio": false,
    "lang_filter_sub": false,
    "local_kbps": 2147483,
    "log_decisions": false,
    "media_ended_cmd": null,
    "media_key_seek": false,
    "media_keys": true,
    "menu_mouse": true,
    "mpv_ext": false,
    "mpv_ext_ipc": null,
    "mpv_ext_no_ovr": false,
    "mpv_ext_path": null,
    "mpv_ext_start": true,
    "mpv_log_level": "info",
    "notify_updates": true,
    "play_cmd": null,
    "playback_timeout": 30,
    "player_name": "gibson",
    "pre_media_cmd": null,
    "prefer_transcode_to_h265": false,
    "raise_mpv": true,
    "remote_direct_paths": false,
    "remote_kbps": 10000,
    "sanitize_output": true,
    "screenshot_dir": null,
    "screenshot_menu": true,
    "seek_down": -60,
    "seek_h_exact": false,
    "seek_left": -5,
    "seek_right": 5,
    "seek_up": 60,
    "seek_v_exact": false,
    "shader_pack_custom": false,
    "shader_pack_enable": true,
    "shader_pack_profile": null,
    "shader_pack_remember": true,
    "shader_pack_subtype": "lq",
    "skip_intro_always": false,
    "skip_intro_prompt": false,
    "stop_cmd": null,
    "stop_idle": false,
    "subtitle_color": "#FFFFFFFF",
    "subtitle_position": "bottom",
    "subtitle_size": 100,
    "svp_enable": false,
    "svp_socket": null,
    "svp_url": "http://127.0.0.1:9901/",
    "sync_attempts": 5,
    "sync_max_delay_skip": 300,
    "sync_max_delay_speed": 50,
    "sync_method_thresh": 2000,
    "sync_osd_message": true,
    "sync_revert_seek": true,
    "sync_speed_attempts": 3,
    "sync_speed_time": 1000,
    "thumbnail_enable": true,
    "thumbnail_jellyscrub": false,
    "thumbnail_osc_builtin": true,
    "thumbnail_preferred_size": 320,
    "transcode_dolby_vision": true,
    "transcode_hdr": false,
    "transcode_hi10p": false,
    "transcode_warning": true,
    "use_web_seek": false,
    "write_logs": false
}
  '';
};

home.file."${config.xdg.configHome}/jellyfin-mpv-shim/input.json" = lib.mkIf config.confSymlinks.configs.jellyfinShim {
    text = ''
q run "/bin/sh" "-c" "hyprctl --batch 'dispatch killactive; dispatch workspace m-1'"
  '';
};

home.file."${config.xdg.configHome}/jellyfin-mpv-shim/mpv.json" = lib.mkIf config.confSymlinks.configs.jellyfinShim {
    text = ''
ao=%8%pipewire
cache=%3%yes
demuxer-max-bytes=%2%1G
geometry=%11%25%+10+10/1
gpu-context=%7%wayland
hwdec=%5%vaapi
ontop=%3%yes
osc=%3%yes
save-position-on-quit=%3%yes
stream-buffer-size=%4%5MiB
user-agent=%11%Mozilla/5.0
vo=%14%dmabuf-wayland
volume=%2%70
ytdl-format=%19%bestvideo+bestaudio
  '';
};

  ## Streamdeck

home.file."${config.xdg.configHome}/streamdeck-ui/streamdeck_ui.json" = lib.mkIf config.confSymlinks.configs.streamdeckui {
    text = ''
{
    "state": {
        "AL26H1A03798": {
            "buttons": {
                "0": {
                    "0": {
                        "state": 1,
                        "states": {
                            "0": {
                                "text": "",
                                "icon": "/home/rickie/Sync/Files/obs-studio/StreamDeck_Icons/streaming-streaming[on].svg",
                                "keys": "",
                                "write": "",
                                "command": "obs-cmd -w obsws://localhost:4455/aZ6ReAkavhmGXkzZ streaming toggle",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 2,
                                "text_vertical_align": "",
                                "text_horizontal_align": "",
                                "font": "",
                                "font_color": "",
                                "font_size": 0,
                                "background_color": ""
                            },
                            "1": {
                                "text": "",
                                "icon": "/home/rickie/Sync/Files/obs-studio/StreamDeck_Icons/streaming-streaming[off].svg",
                                "keys": "",
                                "write": "",
                                "command": "obs-cmd -w obsws://localhost:4455/aZ6ReAkavhmGXkzZ streaming toggle",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 1,
                                "text_vertical_align": "",
                                "text_horizontal_align": "",
                                "font": "",
                                "font_color": "",
                                "font_size": 0,
                                "background_color": ""
                            }
                        }
                    },
                    "1": {
                        "state": 1,
                        "states": {
                            "0": {
                                "text": "",
                                "icon": "/home/rickie/Sync/Files/obs-studio/StreamDeck_Icons/streaming-record[on].svg",
                                "keys": "",
                                "write": "",
                                "command": "obs-cmd -w obsws://localhost:4455/aZ6ReAkavhmGXkzZ recording toggle",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 2,
                                "text_vertical_align": "",
                                "text_horizontal_align": "",
                                "font": "",
                                "font_color": "",
                                "font_size": 0,
                                "background_color": ""
                            },
                            "1": {
                                "text": "",
                                "icon": "/home/rickie/Sync/Files/obs-studio/StreamDeck_Icons/streaming-record[off].svg",
                                "keys": "",
                                "write": "",
                                "command": "obs-cmd -w obsws://localhost:4455/aZ6ReAkavhmGXkzZ recording toggle",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 1,
                                "text_vertical_align": "",
                                "text_horizontal_align": "",
                                "font": "",
                                "font_color": "",
                                "font_size": 0,
                                "background_color": ""
                            }
                        }
                    },
                    "2": {
                        "state": 0,
                        "states": {
                            "0": {
                                "text": "",
                                "icon": "",
                                "keys": "",
                                "write": "",
                                "command": "",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 0,
                                "text_vertical_align": "",
                                "text_horizontal_align": "",
                                "font": "",
                                "font_color": "",
                                "font_size": 0,
                                "background_color": ""
                            }
                        }
                    },
                    "3": {
                        "state": 0,
                        "states": {
                            "0": {
                                "text": "",
                                "icon": "",
                                "keys": "",
                                "write": "",
                                "command": "",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 0,
                                "text_vertical_align": "",
                                "text_horizontal_align": "",
                                "font": "",
                                "font_color": "",
                                "font_size": 0,
                                "background_color": ""
                            }
                        }
                    },
                    "4": {
                        "state": 0,
                        "states": {
                            "0": {
                                "text": "",
                                "icon": "",
                                "keys": "",
                                "write": "",
                                "command": "",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 0,
                                "text_vertical_align": "",
                                "text_horizontal_align": "",
                                "font": "",
                                "font_color": "",
                                "font_size": 0,
                                "background_color": ""
                            }
                        }
                    },
                    "5": {
                        "state": 1,
                        "states": {
                            "1": {
                                "text": "",
                                "icon": "/home/rickie/Sync/Files/obs-studio/StreamDeck_Icons/scenes-starting[on].svg",
                                "keys": "",
                                "write": "",
                                "command": "obs-cmd -w obsws://localhost:4455/aZ6ReAkavhmGXkzZ scene starting Starting",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 1,
                                "text_vertical_align": "",
                                "text_horizontal_align": "",
                                "font": "",
                                "font_color": "",
                                "font_size": 0,
                                "background_color": ""
                            }
                        }
                    },
                    "6": {
                        "state": 1,
                        "states": {
                            "1": {
                                "text": "",
                                "icon": "/home/rickie/Sync/Files/obs-studio/StreamDeck_Icons/scenes-gameplay[on].svg",
                                "keys": "",
                                "write": "",
                                "command": "obs-cmd -w obsws://localhost:4455/aZ6ReAkavhmGXkzZ scene live Live",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 1,
                                "text_vertical_align": "",
                                "text_horizontal_align": "",
                                "font": "",
                                "font_color": "",
                                "font_size": 0,
                                "background_color": ""
                            }
                        }
                    },
                    "7": {
                        "state": 0,
                        "states": {
                            "0": {
                                "text": "AFK\nBOI",
                                "icon": "",
                                "keys": "",
                                "write": "",
                                "command": "obs-cmd -w obsws://localhost:4455/aZ6ReAkavhmGXkzZ scene afk AFK",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 0,
                                "text_vertical_align": "middle-top",
                                "text_horizontal_align": "",
                                "font": "${pkgs.google-fonts}/share/fonts/truetype/Silkscreen-Regular.ttf",
                                "font_color": "",
                                "font_size": 22,
                                "background_color": "#aa55ff"
                            }
                        }
                    },
                    "8": {
                        "state": 0,
                        "states": {
                            "0": {
                                "text": "",
                                "icon": "/home/rickie/Sync/Files/obs-studio/StreamDeck_Icons/sources-facecam[on].svg",
                                "keys": "",
                                "write": "",
                                "command": "obs-cmd -w obsws://localhost:4455/aZ6ReAkavhmGXkzZ scene facecam Facecam",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 0,
                                "text_vertical_align": "",
                                "text_horizontal_align": "",
                                "font": "",
                                "font_color": "",
                                "font_size": 0,
                                "background_color": ""
                            }
                        }
                    },
                    "9": {
                        "state": 0,
                        "states": {
                            "0": {
                                "text": "",
                                "icon": "/home/rickie/Sync/Files/obs-studio/StreamDeck_Icons/scenes-ended[on].svg",
                                "keys": "",
                                "write": "",
                                "command": "obs-cmd -w obsws://localhost:4455/aZ6ReAkavhmGXkzZ scene finish Finish",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 0,
                                "text_vertical_align": "",
                                "text_horizontal_align": "",
                                "font": "",
                                "font_color": "",
                                "font_size": 0,
                                "background_color": ""
                            }
                        }
                    },
                    "10": {
                        "state": 0,
                        "states": {
                            "0": {
                                "text": "",
                                "icon": "/home/rickie/Sync/Files/obs-studio/StreamDeck_Icons/music-music-play.svg",
                                "keys": "",
                                "write": "",
                                "command": "playerctl -p cider play-pause",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 2,
                                "text_vertical_align": "",
                                "text_horizontal_align": "",
                                "font": "",
                                "font_color": "",
                                "font_size": 0,
                                "background_color": ""
                            },
                            "1": {
                                "text": "",
                                "icon": "/home/rickie/Sync/Files/obs-studio/StreamDeck_Icons/music-music-pause.svg",
                                "keys": "",
                                "write": "",
                                "command": "playerctl -p cider play-pause",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 1,
                                "text_vertical_align": "",
                                "text_horizontal_align": "",
                                "font": "",
                                "font_color": "",
                                "font_size": 0,
                                "background_color": ""
                            }
                        }
                    },
                    "11": {
                        "state": 1,
                        "states": {
                            "0": {
                                "text": "",
                                "icon": "/home/rickie/Sync/Files/obs-studio/StreamDeck_Icons/settings-mic[on].svg",
                                "keys": "",
                                "write": "",
                                "command": "obs-cmd -w obsws://localhost:4455/aZ6ReAkavhmGXkzZ toggle-mute \"Mic/Aux\"",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 2,
                                "text_vertical_align": "middle",
                                "text_horizontal_align": "",
                                "font": "${pkgs.google-fonts}/share/fonts/truetype/Silkscreen-Regular.ttf",
                                "font_color": "",
                                "font_size": 0,
                                "background_color": ""
                            },
                            "1": {
                                "text": "",
                                "icon": "/home/rickie/Sync/Files/obs-studio/StreamDeck_Icons/settings-mic[off].svg",
                                "keys": "",
                                "write": "",
                                "command": "obs-cmd -w obsws://localhost:4455/aZ6ReAkavhmGXkzZ toggle-mute \"Mic/Aux\"",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 1,
                                "text_vertical_align": "top",
                                "text_horizontal_align": "",
                                "font": "${pkgs.google-fonts}/share/fonts/truetype/Silkscreen-Regular.ttf",
                                "font_color": "",
                                "font_size": 0,
                                "background_color": ""
                            }
                        }
                    },
                    "12": {
                        "state": 0,
                        "states": {
                            "0": {
                                "text": "ON",
                                "icon": "/home/rickie/Sync/Files/obs-studio/StreamDeck_Icons/settings-camera-generic[on].svg",
                                "keys": "",
                                "write": "",
                                "command": "obs-cmd -w obsws://localhost:4455/aZ6ReAkavhmGXkzZ scene-item toggle Live \"Cam + Border\"",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 2,
                                "text_vertical_align": "middle-bottom",
                                "text_horizontal_align": "",
                                "font": "${pkgs.google-fonts}/share/fonts/truetype/Silkscreen-Regular.ttf",
                                "font_color": "",
                                "font_size": 12,
                                "background_color": ""
                            },
                            "1": {
                                "text": "Off",
                                "icon": "/home/rickie/Sync/Files/obs-studio/StreamDeck_Icons/settings-camera-generic[off].svg",
                                "keys": "",
                                "write": "",
                                "command": "obs-cmd -w obsws://localhost:4455/aZ6ReAkavhmGXkzZ scene-item toggle Live \"Cam + Border\"",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 1,
                                "text_vertical_align": "middle-bottom",
                                "text_horizontal_align": "",
                                "font": "${pkgs.google-fonts}/share/fonts/truetype/Silkscreen-Regular.ttf",
                                "font_color": "",
                                "font_size": 12,
                                "background_color": ""
                            }
                        }
                    },
                    "13": {
                        "state": 0,
                        "states": {
                            "0": {
                                "text": "",
                                "icon": "",
                                "keys": "",
                                "write": "",
                                "command": "",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 0,
                                "text_vertical_align": "",
                                "text_horizontal_align": "",
                                "font": "",
                                "font_color": "",
                                "font_size": 0,
                                "background_color": ""
                            }
                        }
                    },
                    "14": {
                        "state": 0,
                        "states": {
                            "0": {
                                "text": "",
                                "icon": "",
                                "keys": "",
                                "write": "",
                                "command": "",
                                "brightness_change": 0,
                                "switch_page": 0,
                                "switch_state": 0,
                                "text_vertical_align": "",
                                "text_horizontal_align": "",
                                "font": "",
                                "font_color": "",
                                "font_size": 0,
                                "background_color": ""
                            }
                        }
                    }
                }
            },
            "display_timeout": 1800,
            "brightness": 99,
            "brightness_dimmed": 0,
            "rotation": 0,
            "page": 0
        }
    },
    "streamdeck_ui_version": 2
}
  '';
};

home.file."${config.xdg.configHome}/streamdeck-ui/streamdeck_ui.conf" = lib.mkIf config.confSymlinks.configs.jellyfinShim {
    text = ''
[General]
geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\xf\x80\0\0\0\xa0\0\0\x13\x8e\0\0\x4\xa3\0\0\0\0\0\0\0\xc8\0\0\x3\x88\0\0\x2\xf9\0\0\0\x2\x2\0\0\0\a\x80\0\0\xf\x80\0\0\0\xa0\0\0\x13\x8e\0\0\x4\xa3)
  '';
    };
  }; # End Config
}
