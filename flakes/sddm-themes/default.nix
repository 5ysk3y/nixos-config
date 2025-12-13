{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  formats,
  kdePackages,
  theme ? "astronaut",
  themeConfig ? null,
}:
let
  overwriteConfig = (formats.ini { }).generate "${theme}.conf.user" themeConfig;
in
stdenvNoCC.mkDerivation rec {
  pname = "sddm-astronaut-theme";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "keyitdev";
    repo = "sddm-astronaut-theme";
    rev = "c10bd950544036c7418e0f34cbf1b597dae2b72f";
    hash = "sha256-ITufiMTnSX9cg83mlmuufNXxG1dp9OKG90VBZdDeMxw=";
  };
  # Avoid wrapping Qt binaries
  dontWrapQtApps = true;

  # Required Qt6 libraries for SDDM >= 0.21
  propagatedBuildInputs = [
    kdePackages.qtsvg
    kdePackages.qtmultimedia
    kdePackages.qtvirtualkeyboard
  ];

  buildPhase = ''
    runHook preBuild
    echo "No build required."
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Install theme to a single directory
    install -dm755 "$out/share/sddm/themes/sddm-astronaut-theme"
    cp -r ./* "$out/share/sddm/themes/sddm-astronaut-theme"

    # Copy fonts system-wide
    install -dm755 "$out/share/fonts"
    cp -r "$out/share/sddm/themes/sddm-astronaut-theme/Fonts/." "$out/share/fonts"

    # Update metadata.desktop to load the chosen subtheme
    metaFile="$out/share/sddm/themes/sddm-astronaut-theme/metadata.desktop"
    if [ -f "$metaFile" ]; then
      substituteInPlace "$metaFile" \
        --replace "ConfigFile=Themes/astronaut.conf" "ConfigFile=Themes/${theme}.conf"
    fi

     ${lib.optionalString (lib.isAttrs themeConfig) ''
       install -dm755 "$themeDir/Themes"
       cp ${overwriteConfig} $themeDir/Themes/${theme}.conf.user
     ''}

    runHook postInstall
  '';

  # Propagate Qt6 libraries to user environment
  postFixup = ''
    mkdir -p $out/nix-support
    echo ${kdePackages.qtsvg} >> $out/nix-support/propagated-user-env-packages
    echo ${kdePackages.qtmultimedia} >> $out/nix-support/propagated-user-env-packages
    echo ${kdePackages.qtvirtualkeyboard} >> $out/nix-support/propagated-user-env-packages
  '';

  meta = with lib; {
    description = "Series of modern looking themes for SDDM.";
    homepage = "https://github.com/Keyitdev/sddm-astronaut-theme";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
