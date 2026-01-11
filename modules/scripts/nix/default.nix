{
  pkgs,
  vars,
}:
{
  nix-build-system = pkgs.writeShellApplication {
    name = "nix-build-system";
    runtimeInputs = with pkgs; [
      nvd
      gawk
      gnused
    ];
    text = ''
      CONFIG="${vars.nixos-config}"
      HOME="/home/${vars.username}"
      OUTFILE="changes_$(date +%d-%m@%T).out"

      echo "Welcome!"
      if [ ! -f $CONFIG/flake.lock.bak ]; then
        echo "Backing up flake lock file"
        cp $CONFIG/flake.lock $CONFIG/flake.lock.bak
        echo "Done"
        echo ""
        cd $CONFIG
        echo "Updating all flake inputs"
        nix flake update
        echo ""
        echo "Flake updated"
      else
        echo "WARNING: flake.lock backup already exists, not backing up."
        echo ""
      fi
      cd $HOME
      echo "Beginning build. This may take some time."
      echo ""
      systemd-inhibit --no-pager --no-legend --mode=block --who='${vars.username}' --why='NixOS System Building' sudo nixos-rebuild --flake $CONFIG build --option eval-cache false --show-trace

      echo ""
      echo "Build complete. Providing result:"
      echo ""
      nvd diff /run/current-system $HOME/result > "$OUTFILE"

      #Cleanup
      awk -i inplace '{$0=gensub(/\s*\S+/,"",2)}1' "$OUTFILE"
      sed -i -e '1,2d' -e 's/Version/Changed\/Updated:/g' -e 's/Added/\nAdded:/g' -e 's/Removed/\nRemoved:/g' -e '$d' "$OUTFILE"
      rm $HOME/result

      cat "$OUTFILE"

      echo "Result has been stored in $HOME/$OUTFILE. Finished"
    '';
  };
}
