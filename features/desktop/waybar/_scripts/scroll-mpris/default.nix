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

  # The marquee joins the title's end to its start with a hard-coded three
  # spaces, which reads as a gap. A pipe marks the seam instead. It's still
  # three characters, so the scroll window keeps its width. --replace-fail
  # stops the build if upstream changes that line.
  postPatch = ''
    substituteInPlace src/scroll.rs \
      --replace-fail 'pub const WRAP_SPACER: &str = "   ";' \
                     'pub const WRAP_SPACER: &str = " | ";'
  '';

  # Catch upstream renaming or removing one of the flags in args.
  # --generate-config exits after argument parsing, before D-Bus.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/ScrollMPRIS ${pkgs.lib.escapeShellArgs args} --generate-config >/dev/null
    runHook postInstallCheck
  '';
}
