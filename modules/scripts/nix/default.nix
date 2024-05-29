{ pkgs, vars }:

pkgs.writeShellApplication {
    name = "nix-build-system";
    runtimeInputs = with pkgs; [ nvd gawk ];
    text = ''
       CONFIG="${vars.nixos-config}"
       HOME="/home/${vars.username}"
       OUTFILE="changes_$(date +%d-%m@%T).out"

       echo "Welcome!"
       echo "Backing up flake lock file"
       cp $CONFIG/flake.lock $CONFIG/flake.lock.bak
       echo "Done"
       cd $CONFIG
       nix flake update
       echo "Flake updated"
       cd $HOME
       echo "Beginning build. This may take some time."
       echo ""
       sudo nixos-rebuild --flake $CONFIG build --option eval-cache false --show-trace

       echo ""
       echo "Build complete. Providing result:"
       echo ""
       nvd diff /run/current-system $HOME/result | tee "$OUTFILE"

       #Cleanup
       awk -i inplace '{$0=gensub(/\s*\S+/,"",2)}1' "$OUTFILE"
       rm $HOME/result

       echo "Result has been stored in $HOME/$OUTFILE. Finished"
    '';
}
