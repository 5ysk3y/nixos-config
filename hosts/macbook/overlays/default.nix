{
  config,
  pkgs,
  lib,
  vars,
  inputs,
  ...
}:
{
  nixpkgs.overlays = [
    (_final: prev: {
      # Can be rm'd when this merges into nixos-unstable: https://github.com/NixOS/nixpkgs/pull/493943
      yt-dlp = prev.yt-dlp.overridePythonAttrs (override: {
        dependencies = __filter (
          dep:
          !(__elem dep.pname [
            "cffi"
            "secretstorage"
          ])
        ) override.dependencies;
      });
    })
  ];
}
