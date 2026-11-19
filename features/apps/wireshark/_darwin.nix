# Lets my account capture packets without sudo. macOS creates the /dev/bpf*
# capture devices owned by root, so Wireshark can't open them. Wireshark's
# own installer adds a ChmodBPF daemon for this, which the Nix package
# doesn't have. This is the same daemon, declared here.
{ vars, ... }:
{
  users = {
    knownGroups = [ "access_bpf" ];
    groups.access_bpf = {
      # The ID Wireshark's installer gave the group on this Mac
      gid = 102;
      members = [ vars.username ];
    };
  };

  # At boot: create the devices up to the kernel's limit, since each one
  # only appears after the one before it is opened, then give the group
  # read and write access to them
  launchd.daemons.chmod-bpf = {
    script = ''
      max=$(/usr/sbin/sysctl -n debug.bpf_maxdevices)
      [ "$max" -gt 256 ] && max=256
      dev=0
      while [ "$dev" -lt "$max" ]; do
        read -r -n 0 < "/dev/bpf$dev" > /dev/null 2>&1 || true
        dev=$((dev + 1))
      done
      /usr/bin/chgrp access_bpf /dev/bpf*
      /bin/chmod g+rw /dev/bpf*
    '';
    serviceConfig.RunAtLoad = true;
  };
}
