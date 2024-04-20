## Custom Configuration Module

The purpose of this module is to setup existing configuration for the following services, either by way of symlinks or embedded config within Nix itself:

- Cider (External symlink) = False by default : cider
- GNUPG (External symlink) = True by default : gnupg
- Jellyfin MPV Shim (Embedded Config) = False by default : jellyfinShim
- OpenRGB (Embedded Config) = False by default : openrgb
- QPWGraph (Embedded Config) = qpwgraph = False by default : qpwgraph
- SSH (External Symlink) = ssh = True by default : ssh
- StreamdeckUI (Embedded Config) = streamdeckui = False by default : streamdeckui

By default, the confSymlink set is enabled but the above defaults are used for each individual service unless specified otherwise.

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
