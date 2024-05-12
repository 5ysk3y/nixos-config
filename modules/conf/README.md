## Custom Configuration Module

The purpose of this module is to setup configuration files for applications that dont have native nix or home-manager modules. Right now configuration can be toggled for the following services, and they are applied either by way of symlinks to existing files or embedded config within Nix itself:

| Name              | Applied? | Key          | Default |
|-------------------|----------|--------------|---------|
| Cider             | symlink  | cider        | false   |
| GNUPG             | symlink  | gnupg        | true    |
| Jellyfin MPV Shim | embedded | jellyfinShim | false   |
| OpenRGB           | embedded | openrgb      | false   |
| QPWGraph          | embedded | qpwgraph     | false   |
| Rofi              | embedded | n/a          | n/a     |
| SSH               | symlink  | ssh          | true    |
| StreamdeckUI      | embedded | streamdeckui | false   |

By default, the confSymlink set is enabled but the above defaults are used for each individual service unless specified otherwise.

The only non-configurable option in this module is `rofi` which is included automatically when `applications.qutebrowser` is enabled in home.nix, and is there to theme rofi for qutebrowsers password manager `rofi-rbw`.

#### Example:

Defining options is done like so:

``` nix
confSymlinks = {
  enable = false;
};
```

Or:

``` nix
confSymlinks = {
  configs = {
    jellyfinShim = true;
    streamdeckui = true;
    gnupg = false;
  };
};
```

Additional configuration, like obs-studio, is included but will automatically link if the service/program is enabled. Most, if not all, external symlinks link to `/home/${username}/Sync` as thats the default folder for Syncthing.
