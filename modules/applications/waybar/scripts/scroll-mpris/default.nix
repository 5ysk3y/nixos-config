{ pkgs, ... }:

with pkgs;

rustPlatform.buildRustPackage {
  pname = "scroll-mpris";
  version = "0.1.0"; # update to the correct version or tag if available
  src = fetchFromGitHub {
    owner = "BEST8OY";
    repo = "ScrollMPRIS";
    rev = "master"; # you can replace this with a specific commit or tag
    sha256 = "sha256-Ea3ChIbETTJ8x9hz/lRlbseDD3yW5Rm+eV3SV2w/HPo="; # run nix-build to determine the correct hash
  };
  useFetchCargoVendor = true;
  cargoHash = ""; # similarly, update this after first build
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ dbus ];
  patches = [
    ./cargo.lock.patch
    ./update-icons.patch
  ];
}
