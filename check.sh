#!/usr/bin/env bash

# this is a helper script which checks whether a newer upstream release is ready to be packaged
# it prints the new version to stdout if there is a new release
# it prints nothing if there is nothing to do
# requires: curl, jq and sort

set -euo pipefail

cd "$(dirname "$0")"

repo=devmuaz/CoreDeck
api=https://api.github.com/repos/$repo/releases/latest

# GH_TOKEN is optional, it raises the github api rate limit
release=$(curl -fsSL ${GH_TOKEN:+-H "Authorization: Bearer $GH_TOKEN"} "$api")
tag=$(jq -r .tag_name <<<"$release")
new=${tag#v}

# pkgver may only contain digits and dots
if ! [[ $new =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
  echo "unexpected tag '$tag'" >&2
  exit 1
fi

# nothing to do unless upstream is strictly newer than the packaged version
cur=$(sed -n 's/^pkgver=//p' PKGBUILD)
newest=$(printf '%s\n%s\n' "$cur" "$new" | sort -V | tail -n 1)
if [[ $new == "$cur" || $newest != "$new" ]]; then
  echo "up to date ($cur, latest upstream $new)" >&2
  exit 0
fi

# wait for both releases and assets to be published
if ! jq -e '[.assets[].name] | contains(["coredeck-linux-x86-64.tar.gz","coredeck-linux-arm64.tar.gz"])' <<<"$release" >/dev/null; then
  echo "release $tag is missing Linux assets, will retry next run" >&2
  exit 0
fi

echo "$new"
