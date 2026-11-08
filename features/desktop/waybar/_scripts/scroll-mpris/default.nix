{ pkgs, ... }:
# Not my repo - Check it out here: https://github.com/BEST8OY/ScrollMPRIS
with pkgs;
rustPlatform.buildRustPackage {
  pname = "scroll-mpris";
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "BEST8OY";
    repo = "ScrollMPRIS";
    rev = "3e393327eff442ac74b4babbecc84dc2da82b2b6";
    sha256 = "sha256-KWEKD5NmeMih/GPqYsx+Mn5aUTJarSqR6pp9/IYdF4Y=";
  };
  cargoHash = "sha256-Hs+lGesdwkQuQwQKKtwDIg4BH8iqYXS7m4izaV6SZUA=";
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ dbus ];
  patches = [
    ./customisations.patch
  ];
  postUnpack = ''
    cp ${./Cargo.lock} $sourceRoot/Cargo.lock
  '';
}
