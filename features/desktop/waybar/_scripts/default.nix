{
  pkgs,
  rbw,
}:
{
  check_rbw = pkgs.writeShellApplication {
    name = "check_rbw";
    runtimeInputs = [
      rbw
      pkgs.coreutils
    ];
    text = ''
      if ! rbw unlocked 2>/dev/null
      then
          echo ""
      else
          echo ""
      fi
    '';
  };

  # The one producer behind custom/steelseries. Waybar runs a copy of a
  # custom module per output, so polling from the module made each bar
  # read the mouse at its own moment and show a different value. This
  # runs as a single user service instead: it writes the reading to a
  # file and signals every bar to re-read it at once.
  mouse_battery_producer = pkgs.writeShellApplication {
    name = "mouse_battery_producer";
    runtimeInputs = with pkgs; [
      upower
      gawk
      gnugrep
      coreutils
      rivalcfg
      procps # pkill, ps
    ];

    text = ''
      # Every probe below may fail; the script decides what to print itself.
      set +e +o pipefail

      state_dir="''${XDG_RUNTIME_DIR:-/tmp}/waybar-mouse-battery"
      state_file="$state_dir/status.json"
      poll_seconds=10
      # A real-time signal kills a Waybar that hasn't set up its handlers
      # yet, so leave a newly started one alone for this long.
      waybar_min_age=3

      alt_for_pct() {
        local p="$1"
        if (( p <= 10 )); then echo "0"
        elif (( p <= 25 )); then echo "25"
        elif (( p <= 50 )); then echo "50"
        elif (( p <= 75 )); then echo "75"
        else echo "100"
        fi
      }

      class_for_pct() {
        local p="$1"
        if (( p <= 10 )); then echo "lowbat"
        elif (( p <= 25 )); then echo "nearlylowbat"
        elif (( p <= 50 )); then echo "midbat"
        else echo "fine"
        fi
      }

      json() {
        local text="$1" alt="$2" class="$3" pct="''${4:-}" tooltip="''${5:-}"

        if [[ -n "$pct" ]]; then
          if [[ -n "$tooltip" ]]; then
            printf '{"text":"%s","alt":"%s","class":"%s","percentage":%s,"tooltip":"%s"}\n' \
              "$text" "$alt" "$class" "$pct" "$tooltip"
          else
            printf '{"text":"%s","alt":"%s","class":"%s","percentage":%s}\n' \
              "$text" "$alt" "$class" "$pct"
          fi
        else
          if [[ -n "$tooltip" ]]; then
            printf '{"text":"%s","alt":"%s","class":"%s","tooltip":"%s"}\n' \
              "$text" "$alt" "$class" "$tooltip"
          else
            printf '{"text":"%s","alt":"%s","class":"%s"}\n' \
              "$text" "$alt" "$class"
          fi
        fi
      }

      probe() {
        local rc_out rc_pct cls alt mouse_dev info pct

        # 1) Primary path: dongle mode via rivalcfg
        rc_out="$(rivalcfg --battery-level 2>/dev/null | tr -d '\r' || true)"

        if [[ -n "$rc_out" ]]; then
          rc_pct="$(
            printf '%s\n' "$rc_out" |
              awk 'match($0, /([0-9]{1,3})[[:space:]]*%/, m) { print m[1]; exit }'
          )"

          if [[ -n "$rc_pct" ]] && [[ "$rc_pct" =~ ^[0-9]+$ ]] && (( rc_pct >= 0 && rc_pct <= 100 )); then
            if printf '%s' "$rc_out" | grep -qi '^charging'; then
              json "''${rc_pct}%" "charging" "charging" "$rc_pct" "rivalcfg: $rc_out"
            else
              cls="$(class_for_pct "$rc_pct")"
              alt="$(alt_for_pct "$rc_pct")"
              json "''${rc_pct}%" "$alt" "$cls" "$rc_pct" "rivalcfg: $rc_out"
            fi
            return
          fi

          if printf '%s' "$rc_out" | grep -qi '^charging'; then
            json "CHG" "charging" "charging" "" "rivalcfg: $rc_out"
            return
          fi
        fi

        # 2) Fallback path: Bluetooth mode via UPower
        mouse_dev="$(
          upower -e 2>/dev/null | awk '
            $0 ~ /^\/org\/freedesktop\/UPower\/devices\/mouse_/ { print; exit }
          '
        )"

        if [[ -n "$mouse_dev" ]]; then
          info="$(upower -i "$mouse_dev" 2>/dev/null | tr -d '\r')"

          pct="$(
            printf '%s\n' "$info" | awk '
              match($0, /percentage:[[:space:]]*([0-9]{1,3})%/, m) { print m[1]; exit }
            '
          )"

          if [[ -n "$pct" ]] && [[ "$pct" =~ ^[0-9]+$ ]] && (( pct >= 1 && pct <= 100 )); then
            cls="$(class_for_pct "$pct")"
            alt="$(alt_for_pct "$pct")"
            json "''${pct}%" "$alt" "$cls" "$pct" "upower: $mouse_dev"
            return
          fi

          json "DC" "0" "disconnected" "" "upower: no valid percentage"
          return
        fi

        # 3) No valid rivalcfg result and no UPower mouse device
        if [[ -n "$rc_out" ]]; then
          json "DC" "0" "disconnected" "" "rivalcfg: $rc_out"
        else
          json "DC" "0" "disconnected"
        fi
      }

      # nixpkgs' wrapper makes the process name .waybar-wrapped.
      waybar_name='(waybar|\.waybar-wrapped)'

      # True once every running Waybar is old enough to take a signal.
      waybar_ready() {
        local pids age
        pids="$(pgrep -d, -x "$waybar_name")" || return 1
        age="$(ps -o etimes= -p "$pids" | sort -n | head -n 1 | tr -d ' ')"
        [[ -n "$age" ]] && (( age >= waybar_min_age ))
      }

      mkdir -p "$state_dir"
      pending_signal=0

      is_disconnected() {
        [[ "$1" == *'"class":"disconnected"'* ]]
      }

      while true; do
        output="$(probe)"
        previous="$(cat "$state_file" 2>/dev/null)"

        # Unplugging the cable leaves the mouse re-pairing with the dongle
        # for a few seconds, and rivalcfg gets no answer meanwhile. Re-check
        # a few times before showing DC, so that gap never reaches the bar.
        if is_disconnected "$output" && [[ -n "$previous" ]] && ! is_disconnected "$previous"; then
          for _ in 1 2 3; do
            sleep 2
            output="$(probe)"
            is_disconnected "$output" || break
          done
        fi

        if [[ "$output" != "$previous" ]]; then
          tmp_file="$state_file.$$"
          printf '%s\n' "$output" > "$tmp_file"
          mv -f "$tmp_file" "$state_file"
          # Goes to the journal: journalctl --user -u mouse-battery
          printf 'reading changed: %s\n' "$output"
          pending_signal=1
        fi

        # A Waybar too young for the signal is retried on the next pass.
        if (( pending_signal )) && waybar_ready; then
          pkill -x -RTMIN+9 "$waybar_name"
          pending_signal=0
        fi

        sleep "$poll_seconds"
      done
    '';
  };

  # custom/steelseries' exec: every bar reads what the producer wrote.
  mouse_battery = pkgs.writeShellApplication {
    name = "mouse_battery";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      state_file="''${XDG_RUNTIME_DIR:-/tmp}/waybar-mouse-battery/status.json"

      if [[ -s "$state_file" ]]; then
        cat "$state_file"
      else
        printf '%s\n' '{"text":"DC","alt":"0","class":"disconnected","tooltip":"mouse-battery.service has no reading yet"}'
      fi
    '';
  };

  mouse_colour = pkgs.writeShellApplication {
    name = "mouse_colour";
    runtimeInputs = with pkgs; [ rivalcfg ];
    text = ''
      rivalcfg -d reactive -a 0000ff --top-color 0000ff --middle-color 0000ff --bottom-color 0000ff -s 800 -t 0 -T 1
    '';
  };
}
