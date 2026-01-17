## Custom Scripts Module

The purpose of this module is to make a number of custom/grouped scripts togglable so that other applications can use them. They are grouped by sane names, e.g:

* Scripts
  * Enable = Collectively enable the following general scripts:
  * Gaming = Cleanup script, post-gameage
  * Nix = Some nix specific custom scripts

By default, all scripts are set to the defaults shown in the below example unless specified otherwise.

#### What are these scripts?

*General Scripts*

##### Gaming

- `game_cleanup` - Basically it pgreps and kills off wine/gamescope/lutris/heroic processes. I configure launcher to run this as an exit script to ensure I dont have any lingering procs.

##### Nix

- `queryUpdates` - A really poor attempt to show updates between the last/latest home-manager and nix derivations. If you switch a lot don't expect this to be of use. It's only really useful if ran straight after a system update and should show you what pkgs have changed.

#### Examples:

Defining options is done like so, enabling you to pick and choose:

``` nix
scripts = {
  enable = false; # If set to false, gaming/nix won't activate.
  gaming = true; # These exist to allow for independent toggling as necessary.
  nix = true;
};
```

**These represent all available options as well as their default values.**

In this over-engineered example, despite all scripts being individually enabled they won't activate as both `scripts.enable` and `waybar.enable` are disabled as default. The idea is that you set them to true and disable individual scripts as you wish.
