#!/usr/bin/env bash
set -euo pipefail

ROUTER_HOST="openwrt.local"
TARGET="mvebu/cortexa9"
PROFILE="linksys_wrt3200acm"
BASE_URL="https://downloads.openwrt.org/releases"
CUSTOM_PACKAGES_FILE="/home/rickie/Sync/Private/Notes/wrt3200acm_pkgs.txt"

fetch_latest_version() {
  curl -s "$BASE_URL/" |
    grep -Eo 'href="[0-9]+\.[0-9]+\.[0-9]+/' |
    sed 's/href="//;s|/||' |
    sort -V |
    tail -n 1
}

get_installed_version() {
  echo "🔍 Checking installed version on ${ROUTER_HOST}..."
  if VERSION=$(ssh "$ROUTER_HOST" "[ -f /etc/os-release ]"); then
    echo $VERSION
  else
    echo "Latest installed version unknown."
    exit 1
  fi
}

download_imagebuilder() {
  local version="$1"
  echo "Version: $version"
  local target_arch="${TARGET//\//-}"
  echo "Target Arch: $target_arch"

  echo "🔽 Downloading ImageBuilder for OpenWrt $version..."

  local listing_url="${BASE_URL}/${version}/targets/${TARGET}/"
  echo "Listing URL: $listing_url"
  archive_name=$(curl -s "$listing_url" | grep -oE "openwrt-imagebuilder-${version}-${target_arch}[^\"']+\.tar\.zst" | head -n1)
  echo "Archive Name: $archive_name"

  if [[ -z "$archive_name" ]]; then
    echo "❌ Could not find ImageBuilder for version $version at $listing_url"
    exit 1
  fi

  mkdir -p imagebuilder
  wget -q "${listing_url}${archive_name}" -O "imagebuilder/${archive_name}"
  tar -xf "imagebuilder/${archive_name}" -C imagebuilder/
}

build_image() {
  local version="$1"
  local builder_dir
  builder_dir=$(find imagebuilder -type d -name "openwrt-imagebuilder-*${version}*" | head -n1)

  if [[ -z "$builder_dir" ]]; then
    echo "❌ ImageBuilder directory not found after extraction"
    exit 1
  fi

  echo "🏗️  Building custom image for version ${version}..."

  local custom_packages=""
  custom_packages=$(tr '\n' ' ' < "$CUSTOM_PACKAGES_FILE")

  pushd "$builder_dir" > /dev/null
  make image PROFILE="$PROFILE" PACKAGES="$custom_packages"
  popd > /dev/null
  OUTFILE=$(find imagebuilder/openwrt-imagebuilder-24.10.1-mvebu-cortexa9.Linux-x86_64/bin/targets/mvebu/cortexa9 -name *sysupgrade*  2>/dev/null | head -n1 )
  cp "$OUTFILE" ~/Downloads

  echo "✅ Build complete. Check your downloads folder!"
}

main() {
  latest_version=$(fetch_latest_version)
  installed_version=$(get_installed_version)

  echo "🆕 Latest version:    ${latest_version}"
  echo "📦 Installed version: ${installed_version}"

  if [[ "$installed_version" == "unknown" ]]; then
    echo "⚠️  Remote version unknown. Proceeding with build."
  elif [[ "$installed_version" =~ $latest_version ]]; then
    echo "✅ Already running the latest OpenWrt version (${latest_version}). Skipping build."
    exit 0
  fi

  echo "🚧 Proceeding to build for ${ROUTER_HOST}..."
  download_imagebuilder "$latest_version"
  build_image "$latest_version"
}

main "$@"
