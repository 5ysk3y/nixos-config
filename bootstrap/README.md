# Installing personal machines

This is a series of directions/checklist for reinstalling `gibson` and setting up the `macbook`. 

Upstream tools do the work: [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) and [disko](https://github.com/nix-community/disko) install gibson, [restic](https://restic.net) restores anything in an undeclarative state, and `age` / `age-plugin-yubikey` / `sops` unlock the secrets with a YubiKey. 

Servers are deployed differently: see `deploy.sh`.

---

## gibson

Installed from the MacBook over SSH, while gibson runs the netboot or USB installer (`features/installer`). If the Mac isn't available, see [Without the Mac](#without-the-mac).

### Where everything comes from

| What | Source |
| --- | --- |
| The system | This flake, built on gibson by the installer |
| System disk layout | `hosts/personal/gibson/disko.nix`: wipes the main NVMe, pinned by ID |
| Games disk (`~/games`) | Not touched; mounted again by its label (`GAMES`) |
| sops key (`/var/lib/age/keys.txt`) | Decrypted from nix-secrets with a YubiKey |
| Swap keyfile, SSH host keys, machine-id, NetworkManager connections, user/group ID maps | Restored from local restic backup **before** the install |
| `/home/rickie` (except `~/games`), `/root`, `/var/lib` | Restored from local restic backup **before** the first boot |
| FIDO2 disk unlock | Enrolled again after the install |

The user/group ID maps (`/var/lib/nixos`) go in first so NixOS hands out the same IDs as before, and restored files keep their owners. Everything else is restored before gibson first boots, so no service starts on an empty state directory (i.e. Syncthing, Tailscale) and nothing writes to the home directory while it's being restored.

### 0. Before starting 

On gibson:

1. Push any repo changes as they are not preserved unless Restic has backed them up.
2. Note how the current FIDO2 enrolment is set up, so step 6 can enrol the new disk the same way. This prints each YubiKey's token (one per key); note its `fido2-clientPin-required`, `fido2-up-required` and `fido2-uv-required` values:
   ```sh
   ROOT_DEVICE=$(sudo cryptsetup status rootfs | awk '/device:/ {print $2}')
   for id in 0 1; do sudo cryptsetup token export --token-id "$id" "$ROOT_DEVICE"; echo; done
   ```
3. Make sure netboot.xyz serves a current installer: rebuild if `features/installer` has changed since last publication, i.e. from the repo root, on the Mac or gibson:
   ```sh
   nix run .#build-installer -- netboot
   ```
   It builds the netboot files (on the Mac, in its Linux builder VM) and prints the `rsync` command that publishes them; nothing is copied until that command is ran, or if answer "yes" is supplied at the prompt when `NETBOOT_DEST` is set. To boot from a USB stick instead, `nix run .#build-installer -- iso` builds the ISO and prints the commands to write it.
4. Take a final backup if necessary:
   ```sh
   sudo systemctl start restic-backups-gibson.service   # returns when the backup and check finish
   sudo restic-gibson snapshots --latest 1
   ```
5. On the Mac, check gibson's config evaluates there (the Mac evaluates it; gibson builds it):
   ```sh
   cd ~/nixos-config && git pull
   nix eval --raw .#nixosConfigurations.gibson.config.system.build.toplevel.drvPath
   nix eval --raw .#nixosConfigurations.gibson.config.system.build.diskoScript.drvPath
   ```
   Both should print a `/nix/store/…drv` path.

Step 1 below doesn't touch gibson, so it can also be tried out at any time, to check the Mac can reach the backup.

### 1. Stage the files on the Mac

On the home LAN, in `~/nixos-config`, with a YubiKey plugged in. Everything below runs in one `bash` session, with tools from this flake's nixpkgs:

```sh
nix shell --inputs-from . nixpkgs#nixos-anywhere nixpkgs#sops nixpkgs#restic \
  nixpkgs#age nixpkgs#age-plugin-yubikey --command bash
```
Load the values the rest of the checklist uses, from gibson's config (`HOST` is the configuration to install; see [Rehearsing a reinstall](#rehearsing-a-reinstall) for the others):

```sh
HOST=gibson
eval "$(nix eval --raw ".#nixosConfigurations.$HOST.config.system.build.bootstrapEnv")"
```

This sets the variables below and prints each one with its value, so the following steps can be checked against them. They're read from the config itself (`hosts/personal/gibson/bootstrap.nix` collects them), so they always match what's being installed. The nix-secrets files are the copy Nix fetched to evaluate the config, so there's nothing to clone.

| Variable | What it is | Where it's set |
| --- | --- | --- |
| `BACKUP_HOST`, `BACKUP_HOST_KEY` | The backup server, and its pinned host key | `backup.nix` |
| `RESTIC_REPOSITORY`, `RESTIC_SFTP_USER` | The restic repository, and the sftp user in it | `backup.nix` |
| `RESTIC_WRAPPER` | The `restic` wrapper the installed system has (`restic-gibson`) | `backup.nix` (the backup's name) |
| `RESTIC_PASSWORD_SOPS`, `RESTIC_SFTP_KEY_SOPS` | The sops-encrypted repository password and sftp key | `backup.nix`, from nix-secrets |
| `AGE_KEYS` | The sops key, encrypted to the YubiKeys | nix-secrets, `bootstrap/age-keys.txt.age` |
| `SOPS_KEY_FILE` | Where the system expects the sops key | `sops.age.keyFile` |
| `INSTALL_DISK` | The disk disko formats: everything on it is erased | `disko.nix` (`default.nix` for the test configurations) |
| `DISK_PASSWORD_FILE` | Where disko reads the disk passphrase during the install | `disko.nix` |
| `SWAP_KEY`, `SWAP_KEY_SOURCE` | The swap keyfile as disko and the initrd see it, and where it's kept on the system | `disko.nix`, `hardware-configuration.nix` |
| `ROOT_DEVICE` | The root LUKS device | `hardware-configuration.nix` (`test-install.nix` for the test configurations) |
| `GAMES_DIR` | The games disk's mount point, left out of the restore | `hardware-configuration.nix` |
| `PRE_INSTALL_INCLUDES` | What's restored before the install, as `restic --include` options | `bootstrap.nix` |

Then prepare local temp directories and the sops-nix decryption key, decrypted with the YubiKey:

```sh
umask 077
STAGE=$(mktemp -d)   # copied to / on gibson
TMP=$(mktemp -d)     # credentials for this session only, never copied

# The sops key, decrypted with the YubiKey (touch it when it blinks)
age-plugin-yubikey --identity > "$TMP/yubikey-identity.txt"
install -d -m 0755 "$STAGE/var" "$STAGE/var/lib"
install -d -m 0750 "$STAGE$(dirname "$SOPS_KEY_FILE")"
age -d -i "$TMP/yubikey-identity.txt" -o "$STAGE$SOPS_KEY_FILE" "$AGE_KEYS"
chmod 0640 "$STAGE$SOPS_KEY_FILE"
```

If `age-plugin-yubikey` can't reach the key, gpg's scdaemon may be holding it on the live system: `gpgconf --kill scdaemon` and try again.

Then the files that have to be in place before the install, from the backup:

```sh
export SOPS_AGE_KEY_FILE="$STAGE$SOPS_KEY_FILE"
sops -d --input-type binary --output-type binary "$RESTIC_PASSWORD_SOPS" > "$TMP/restic.password"
sops -d --input-type binary --output-type binary "$RESTIC_SFTP_KEY_SOPS" > "$TMP/sftp.key"
echo "$BACKUP_HOST_KEY" > "$TMP/known_hosts"

export RESTIC_PASSWORD_FILE="$TMP/restic.password"
SFTP="sftp.command=ssh $RESTIC_SFTP_USER@$BACKUP_HOST -i $TMP/sftp.key -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$TMP/known_hosts -s sftp"

restic -o "$SFTP" --no-cache snapshots --latest 1   # the backup from step 0
restic -o "$SFTP" --no-cache restore latest --target "$STAGE" "${PRE_INSTALL_INCLUDES[@]}"
find "$STAGE" -type f | sort
```

The list should show the swap keyfile (`$SWAP_KEY_SOURCE`), the `etc/ssh/ssh_host_*` keys, `etc/machine-id`, the `.nmconnection` files, the sops key (`$SOPS_KEY_FILE`) and the files in `var/lib/nixos` (`uid-map`, `gid-map` and others).

### 2. Boot the installer on gibson

Shut gibson down first (a full shutdown, not hibernation, so the games disk is cleanly unmounted). Then netboot.xyz via PXE → **Custom URL Menu** → **installer** (or the USB stick). On gibson's screen:

```sh
ip -br a                                           # the address to install to
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub   # confirm the host key for the next step
```

### 3. Install, from the Mac

In the same `bash` session where the variables from step 1 are set; first,  one SSH connection to the installer, checked against the host key above:

```sh
IP=<the address from step 2>
ssh -fN -M -S "$TMP/ssh" -o ControlPersist=yes \
  -o UserKnownHostsFile="$TMP/installer_known_hosts" -o StrictHostKeyChecking=ask \
  "root@$IP"
```

Accept the host key only if it matches the fingerprint on gibson's screen, and touch the YubiKey to log in. Then check the disk that's about to be erased:

```sh
ssh -S "$TMP/ssh" "root@$IP" "ls -l $INSTALL_DISK && lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL $INSTALL_DISK"
```

It should be the system disk (for gibson, the 476.9G NVMe with the `BOOT`, `ROOT` and `SWAP` partitions), never the one labelled `GAMES`. The `nvme0`/`nvme1` names can swap between boots, which is why the config names the disk by its ID. If `ls` can't find it, stop: the config names a disk that isn't attached.

Then install through that connection:

```sh
read -rsp 'Disk passphrase: ' PASS; echo

nixos-anywhere --flake ".#$HOST" --target-host "root@$IP" \
  --ssh-option ControlPath="$TMP/ssh" \
  --build-on remote \
  --phases kexec,disko,install \
  --extra-files "$STAGE" \
  --disk-encryption-keys "$DISK_PASSWORD_FILE" <(printf '%s' "$PASS") \
  --disk-encryption-keys "$SWAP_KEY" "$STAGE$SWAP_KEY_SOURCE"
```

- Why the separate connection: nixos-anywhere turns host key checking off (`StrictHostKeyChecking=no`, `UserKnownHostsFile=/dev/null`), and passes those options before any `--ssh-option`, so they can't be overridden (ssh takes the first value it's given). Through `ControlPath`, every connection it makes reuses the one checked above, so the passphrase and the sops key only go to the verified host.
- The installer's throwaway host key is kept in `$TMP`, not the Mac's own `known_hosts`.
- `kexec` is skipped (gibson is already in the installer) and `reboot` is left out, so the restore in step 4 happens before the first boot.
- The system is built on gibson, straight onto the disk, with substitutes from cache.nixos.org and the local attic cache.

### 4. Restore, before the first boot

Still on the Mac, in the same session; each command runs on gibson (still the installer) through the SSH connection from step 3:

```sh
ssh -S "$TMP/ssh" "root@$IP" "nixos-enter --root /mnt --silent -c '$RESTIC_WRAPPER restore latest --target / \
  --exclude $GAMES_DIR --exclude /var/lib/nixos --exclude /etc'"

# Files whose owner doesn't exist on the new system
ssh -S "$TMP/ssh" "root@$IP" "nixos-enter --root /mnt --silent -c 'find /home /root /var/lib -xdev \( -nouser -o -nogroup \)'" \
  | awk -F/ '{print "/"$2"/"$3"/"$4"/"$5"/"$6"/"$7}' | sort | uniq -c | sort -rn

ssh -S "$TMP/ssh" "root@$IP" reboot
```

- `nixos-enter` runs the new system's activation first, so the sops secrets and the `$RESTIC_WRAPPER` wrapper work as they do on the installed system.
- The ownership check groups what it finds by directory. Rootless podman's storage (`~/.local/share/containers/storage`) is expected there in large numbers: container files belong to subordinate IDs, which aren't users. So are directories left behind by services the config no longer has (`/var/lib/syncthing`, `/var/lib/dhcpcd`). Anything else under the home directory means an owner changed between the backup and the new system; check it before rebooting.

### 5. First boot

- The root disk asks for the passphrase (no FIDO2 token is enrolled yet); swap unlocks by itself with its keyfile.
- Log in as usual, then check:
  ```sh
  swapon --show
  findmnt ~/games
  systemctl --failed
  systemctl status "home-manager-$USER.service"
  ```

### 6. Enrol the YubiKeys for unlocking

With **one** YubiKey plugged in, then again with the other (each asks for the disk passphrase, then the key's FIDO2 PIN and a touch):

```sh
ROOT_DEVICE=$(sudo cryptsetup status rootfs | awk '/device:/ {print $2}')
sudo systemd-cryptenroll --fido2-device=auto "$ROOT_DEVICE"
```

systemd-cryptenroll requires the PIN and a touch by default (`--fido2-with-client-pin=yes`, `--fido2-with-user-presence=yes`, `--fido2-with-user-verification=no`). Compare these with the `fido2-clientPin-required`, `fido2-up-required` and `fido2-uv-required` values noted before starting (step 0): if any differ, add the matching option to the command above, e.g. `--fido2-with-user-verification=yes` for `"fido2-uv-required": true`.

Then check both tokens are there, and the passphrase is still in slot 0:

```sh
sudo cryptsetup luksDump "$ROOT_DEVICE" | sed -n '/^Keyslots:/,/^Digests:/p'
```

### 7. Clean up on the Mac

```sh
ssh -S "$TMP/ssh" -O exit "root@$IP" 2>/dev/null
rm -rf "$STAGE" "$TMP"
exit
```

### Without the Mac

The same steps run on gibson itself, from the installer, with the YubiKey plugged into gibson:

1. Boot the installer, log in on the console as `nixos`, and check the YubiKey is seen: `ssh-add -L` lists its key.
2. `git clone git@github.com:5ysk3y/nixos-config.git && cd nixos-config`
3. Steps 1, 3 and 4 as above, with `IP=localhost`. `root@localhost` accepts the YubiKey, as `root@<address>` does from the Mac, and the host key to compare is the one `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` prints on the same machine.

***

### Rehearsing a reinstall

The whole checklist can be run against a disk that isn't gibson's NVMe, with `HOST=gibson-test-usb` or `HOST=gibson-test-vm` in step 1 in place of `HOST=gibson`; the values it loads, and the install in step 3, then follow. Both are gibson's own config with the changes in `hosts/personal/gibson/test-install.nix`:

- Only the test disk is touched, and its partitions and filesystems have their own names (`gibson-test-*`, `TBOOT`, `TROOT`, `TSWAP`, `trootfs`, `tswap`). The install can't format the live NVMe, and the test system can't mount or unlock it, even with both attached.
- The firmware's boot entries are left alone; the test disk is booted from the firmware's boot menu.
- The games disk isn't mounted. (Even a read-only ext4 mount can write to it, which would corrupt it if gibson is hibernated with it mounted.)
- Tailscale, Syncthing, the scheduled backup and the pushes to attic are off, so the copy never acts as gibson on the network. It still has gibson's SSH host keys and machine-id once restored.

In step 0, skip the final backup: the restore uses whatever the latest backup is. Size the test disk for 1G + 32G swap + the system + the restore (`sudo restic-gibson stats latest` gives the restore size).

**On gibson, to an external USB disk.** The closest to the real thing: real hardware, netboot, the Mac, and FIDO2 unlock with the YubiKeys.

1. With the disk plugged in, find its whole-disk link (no `-part` suffix): `ls -l /dev/disk/by-id/ | grep usb-`. Set it as `gibson-test-usb`'s `device` in `hosts/personal/gibson/default.nix`, commit and push.
2. Follow steps 1–4 with `HOST=gibson-test-usb`, after making sure netboot.xyz serves a current installer (step 0). The installer runs on gibson with the NVMe attached; only the USB disk is formatted.
3. At the end of step 4, `poweroff` instead of `reboot`, then start gibson from the firmware's boot menu, choosing the USB disk. Unlock it with the test passphrase, and carry on with steps 5 and 6.
4. On the test system, rebuild with `sudo nixos-rebuild switch --flake .#gibson-test-usb`, not `rebuild`: that alias always builds `.#gibson`. On the test system that remounts `/boot` onto the live NVMe's boot partition, and the switch after it would replace live gibson's boot entries with the test system's.
5. To go back, power off and unplug the USB disk before starting gibson again; it boots its NVMe as usual.

**In a VM on gibson.** Nothing to plug in, and gibson keeps running. gibson stands in for the Mac, since only gibson can reach a VM on libvirt's default (NAT) network. NAT also keeps the copy off the LAN, where its restored machine-id and NetworkManager profile could clash with the real gibson's; it can still reach the backup server and attic.

1. Build the installer ISO on gibson, from the repo root: `nix run .#build-installer -- iso` prints its path. Then create a VM in virt-manager: UEFI firmware (Overview → Firmware, before the first start), 8 GB of RAM or more, the ISO as a CD-ROM, the default network, and a virtio disk sized as above, with the serial number `gibson-test` (Advanced options → Serial number). The disk image counts towards gibson's own disk space.
2. Boot the ISO; on the VM's console, `ip -br a` gives `IP`.
3. Follow steps 1–4 on gibson with `HOST=gibson-test-vm`, then boot the VM from its disk. Without an NVIDIA GPU the desktop may not start: check from a text console or over SSH instead. There's no FIDO2 to test (step 6).

---

## macbook

A fresh macOS install, signed in as `rickie`. Restore files from Time Machine separately.

nix-secrets is a private flake input fetched over SSH (`git+ssh://git@github.com/…`), so nothing builds until the YubiKey works for SSH. Nix fetches it by running `git` as whoever runs `nix`, with that user's SSH agent and `known_hosts`. Root has neither on a fresh Mac, so a `sudo darwin-rebuild switch` run first stalls trying to reach GitHub. Instead, we build as a standard user first (step 5): root's run then finds nix-secrets in the Nix store, as normal.

1. Install Nix with the upstream installer, then open a new terminal:
   ```sh
   curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
   ```
2. Turn on flakes for this terminal, clone the repo to where the config expects it (`vars.configDir`), and start a shell with the tools the next steps use:
   ```sh
   export NIX_CONFIG='extra-experimental-features = nix-command flakes'
   nix run nixpkgs#git -- clone https://github.com/5ysk3y/nixos-config.git ~/nixos-config
   nix shell --inputs-from ~/nixos-config nixpkgs#git nixpkgs#gnupg nixpkgs#pinentry_mac nixpkgs#age nixpkgs#age-plugin-yubikey
   ```
   Run the rest of the steps inside this shell. `git` must stay on `PATH`: macOS's `/usr/bin/git` only offers to install the Xcode command-line tools, and Nix runs `git` to fetch nix-secrets.
3. Make the YubiKey work for SSH, with a throwaway GnuPG home (the config's own gpg-agent setup takes over after step 5):

   ```sh
   export GNUPGHOME=$(mktemp -d)
   TMP=$(mktemp -d)
   printf 'enable-ssh-support\npinentry-program %s\n' "$(command -v pinentry-mac)" > "$GNUPGHOME/gpg-agent.conf"
   echo disable-ccid > "$GNUPGHOME/scdaemon.conf"
   export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
   gpg --card-status > /dev/null
   ssh-add -L   # lists the YubiKey's authentication key
   ```
   - `SSH_AUTH_SOCK` points SSH at gpg-agent rather than macOS's own agent.
   - `pinentry-mac` asks for the PIN in a window. A terminal pinentry can't find a terminal when SSH is what needs the PIN, which fails as "agent refused operation".
   - `disable-ccid` makes scdaemon reach the YubiKey through macOS's smartcard service, as on gibson and the installer.

   Then trust GitHub's host key, checked against [GitHub's published fingerprints](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints) (Ed25519: `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`). Nix's fetch can't stop to ask about it:

   ```sh
   mkdir -p -m 0700 ~/.ssh
   echo 'github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl' >> ~/.ssh/known_hosts
   ssh-keygen -lf ~/.ssh/known_hosts   # the fingerprint above
   ssh -T git@github.com               # "Hi 5ysk3y! …" (touch the YubiKey)
   git -C ~/nixos-config remote set-url origin git@github.com:5ysk3y/nixos-config.git
   ```

4. Clone nix-secrets and decrypt the sops key to where the config looks for it (`vars.age.keyFile`):
   ```sh
   git clone --depth 1 git@github.com:5ysk3y/nix-secrets.git "$TMP/nix-secrets"
   KEYS="$HOME/Library/Application Support/sops/age"
   mkdir -p "$KEYS" && chmod 0700 "$KEYS"
   gpgconf --kill scdaemon   # frees the YubiKey for age-plugin-yubikey
   age-plugin-yubikey --identity > "$TMP/yubikey-identity.txt"
   age -d -i "$TMP/yubikey-identity.txt" -o "$KEYS/keys.txt" \
     "$TMP/nix-secrets/bootstrap/age-keys.txt.age"
   chmod 0600 "$KEYS/keys.txt"
   ```
5. Build as the main user (this fetches nix-secrets with the YubiKey), then activate as root, which reuses that copy:
   ```sh
   cd ~/nixos-config
   nix build .#darwinConfigurations.macbook.system
   sudo ./result/sw/bin/darwin-rebuild switch --flake .#macbook
   ```
   If activation stops at "Unexpected files in /etc", check the files it lists hold nothing that's actually required (the installer's `/etc/nix/nix.conf`, which this config manages, is likely to be one), rename each with `sudo mv <file> <file>.before-nix-darwin`, and run the `darwin-rebuild` line again. nix-darwin replaces the installer's `nix-daemon` service itself.
6. Clean up and open a new terminal, where the config's own gpg-agent and SSH setup apply:
   ```sh
   gpgconf --kill all
   rm -rf "$GNUPGHOME" "$TMP"
   exit
   ```
   From then on, `rebuild` rebuilds the Mac.
