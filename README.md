# NixOS Configuration

Welcome to my NixOS config repo.

This contains a personal Nix flake for managing both NixOS and macOS (nix-darwin) system types, and any server builds I may wish to add.

![screenshot](screenshot.jpeg)

The repo is public as a rebuild reference for myself, and in case anything here is useful to someone else stumbling across it. It won't work out of the box for anyone — it's built around my hardware, with anything sensitive locked behind YubiKey, and a private secrets repo. 3rd Party PR requests wont be taken, but feel free to use any code in the repo as you see fit in your own Nix-based projects!

---

## Hosts

| Host | Platform | System | Type | Description |
|---|---|---|---|---|
| `gibson` | NixOS | x86_64-linux | Personal | Main NixOS PC |
| `macbook` | nix-darwin | aarch64-darwin | Personal | M2 Macbook Air |
| `attic` | NixOS | x86_64-linux | Server | Attic Cache under Proxmox PCT |
| `theVault` | NixOS | x86_64-linux | Server | Vaultwarden under Proxmox PCT |

---

## Structure

```
.
├── flake.nix                  # Entrypoint — flake-parts + import-tree; the only file naming top-level dirs
├── flake/
│   └── parts/                 # Flake-parts modules (host registry, platforms, exports, formatter)
├── hosts/
│   ├── personal/<host>/       # default.nix registers the host; system/home/overlays alongside it
│   └── servers/<host>/        # Same, for servers
├── features/                  # Feature modules — home and system, published by name
├── profiles/                  # Profile compositions — named groups of features per host class
├── pkgs/                      # Custom packages 
└── bootstrap/
    └── install.sh             # Bootstrap entrypoint for personal NixOS hosts
    └── install-darwin.sh      # Bootstrap entrypoint for personal Nix-Darwin hosts
    └── deploy.sh              # Bootstrap entrypoint for server hosts
    └── test.sh                # Custom boostraping test suite
    └── servers/               # Individual server deployment scripts used by deploy.sh
```

The config follows the [dendritic pattern](https://saylesss88.github.io/flakes/dendritic_flake_parts.html) — features are small, self-contained modules composed into hosts via profiles rather than monolithic per-host config files. Nothing references another directory by path (`../`); modules, profiles and hosts are referenced by name, so directories can be moved without breaking the wiring (enforced by a check in CI and the pre-commit hook). [flake-parts](https://github.com/hercules-ci/flake-parts) and [import-tree](https://github.com/vic/import-tree) handle the wiring.

---

## Secrets

Nothing sensitive lives here. Secrets are managed via [sops-nix](https://github.com/Mic92/sops-nix) + `age`, sourced from a private `nix-secrets` repo. The age identity is encrypted to a YubiKey (PIV, via `age-plugin-yubikey`), which is also the root of trust for SSH and GPG. The bootstrap script handles cloning secrets and placing the decrypted age key on a fresh system that has a valid hardware key — see `bootstrap/install.sh --help`.

---

## Rebuilds

```sh
# NixOS
sudo nixos-rebuild switch --flake ~/nixos-config#gibson

# macOS
darwin-rebuild switch --flake ~/nixos-config#macbook
```

---

## A 📝 on AI use
In the event that it isn't obvious: AI collaboration (Claude, Anthropic) shows up in a few places in this repo and I want to make a point of outlining exactly _how_ it is used:

- **Design** — architectural **review** during major restructures (e.g. dendritic pattern migration)
- **Debugging** — root-cause issue analysis, i.e. kernel regressions, CI pipeline races, and other edge cases where my own investigations yield nothing useful
- **CI/CD** — aiding maintenance of consistently hardened pipeline intergations and workflow fixes, if necessary
- **Tooling** — a local git hook generates templated commit messages via Claude, based on staged changes, which is why it may appear as a co-author on commits

To be clear: AI is used as a tool to do some of the more boilerplate/mundane bits, e.g. adding inline comments and explanations and reviewing code changes, under my guidance; all AI input, in whatever capacity, is checked and double-checked by myself-- a real-life actual human bean (not a typo)-- before it is commited back to the repo.

---

## References

- [sops-nix](https://github.com/Mic92/sops-nix)
- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [home-manager](https://github.com/nix-community/home-manager)
- [flake-parts](https://github.com/hercules-ci/flake-parts)
- [disko](https://github.com/nix-community/disko)
- [age-plugin-yubikey](https://github.com/str4d/age-plugin-yubikey)
