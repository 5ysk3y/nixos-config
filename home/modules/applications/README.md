## Custom Applications Module

The purpose of this module is to wrap around a number of existing Nix packages and their options, enabling them and making per-host config available.

* Applications
  * Hypr = Collectively enable all hypr* applications
    * Hyprland = Toggles hyprland inclusive of per-host config
    * Hypridle = Toggles hypridle inclusive of per-host config
    * Hyprlock = Toggles hyprlock inclusive of per-host config
  * DoomEmacs = Toggles emacs, doom and custom config files
  * Qutebrowser = Toggles qutebrowser, inclusive of themes, keybinds etc
  * Fuzzel = Toggles fuzzel inclusive of per-host config

By default, all scripts are set to the defaults shown in the below example unless specified otherwise.

***

> Note: `hypr.apps`-based applications, .e.g `hyprland` are enabled individually by default however the master enable toggle (e.g. `hypr.enable`) is turned off. Enabling it will turn on all hypr* applications unless you specifically turn certain ones off.

***

#### Examples:

Defining certain applications is done like so, enabling you to pick and choose:

``` nix
applications = {
  hypr = {
    enable = false;
    apps = {
      hyprland = true;
      hypridle = true;
      hyprlock = true;
    };
  };
  waybar = true;
  doomemacs = true;
  qutebrowser = true;
  fuzzel = true;
};
```

**These represent all available options as well as their default values.**

In this example, despite the individual `hypr` apps being enabled, it will not activate the them as the parent enable option is false by default. You can enable such apps by setting this to true and then setting each individual app false based on preference. You can also explicitly define them as true but they are set to true by default as stated.

***

In this example we explicitly enable the hypr set of applications but then turn off hypridle and hyprlock, meaning that only hyprland will be installed. We've also explicitly turned off fuzzel so that also will not install.

``` nix
applications = {
  hypr = {
    enable = true;
    apps = {
      hypridle = false;
      hyprlock = false;
    };
  };
  fuzzel = false;
};
```
