#!/usr/bin/env bash

# this is a helper script which updates the local packaged files from upstream
# NEVER RUN AS ROOT (makepkg refuses)

set -euo pipefail

cd "$(dirname "$0")"

# asks check.sh whether there is anything to package
new=$(./check.sh)
if [[ -z $new ]]; then
  exit 0
fi
cur=$(sed -n 's/^pkgver=//p' PKGBUILD)

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
grep -qx 'usr/lib/coredeck/CoreDeck' <<<"$files"
grep -q '^usr/share/coredeck/assets/fonts/' <<<"$files"
! grep -q '^opt/' <<<"$files"
grep -qx 'usr/share/applications/com.devmuaz.coredeck.desktop' <<<"$files"
grep -q '^usr/share/icons/hicolor/.*/apps/com.devmuaz.coredeck.png$' <<<"$files"

# generates .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# cleanup
rm -rf src pkg ./*.pkg.tar.zst ./*.tar.gz ./*-LICENSE

echo "ok: $new"
