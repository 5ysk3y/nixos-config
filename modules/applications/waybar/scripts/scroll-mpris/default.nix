{ pkgs, ... }:

# Not my repo - Check it out here: https://github.com/BEST8OY/ScrollMPRIS

with pkgs;

rustPlatform.buildRustPackage {
  pname = "scroll-mpris";
  version = "0.1.0"; 
  src = fetchFromGitHub {
    owner = "BEST8OY";
    repo = "ScrollMPRIS";
    #rev = "7549ba2b879aa4f3c0bfcbcc525cab23ec635453"; 
    rev = "3e393327eff442ac74b4babbecc84dc2da82b2b6"; 
    sha256 = "sha256-KWEKD5NmeMih/GPqYsx+Mn5aUTJarSqR6pp9/IYdF4Y=";
    #sha256 = "sha256-9nVCQeQcfwgq8y/gkLyWuVw9B4O9QYY9ZPxe0+9yUY4=";
  };
  cargoHash = "sha256-2KhyUoz7G637jXDFSXAgLJP6FGW9dJMzYMi41aaiqaU=";
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ dbus ];
  #patches = [
  #  ./customisations.patch
  #];
  postUnpack = ''
    cp ${./Cargo.lock} $sourceRoot/Cargo.lock
  '';
}
