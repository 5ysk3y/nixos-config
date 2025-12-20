# NixOS Configuration

## Contents
- [Introduction](#introduction)
- [Philosophy](#-philosophy)
- [Secrets](#-secrets)
- [What’s in This Repo](#-whats-in-this-repo)
- [Installation](#-installation)
- [Local Development & Rebuilds](#-local-development--rebuilds)
- [CI Integration](#-ci-integration)
- [Structure & Ongoing Work](#-structure--ongoing-work)
- [For Readers New to This Repo](#-for-readers-new-to-this-repo)
- [Final Notes](#-final-notes)

---

## Introduction

This repository is the **home of my personal NixOS configuration** — a declarative, reproducible setup driven by Nix flakes and enhanced with automated secrets provisioning.

This is *not* a generic “copy‑paste and it works for everybody” configuration. It is tuned for my hardware, preferences, and workflows. That said, this repo may be a useful reference if you’re exploring advanced NixOS patterns.

> ⚠️ **Status:** This repository is under **active, ongoing development**. Some modules are highly refined, others are still host‑specific or in the process of being generalised. Expect rough edges — and evolution.

![Alt text](screenshot.jpeg)

---

## 🧠 Philosophy

This config aims to combine:

- **Declarative system configuration** via Nix flakes
- **Secure secret management** using age + sops + a private secrets repo
- **Reproducible deployment**, including fresh installs via a bootstrap script
- **CI compatibility**, with secrets decoupled from public evaluation

Reproducibility doesn’t mean “works everywhere without editing”. It means the system *you define here* can be rebuilt reliably across machines or reinstall scenarios.

---

## 🧱 Secrets 

Secrets (passwords, keys, tokens) are **never stored in this public repo** in plaintext.

Instead, this setup uses:

- A private `nix-secrets` repository (encrypted with `sops`)
- The encryption scheme `age` for secure key management
- A bootstrap script that:
  - decrypts a minimal age identity using a *single long passphrase*
  - uses a deploy SSH key to clone the private `nix-secrets` repo
  - installs decrypted secrets into `/etc/nixos/nix-secrets` on a fresh system

This bootstrap process allows a fresh install to succeed without embedding secrets in the public flake. Strong key rotation and cryptographic hygiene are enforced.

> Secrets are encrypted at rest, stored in a private repo, and only ever decrypted on target machines. CI workflows override the secrets input and never evaluate real secret material.

---

## 🧰 What’s in This Repo

This repo contains:

- `flake.nix` — the flake entrypoint with system definitions
- Host‑specific folders (e.g. `hosts/gibson/`) containing NixOS modules
- Home Manager configurations
- Custom scripts (including bootstrap helpers)
- Supporting tooling and documentation

It does *not* contain:

- Unencrypted private keys
- Decryption passphrases
- Plaintext secrets of any kind

---

## 🚀 Installation 

> **IMPORTANT:** Secrets are required to install or rebuild this configuration.

To install on a fresh machine:

1. Clone this repo locally:
   ```sh
   git clone https://github.com/5ysk3y/nixos-config.git
   cd nixos-config
   ```

2. Run the **bootstrap script** with your long passphrase:
   ```sh
   sudo ./bootstrap/install.sh --target /mnt --user rickie --host gibson
   ```

   The bootstrap process:
   - Decrypts the age identity
   - Decrypts the deploy SSH key
   - Pulls the private `nix-secrets` repo
   - Deploys secrets to `/etc/nixos/nix-secrets`
   - Installs the age key at `/var/lib/age/keys.txt` for `sops-nix`

3. Install NixOS using the flake:
   ```sh
   sudo nixos-install --flake "/mnt/home/rickie/nixos-config#gibson"
   ```

Once this completes, the system can be rebuilt normally with secrets available.

---

## 🧪 Local Development & Rebuilds

After bootstrapping, future rebuilds work as usual:

```sh
sudo nixos-rebuild switch --flake /home/<user>/nixos-config#gibson
```

Secrets are decrypted automatically at activation time via `sops-nix`.

---

## 🛠 CI Integration

GitHub Actions runs `nix flake check` without access to real secrets.

CI achieves this by:

- Using an SSH deploy key (stored in GitHub Secrets) to fetch the private secrets repo
- Overriding the `nix-secrets` flake input during CI evaluation
- Avoiding any reliance on `/etc/nixos/nix-secrets` existing on runners

This keeps CI **green, safe, and reproducible**, while maintaining strong isolation between public evaluation and private secret material.

---

## 🧩 Structure & Ongoing Work

Some parts of this repository — particularly newer bootstrap and secrets tooling — are relatively polished and opinionated.

Other areas:

- still contain host‑specific assumptions
- have grown organically over time
- may not yet align with strict Nix “best practices”

Cleaning up, modularising, and generalising those parts is **ongoing work**. This repo reflects a living system, not a finished template.

---

## 🧭 For Readers New to This Repo

If you’re new to NixOS or flakes:

- This configuration uses advanced patterns
- Some familiarity with Nix expressions is assumed
- Secrets handling is intentionally non‑trivial for security reasons

Useful references:

- `sops-nix`: https://github.com/Mic92/sops-nix
- NixOS Discourse discussions on secrets management

---

## ❤️ Final Notes

This repository exists primarily for my own systems, but it’s public in the spirit of learning, sharing, and curiosity.

If something here inspires you, feel free to adapt it — just don’t expect it to drop cleanly into your environment without modification.

Expect change. Expect iteration. That’s the point.
