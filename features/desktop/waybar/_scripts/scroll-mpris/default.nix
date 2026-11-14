{
  pkgs,
  inputs,
  # The flags waybar's custom/media passes; checked in installCheckPhase.
  args,
  ...
}:
# Not my repo - Check it out here: https://github.com/BEST8OY/ScrollMPRIS
let
  src = inputs.scroll-mpris;
  cargoToml = pkgs.lib.importTOML "${src}/Cargo.toml";
in
pkgs.rustPlatform.buildRustPackage {
  pname = "scroll-mpris";
  version = "${cargoToml.package.version}-unstable-${src.lastModifiedDate}";
  inherit src;
  cargoLock.lockFile = "${src}/Cargo.lock";

  # Catch upstream renaming or removing one of the flags in args.
  # --generate-config exits after argument parsing, before D-Bus.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/ScrollMPRIS ${pkgs.lib.escapeShellArgs args} --generate-config >/dev/null
    runHook postInstallCheck
  '';
}
