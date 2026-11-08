# The SSH client config. Keys come from the YubiKey through gpg-agent
# (_gpg.nix), so no block names an IdentityFile. known_hosts is an ordinary
# file in ~/.ssh on each machine.
_: {
  programs.ssh = {
    enable = true;
    # Home Manager's old defaults are being removed; OpenSSH's own apply
    enableDefaultConfig = false;

    settings = {
      "github.com".User = "git";

      "backupServer.home.arpa".User = "networkBackup";
      "mediaServer.home.arpa".User = "mediaRickie";
      "nexus.home.arpa".User = "truenas_admin";
      "ansiblePrime.home.arpa".User = "ansible";

      "proxmox.home.arpa" = {
        HostName = "192.168.1.10";
        User = "root";
      };

      "openwrt.home.arpa" = {
        User = "root";
        Port = 2224;
      };

      "webServer.home.arpa".User = "administrator";
      # Root on the web server, as its own alias: a second webServer block
      # never applied, since ssh takes the first value it finds
      "webServer-root" = {
        HostName = "webServer.home.arpa";
        User = "root";
      };
    };
  };
}
