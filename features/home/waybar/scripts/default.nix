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

      # 1) Charging state from rivalcfg (authoritative when it says Charging)
      rc_out="$(rivalcfg --battery-level 2>/dev/null || true)"

      if printf '%s' "$rc_out" | grep -qi '^charging'; then
        rc_pct="$(printf '%s' "$rc_out" | grep -Eo '[0-9]{1,3}' | head -n1 || true)"
        if [[ -n "$rc_pct" ]] && [[ "$rc_pct" =~ ^[0-9]+$ ]] && (( rc_pct >= 0 && rc_pct <= 100 )); then
          json "''${rc_pct}%" "charging" "charging" "$rc_pct" "rivalcfg: $rc_out"
          exit 0
        fi
        json "CHG" "charging" "charging" "" "rivalcfg: $rc_out"
        exit 0
      fi

      # 2) Wireless percentage from UPower mouse device path
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

      # 3) No UPower mouse device and not charging
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
      rivalcfg d reactive -a 0000ff --top-color 0000ff --middle-color 0000ff --bottom-color 0000ff -s 800 -t 0 -T 1
    '';
  };
}
