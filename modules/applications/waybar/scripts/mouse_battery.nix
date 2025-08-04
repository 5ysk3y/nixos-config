{ pkgs }:

pkgs.writeShellApplication {
  name = "mouse_battery";
  runtimeInputs = with pkgs; [ bluez gawk gnugrep rivalcfg coreutils ];
  text = ''
    # override writeShellApplication’s default safety flags
    set +e +u +o pipefail

    # optional: re-enable specific flags you want
    set -u  # just example

    found_device=false

    while read -r MAC; do
      found_device=true

      if ! rivalcfg --battery-level >/dev/null 2>&1; then
        CONNECTED=$(bluetoothctl info "$MAC" | grep -i 'connected' | awk '{print $2}')
        if [[ "$CONNECTED" = "yes" ]]; then
          BT_BATTERY=$(bluetoothctl info "$MAC" | grep -i 'battery percentage' | awk -F '[()]' '{print $2}')
          if (( BT_BATTERY == 0 )); then
            echo '{"alt": "0", "text": "DEAD", "class": "lowbat"}'
          elif (( BT_BATTERY <= 10 )); then
            echo "{\"alt\": \"25\", \"text\": \" $BT_BATTERY%\", \"class\": \"lowbat\"}"
          elif (( BT_BATTERY <= 25 )); then
            echo "{\"alt\": \"25\", \"text\": \" $BT_BATTERY%\", \"class\": \"nearlylowbat\"}"
          elif (( BT_BATTERY <= 50 )); then
            echo "{\"alt\": \"50\", \"text\": \" $BT_BATTERY%\", \"class\": \"fine\"}"
          elif (( BT_BATTERY <= 75 )); then
            echo "{\"alt\": \"75\", \"text\": \" $BT_BATTERY%\", \"class\": \"fine\"}"
          elif (( BT_BATTERY <= 100 )); then
            echo "{\"alt\": \"100\", \"text\": \" $BT_BATTERY%\", \"class\": \"fine\"}"
          fi
        elif [[ "$CONNECTED" = "no" ]]; then
          echo '{"alt": "0", "text": " DC", "class": "lowbat"}'
        fi
      else
        charge=$(rivalcfg --battery-level 2>/dev/null | grep -Eo '[0-9]{2,3}' || echo "0")
        echo "{\"alt\": \"charging\", \"text\": \"$charge%\", \"class\": \"fine\"}"
      fi
    done < <(bluetoothctl devices | awk '{print $2}')

    if ! $found_device; then
      echo '{"alt": "0", "text": "NO DEVICE", "class": "lowbat"}'
    fi

    exit 0
  '';
}
