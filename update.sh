#!/usr/bin/env bash

# this is a helper script which auto updates the local packaged files from upstream
# NEVER RUN AS ROOT (makepkg refuses)
# exit code 0 if no action can be done

set -euo pipefail

cd "$(dirname "$0")"

repo=devmuaz/CoreDeck
api=https://api.github.com/repos/$repo/releases/latest

curl_gh() {
  curl -fsSL ${GH_TOKEN:+-H "Authorization: Bearer $GH_TOKEN"} "$@"
}

release=$(curl_gh "$api")
tag=$(jq -r .tag_name <<<"$release")
new=${tag#v}

# pkgver may only contain digits and dots
if ! [[ $new =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
  echo "unexpected tag '$tag'" >&2
  exit 1
fi

# check if the package is already up to date
cur=$(sed -n 's/^pkgver=//p' PKGBUILD)
if (( $(vercmp "$new" "$cur") <= 0 )); then
  echo "up to date ($cur, latest upstream $new)"
  exit 0
fi

# wait for both releases and assets to be published
if ! jq -e '[.assets[].name] | contains(["coredeck-linux-x86-64.tar.gz","coredeck-linux-arm64.tar.gz"])' <<<"$release" >/dev/null; then
  echo "release $tag is missing Linux assets, will retry next run" >&2
  exit 0
fi

# bumps PKGBUILD version to the latest release
echo "bumping $cur -> $new"
sed -i -e "s/^pkgver=.*/pkgver=$new/" -e 's/^pkgrel=.*/pkgrel=1/' PKGBUILD

# refreshes checksums
updpkgsums

# sanity check that the package still builds and contain the expected files
makepkg -fd --noconfirm
pkg=$(ls -1 coredeck-bin-"$new"-1-*.pkg.tar.zst)
files=$(bsdtar -tf "$pkg")
grep -qx 'usr/bin/coredeck' <<<"$files"
grep -qx 'opt/coredeck/CoreDeck' <<<"$files"
grep -q '^opt/coredeck/assets/' <<<"$files"

# generates .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# cleanup
rm -rf src pkg ./*.pkg.tar.zst ./*.tar.gz ./*-LICENSE

echo "ok: $new"
