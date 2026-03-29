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
    (final: prev: {
      # Can be rm'd once upstream merge lands in nixos-unstable (https://nixpk.gs/pr-tracker.html?pr=503376)
      mailutils = prev.mailutils.overrideAttrs (old: {
        nativeCheckInputs = builtins.filter (pkg: pkg != prev.nss_wrapper) (old.nativeCheckInputs or [ ]);

        preCheck = "";
        doCheck = false;
      });
    })
  ];
}
