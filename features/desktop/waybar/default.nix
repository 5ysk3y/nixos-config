_: {
  flake.modules.homeManager.waybar = ./_module.nix;

  # nix run .#waybar-preview [-- --output DP-1 --top --inspect]
  #
  # Runs a second Waybar beside the live one, so a theme can be tried
  # without switching. It builds this host's bar config from the checkout,
  # and loads style.css from the checkout, reloading it on every save.
  # Ctrl+C closes it; the live bar is never touched.
  perSystem =
    { pkgs, lib, ... }:
    let
      themeFonts = import ./_theme-fonts.nix pkgs;

      # The system's fonts plus the theme's, which may not be installed yet.
      fontsConf = pkgs.writeText "waybar-preview-fonts.conf" ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
          <dir>${themeFonts}/share/fonts</dir>
        </fontconfig>
      '';

      preview = pkgs.writeShellApplication {
        name = "waybar-preview";
        runtimeInputs = with pkgs; [
          coreutils
          git
          jq
          waybar
        ];
        text = ''
          usage() {
            cat <<'EOF'
          Usage: nix run .#waybar-preview -- [options]

            --output NAME  Show the preview only on this output (repeatable).
                           Default: the live bar's outputs.
            --top          Put the preview at the top instead of the bottom.
            --style FILE   CSS to preview. Default: this checkout's
                           features/desktop/waybar/style.css.
            --inspect      Open GTK's inspector, to find widgets' CSS names.
            --live-config  Use the live bar's module settings from
                           ~/.config/waybar/config instead of building this
                           checkout's (faster, but misses config changes).
          EOF
          }

          outputs=()
          position=bottom
          style=""
          inspect=0
          live_config=0
          root=""

          while (( $# )); do
            case "$1" in
              --live-config) live_config=1; shift ;;
              --output) outputs+=("$2"); shift 2 ;;
              --top) position=top; shift ;;
              --style) style="$2"; shift 2 ;;
              --inspect) inspect=1; shift ;;
              -h | --help) usage; exit 0 ;;
              *) echo "waybar-preview: unknown option $1" >&2; usage >&2; exit 2 ;;
            esac
          done

          if [[ -z "$style" ]]; then
            root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
              echo "waybar-preview: run it inside the nixos-config checkout, or pass --style" >&2
              exit 1
            }
            style="$root/features/desktop/waybar/style.css"
          fi
          style="$(realpath "$style")"
          [[ -r "$style" ]] || { echo "waybar-preview: can't read $style" >&2; exit 1; }

          config_src="''${XDG_CONFIG_HOME:-$HOME/.config}/waybar/config"

          # Build this host's bar config from the checkout, so module
          # changes (formats, max-length) show up without switching.
          if (( ! live_config )) && [[ -n "$root" ]]; then
            host="$(uname -n)"
            attr="nixosConfigurations.\"$host\".config.home-manager.users.\"$USER\".xdg.configFile.\"waybar/config\".source"
            echo "waybar-preview: building $host's bar config from the checkout..."
            if built="$(nix build --no-link --print-out-paths "$root#$attr")"; then
              config_src="$built"
            else
              echo "waybar-preview: couldn't build it; using the live config instead" >&2
            fi
          fi
          [[ -r "$config_src" ]] || { echo "waybar-preview: no bar config at $config_src" >&2; exit 1; }

          work="$(mktemp -d -t waybar-preview.XXXXXX)"
          trap 'rm -rf "$work"' EXIT

          outputs_json="$(printf '%s\n' "''${outputs[@]}" | jq -R . | jq -sc 'map(select(. != ""))')"
          # --output narrows each bar to the asked outputs it already covers,
          # and drops bars left with none, so per-output bars keep their own
          # settings. A bar with no output list covers every output.
          jq --arg position "$position" --argjson outputs "$outputs_json" '
            def outs: if .output == null then null
              elif (.output | type) == "string" then [.output]
              else .output end;
            def narrow:
              if ($outputs | length) == 0 then .
              elif outs == null then .output = $outputs
              else .output = (outs - (outs - $outputs)) end;
            def preview: narrow + { position: $position, reload_style_on_change: true };
            (if type == "array" then . else [.] end)
            | map(preview | select((.output | length) > 0))
          ' "$config_src" > "$work/config"
          [[ "$(jq length "$work/config")" -gt 0 ]] || {
            echo "waybar-preview: no bar covers ''${outputs[*]}" >&2
            exit 1
          }

          export FONTCONFIG_FILE=${fontsConf}
          (( inspect )) && export GTK_DEBUG=interactive

          echo "waybar-preview: $style ($position). Save it to reload; Ctrl+C to quit."
          waybar --config "$work/config" --style "$style"
        '';
      };
    in
    {
      apps = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        waybar-preview = {
          type = "app";
          program = lib.getExe preview;
          meta.description = "Run a second Waybar with this checkout's style.css, reloading it on save";
        };
      };
    };
}
