# Bars on fractionally scaled outputs. Waybar sizes everything in logical
# pixels, so on a 1.25x output a bar comes out a quarter bigger than on a
# 1x one. Each bar that covers a listed output is split in two: a normal
# copy for its other outputs, and a 0.9x-high copy named "scaled" for the
# listed ones, which style.css shrinks by the same 0.9. That's short of the
# 0.8x that would cancel the scale, because a scaled output's pixels are
# usually denser too, and 0.8x looked too small in person.
#
# This rewrites home-manager's generated config file rather than adding a
# bar to programs.waybar.settings, because a bar defined from another one
# in that option is infinite recursion.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  scaled = config.features.home.waybar.scaledOutputs;
  inherit (config.programs.waybar) settings;

  bars = if builtins.isAttrs settings then lib.attrValues settings else settings;

  # What home-manager does before writing JSON: no "modules" option, no nulls.
  clean = bar: lib.filterAttrs (_: v: v != null) (removeAttrs bar [ "modules" ]);

  split =
    bar:
    let
      outputs = if bar ? output then lib.toList bar.output else null;
      onScaled = if outputs == null then scaled else lib.intersectLists scaled outputs;
      # Waybar skips outputs listed with a leading "!".
      plainOutputs =
        if outputs == null then map (o: "!" + o) scaled ++ [ "*" ] else lib.subtractLists scaled outputs;
      scaledBar =
        bar
        // {
          name = "scaled";
          output = onScaled;
        }
        // lib.optionalAttrs (bar ? height) { height = bar.height * 9 / 10; };
    in
    lib.optional (plainOutputs != [ ]) (bar // { output = plainOutputs; })
    ++ lib.optional (onScaled != [ ]) scaledBar;

  splitConfig = (pkgs.formats.json { }).generate "waybar-config.json" (
    lib.concatMap (bar: split (clean bar)) bars
  );
in
{
  options.features.home.waybar.scaledOutputs = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "DP-1" ];
    description = ''
      Outputs running at 1.25x scale. Their bars get a 0.9x-high copy named
      "scaled", which style.css shrinks to match the unscaled bars.
    '';
  };

  config = lib.mkIf (scaled != [ ]) {
    xdg.configFile."waybar/config".source = lib.mkForce splitConfig;
  };
}
