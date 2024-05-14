{ pkgs }:

pkgs.writeShellApplication {
    name = "mouse_battery";
    runtimeInputs = with pkgs; [ bluez gawk gnugrep rivalcfg coreutils ];
    text = ''
for i in $(bluetoothctl devices | awk '{print $2}'); do
    if ! rivalcfg --battery-level >/dev/null 2>&1
    then
        MAC="$i"
        CONNECTED=$(bluetoothctl info "$MAC" | grep -i 'connected' | awk '{print $2}')
    if [[ $CONNECTED = "yes" ]];
    then
        BT_BATTERY=$(bluetoothctl info "$MAC" | grep -i 'battery percentage' | awk -F '[()]' '{print $2}')
        if (( BT_BATTERY == 0 ))
        then
            echo "{\"alt\": \"0\", \"text\": \"DEAD\"}, \"class\": \"lowbat\""
        elif (( BT_BATTERY <=10 ))
        then
            echo "{\"alt\": \"25\", \"text\": \" $BT_BATTERY%\"}, \"class\": \"lowbat\""
        elif (( BT_BATTERY <=25 ))
        then
            echo "{\"alt\": \"25\", \"text\": \" $BT_BATTERY%\"}, \"class\": \"nearlylowbat\""
        elif (( BT_BATTERY <=50 ))
        then
            echo "{\"alt\": \"50\", \"text\": \" $BT_BATTERY%\"}, \"class\": \"fine\""
        elif (( BT_BATTERY <=75 ))
        then
            echo "{\"alt\": \"75\", \"text\": \" $BT_BATTERY%\"}, \"class\": \"fine\""
        elif (( BT_BATTERY <=100 ))
        then
            echo "{\"alt\": \"100\", \"text\": \" $BT_BATTERY%\"}, \"class\": \"fine\""
        fi
    elif [[ $CONNECTED = "no" ]]; then
        echo "{\"alt\": \"0\", \"text\": \" DC\"}, \"class\": \"lowbat\""
    fi
    else
        echo "{\"alt\": \"charging\", \"text\": \"$(rivalcfg --battery-level 2>/dev/null | grep -Eo '[0-9]{2,3}')%\"}, \"class\": \"fine\""
    fi
done
    '';
}
