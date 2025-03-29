{ pkgs, ... }:

# Not my repo - Check it out here: https://github.com/BEST8OY/ScrollMPRIS

with pkgs;

rustPlatform.buildRustPackage {
  pname = "scroll-mpris";
  version = "0.1.0"; 
  src = fetchFromGitHub {
    owner = "BEST8OY";
    repo = "ScrollMPRIS";
    rev = "7549ba2b879aa4f3c0bfcbcc525cab23ec635453"; 
    sha256 = "sha256-RGE/x/1sTYL3zV/t0vHog7t4X6pP1g3jJPIZqRRxjJM="; 
  };
  useFetchCargoVendor = true;
  cargoHash = "sha256-GIrwUJxe/ktHnZ2NW9car1t0WHHL1Wxlc7448lmzk/c="; 
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ dbus ];
  patches = [
    ./customisations.patch
  ];
  postUnpack = ''
    cp ${./Cargo.lock} $sourceRoot/Cargo.lock
  '';
}
