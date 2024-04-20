## Custom Scripts Module

The purpose of this module is to make a number of custom/grouped scripts togglable so that other applications can use them. They are grouped by sane names, e.g:

* Scripts
  * Enable = Collectively enable the following general scripts:
  * Gaming = Cleanup script, post-gameage
  * Nix = Some nix specific custom scripts
  * Qutebrowser = Userscripts 
  * Waybar
    * Enable = Collectively enable the following waybar scripts:
    * Check RBW = Shows icon based on bitwarden lock/unlock status
    * Music Panel = Shows currently playing song from Cider
    * Mouse Info = Shows bluetooth battery for mouse, charge state etc

By default, all scripts are set to the defaults shown in the below example unless specified otherwise.

***

> Note: Sub-catagories of `scripts`, .e.g `waybar` can have their enable mode set to true/false independently of the enable mode of the parent scripts option. That is to say `scripts.enable = false` != `scripts.waybar.enable = false`. Waybar scripts will be enabled if set to true.

***

#### What are these scripts?

*General Scripts*

##### Gaming

- `game_cleanup` - Basically it pgreps and kills off wine/gamescope/lutris-wrapper processes. I configure Lutris to run this as an exit script to ensure I dont have any lingering procs.

##### Nix

- `queryUpdates` - A really poor attempt to show updates between the last/latest home-manager and nix derivations. If you switch a lot don't expect this to be of use. It's only really useful if ran straight after a system update and should show you what pkgs have changed.

##### Qutebrowser

- `qute-rbw` - This is a qutebrowser script to spawn agent-based `pkgs.rbw-rofi-wayland`. It checks to see if the configured Bitwarden vault is unlocked first and, if not, prompts you to unlock it via a spawned terminal window + pinentry. If unlocked successfully itll spawn [rofi-rbw](https://github.com/fdw/rofi-rbw) on top of qutebrowser, which can then be used to pass logins. TOTPs are also copied to the clipboard.

***

*Waybar Scripts*

##### Check RBW

- `check_rbw` - A simple script that uses `rbw` to check the state of the configured Bitwarden vault. It then shows a closed/open padlock in Waybar based on the result. Handy when you just want to check if you're vault is unlocked at a glance.

##### Music Panel

- `current_song` - Spits out the artist/title for the song currently playing in `pkgs.cider`. Also reports the player state, e.g. offline, paused etc, if nothing is playing.

- `music_panel` - A [zscroll](https://github.com/noctuid/zscroll) wrapper for `current_song` to enable waybar to scroll the artist/title metadata if its character set exceeds a certain length. 

##### Mouse Info

- `mouse_battery` - A wrapper to report the battery for my Aerox 3 Wireless mouse. It uses bluetoothctl by default, unless the device is plugged in at which point it uses [rivalcfg](https://github.com/flozz/rivalcfg). It also appends an icon if the device is plugged in, a la charging.

- `mouse_colour` - The script executed when the waybar mouse battery module is clicked, setting the default colour settings for the mouse.

***

#### Examples:

Defining options is done like so, enabling you to pick and choose:

``` nix
scripts = {
  enable = false; # If set to false, gaming/nix/qutebrowser won't activate.
  gaming = true; # These exist to allow for independent toggling as necessary.
  nix = true;
  qutebrowser = true;
  waybar = {
    enable = false;
    check_rbw = true; 
    music_panel = true; 
    mouse_info = true; 
  };
};
```

**These represent all available options as well as their default values.**

In this over-engineered example, despite all scripts being individually enabled they won't activate as both `scripts.enable` and `waybar.enable` are disabled as default. The idea is that you set them to true and disable individual scripts as you wish.

***

In this example we explicitly disable general `scripts` (e.g. all categories under it: gaming/nix/qutebrowser), however we enable `waybar` scripts with `check_rbw` explicitly disabled. This means all waybar scripts will be turned on, as they are by default, *except* `check_rbw`. All non-waybar scripts will remain disabled:

``` nix
scripts = {
  enable = false; # If set to false, gaming/nix/qutebrowser won't activate.
  waybar = {
    enable = true;
    check_rbw = false; 
  };
};
```

When I get round to modularising waybar/hypr configuration, I'll likely set some elements to enable scripts based on specific hosts, or perhaps what services are enabled etc.
