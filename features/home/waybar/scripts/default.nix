{
  pkgs,
}:
{
  check_rbw = pkgs.writeShellApplication {
    name = "check_rbw";
    runtimeInputs = with pkgs; [
      rbw
      coreutils
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

  mouse_battery = pkgs.writeShellApplication {
    name = "mouse_battery";
    runtimeInputs = with pkgs; [
      upower
      gawk
      gnugrep
      coreutils
      rivalcfg
    ];

    text = ''
      set +e +u +o pipefail
      set -u

      cache_dir="''${XDG_RUNTIME_DIR:-/tmp}/waybar-mouse-battery"
      cache_file="$cache_dir/status.json"
      lock_file="$cache_dir/lock"
      cache_ttl=20

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
        local output tmp_file

        if [[ -n "$pct" ]]; then
          if [[ -n "$tooltip" ]]; then
            output="$(printf '{"text":"%s","alt":"%s","class":"%s","percentage":%s,"tooltip":"%s"}' \
              "$text" "$alt" "$class" "$pct" "$tooltip")"
          else
            output="$(printf '{"text":"%s","alt":"%s","class":"%s","percentage":%s}' \
              "$text" "$alt" "$class" "$pct")"
          fi
        else
          if [[ -n "$tooltip" ]]; then
            output="$(printf '{"text":"%s","alt":"%s","class":"%s","tooltip":"%s"}' \
              "$text" "$alt" "$class" "$tooltip")"
          else
            output="$(printf '{"text":"%s","alt":"%s","class":"%s"}' \
              "$text" "$alt" "$class")"
          fi
        fi

        tmp_file="$cache_file.$$"
        printf '%s\n' "$output" > "$tmp_file"
        mv -f "$tmp_file" "$cache_file"
        printf '%s\n' "$output"
      }

      mkdir -p "$cache_dir"

      if [[ -s "$cache_file" ]]; then
        now="$(date +%s)"
        mtime="$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)"

        if (( now - mtime < cache_ttl )); then
          cat "$cache_file"
          exit 0
        fi
      fi

      exec 9>"$lock_file"

      if ! flock -n 9; then
        if [[ -s "$cache_file" ]]; then
          cat "$cache_file"
          exit 0
        fi

        json "DC" "0" "disconnected" "" "battery query locked"
        exit 0
      fi

      # Another Waybar instance may have refreshed the cache while this one waited.
      if [[ -s "$cache_file" ]]; then
        now="$(date +%s)"
        mtime="$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)"

        if (( now - mtime < cache_ttl )); then
          cat "$cache_file"
          exit 0
        fi
      fi

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
          exit 0
        fi

        if printf '%s' "$rc_out" | grep -qi '^charging'; then
          json "CHG" "charging" "charging" "" "rivalcfg: $rc_out"
          exit 0
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
          exit 0
        fi

        json "DC" "0" "disconnected" "" "upower: no valid percentage"
        exit 0
      fi

      # 3) No valid rivalcfg result and no UPower mouse device
      if [[ -n "$rc_out" ]]; then
        json "DC" "0" "disconnected" "" "rivalcfg: $rc_out"
      else
        json "DC" "0" "disconnected"
      fi

      exit 0
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
