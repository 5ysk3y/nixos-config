# Single source of truth for macbook's overlays and their audit metadata.
# See hosts/personal/gibson/overlays/overlay-entries.nix for the full convention
# explanation (exempt vs meta, final vs prev discipline).
_: {
  permanent = final: prev: {
    qutebrowser = prev.qutebrowser.overrideAttrs (old: {
      # nixpkgs starts qutebrowser through a wrapper that runs its entry point
      # as a Python script, so the process's arguments are
      # `python .qutebrowser-wrapped ...`. macOS hands any plain argument to
      # the app as a file to open, and qutebrowser opened that script in a
      # tab on every launch. The first patch skips it.
      #
      # A link macOS hands the running qutebrowser opens as a tab, but
      # qutebrowser leaves its window where it is on purpose. macOS has
      # already made the app active, so you end up with no window in front,
      # and none when the window is full screen in another Space. The second
      # patch raises the window, as a link from another qutebrowser does.
      # Neither has an upstream report to track.
      patches = (old.patches or [ ]) ++ [
        ./patches/qutebrowser-skip-entry-script.patch
        ./patches/qutebrowser-raise-on-open-url.patch
      ];

      # nixpkgs builds the app bundle from the Linux .desktop file, and its
      # Info.plist doesn't say the app opens web links. macOS then never
      # offers it as a browser, so it can't be made the default. This adds
      # the http/https URL types and HTML document types that qutebrowser's
      # own macOS build declares. postFixup runs after the bundle is made.
      postFixup = (old.postFixup or "") + ''
        ${final.buildPackages.python3.interpreter} - "$out/Applications/qutebrowser.app/Contents/Info.plist" <<'EOF'
        import plistlib, sys
        path = sys.argv[1]
        with open(path, "rb") as f:
            info = plistlib.load(f)
        info["CFBundleURLTypes"] = [
            {"CFBundleURLName": "Web site URL", "CFBundleURLSchemes": ["http", "https"]},
        ]
        info["CFBundleDocumentTypes"] = [
            {
                "CFBundleTypeName": "HTML document",
                "CFBundleTypeRole": "Viewer",
                "LSItemContentTypes": ["public.html", "public.xhtml"],
            },
        ]
        with open(path, "wb") as f:
            plistlib.dump(info, f)
        EOF
      '';
    });
  };
  tracked = [ ];
}
