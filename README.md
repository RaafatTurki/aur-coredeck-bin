[AUR](https://aur.archlinux.org/packages/coredeck-bin) package for [CoreDeck](https://github.com/devmuaz/CoreDeck)

This repository holds the packaging files and the automation that keeps the AUR package in sync with upstream releases.

[![AUR version](https://img.shields.io/aur/version/coredeck-bin)](https://aur.archlinux.org/packages/coredeck-bin)

## Install

```sh
paru -S coredeck-bin
# or
yay -S coredeck-bin
```

or manually:

```sh
git clone https://aur.archlinux.org/coredeck-bin.git
cd coredeck-bin
makepkg -si
```

### Repository settings

| Kind | Name | Value |
|---|---|---|
| Secret | `AUR_SSH_KEY` | private key (no passphrase) whose public half is on the AUR account |
| Variable | `AUR_PUSH` | `true` to publish. anything else is a dry run that only prints the `PKGBUILD` diff |

the built-in `github.token` is used for everything else.


## Updating by hand

```sh
./update.sh          # must not run as root
git diff             # review the bump
```
