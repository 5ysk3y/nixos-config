return function(WS)
  hl.config({
    render = {
      direct_scanout = 1,
      non_shader_cm = 2,
    },
  })

  hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
  hl.env("HYPRCURSOR_SIZE", "26")
  hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
  hl.env("XCURSOR_SIZE", "26")
  hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

  hl.monitor({
    output = "desc:Ancor Communications Inc VG248 G6LMQS045879",
    mode = "1920x1080@144",
    position = "0x200",
    scale = 1,
    bitdepth = 10,
  })

  hl.monitor({
    output = "desc:BNQ BenQ EX2780Q 66L07726019",
    mode = "2560x1440@120",
    position = "1920x0",
    scale = 1.25,
    vrr = 2,
    cm = "hdredid",
    sdrbrightness = 1.25,
    sdrsaturation = 1.0,
    sdr_max_luminance = 203,
    bitdepth = 10,
  })

  hl.monitor({
    output = "desc:BNQ BenQ GL2460 F1D09565SL0",
    mode = "1920x1080@60",
    position = "3968x160",
    scale = 1,
    bitdepth = 10,
  })

  hl.workspace_rule({ workspace = "name:" .. WS.WS1, monitor = "desc:BNQ BenQ EX2780Q 66L07726019", default = true })
  hl.workspace_rule({ workspace = "name:" .. WS.WS2, monitor = "desc:BNQ BenQ GL2460 F1D09565SL0" })
  hl.workspace_rule({ workspace = "name:" .. WS.WS3, monitor = "desc:BNQ BenQ EX2780Q 66L07726019" })
  hl.workspace_rule({ workspace = "name:" .. WS.WS4, monitor = "desc:BNQ BenQ EX2780Q 66L07726019" })
  hl.workspace_rule({ workspace = "name:" .. WS.WS5, monitor = "desc:Ancor Communications Inc VG248 G6LMQS045879" })
  hl.workspace_rule({ workspace = "name:" .. WS.WS6, monitor = "desc:BNQ BenQ GL2460 F1D09565SL0" })
  hl.workspace_rule({ workspace = "name:" .. WS.WS7, monitor = "desc:Ancor Communications Inc VG248 G6LMQS045879" })
  hl.workspace_rule({ workspace = "name:" .. WS.WS8, monitor = "desc:Ancor Communications Inc VG248 G6LMQS045879" })

  hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
  hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

  hl.bind("SUPER + F", hl.dsp.window.fullscreen())
  hl.bind("SUPER + code:36", hl.dsp.exec_cmd("kitty -1"))
  hl.bind("SUPER + D", hl.dsp.exec_cmd("fuzzel"))
  hl.bind("SUPER + X", hl.dsp.exec_cmd("makoctl dismiss"))
  hl.bind("SUPER + SHIFT + Q", hl.dsp.window.close())
  hl.bind("SUPER + SHIFT + C", hl.dsp.exit())
  hl.bind("SUPER + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }))

  hl.bind("code:123", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_SINK@ 5%+"), { locked = true, repeating = true })
  hl.bind("code:122", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_SINK@ 5%-"), { locked = true, repeating = true })
  hl.bind("code:121", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), { locked = true })


  hl.bind("SUPER + O", hl.dsp.exec_cmd("playerctl -p playerctld play-pause"))
  hl.bind("SUPER + SHIFT + O", hl.dsp.exec_cmd("playerctl -p cider play-pause"))

  hl.bind("SUPER + code:21", hl.dsp.exec_cmd("playerctl -p playerctld next"))
  hl.bind("SUPER + code:20", hl.dsp.exec_cmd("playerctl -p playerctld previous"))
  hl.bind("SUPER + SHIFT + code:21", hl.dsp.exec_cmd("playerctl -p cider next"))
  hl.bind("SUPER + SHIFT + code:20", hl.dsp.exec_cmd("playerctl -p cider previous"))

  hl.bind("SUPER + P", hl.dsp.exec_cmd("grimblast --notify copy output"))
  hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("grimblast --notify copy area"))
  hl.bind("SUPER + CTRL + P", hl.dsp.exec_cmd("grimblast --notify copy window"))
  hl.bind("SUPER + ALT + P", hl.dsp.exec_cmd("grimblast --notify copy screen"))

  hl.bind("SUPER + h", hl.dsp.focus({ direction = "l" }))
  hl.bind("SUPER + l", hl.dsp.focus({ direction = "r" }))
  hl.bind("SUPER + k", hl.dsp.focus({ direction = "u" }))
  hl.bind("SUPER + j", hl.dsp.focus({ direction = "d" }))

  hl.bind("SUPER + CTRL + h", hl.dsp.window.move({ direction = "l" }))
  hl.bind("SUPER + CTRL + l", hl.dsp.window.move({ direction = "r" }))
  hl.bind("SUPER + CTRL + k", hl.dsp.window.move({ direction = "u" }))
  hl.bind("SUPER + CTRL + j", hl.dsp.window.move({ direction = "d" }))

  hl.bind("SUPER + ALT + h", hl.dsp.window.resize({ x = -25, y = 0, relative = true }))
  hl.bind("SUPER + ALT + l", hl.dsp.window.resize({ x = 25, y = 0, relative = true }))
  hl.bind("SUPER + ALT + k", hl.dsp.window.resize({ x = 0, y = -25, relative = true }))
  hl.bind("SUPER + ALT + j", hl.dsp.window.resize({ x = 0, y = 25, relative = true }))

  hl.bind("ALT + TAB", hl.dsp.focus({ urgent_or_last = true }))

  hl.bind("SUPER + R", hl.dsp.exec_cmd("hyprctl dispatch reload"))
  hl.bind("SUPER + SHIFT + l", hl.dsp.exec_cmd("hyprlock --immediate"))

  hl.bind("SUPER + SHIFT + j", hl.dsp.group.prev())
  hl.bind("SUPER + SHIFT + k", hl.dsp.group.next())

  hl.bind("SUPER + 1", hl.dsp.focus({ workspace = "name:" .. WS.WS1 }))
  hl.bind("SUPER + 2", hl.dsp.focus({ workspace = "name:" .. WS.WS2 }))
  hl.bind("SUPER + 3", hl.dsp.focus({ workspace = "name:" .. WS.WS3 }))
  hl.bind("SUPER + 4", hl.dsp.focus({ workspace = "name:" .. WS.WS4 }))
  hl.bind("SUPER + 5", hl.dsp.focus({ workspace = "name:" .. WS.WS5 }))
  hl.bind("SUPER + 6", hl.dsp.focus({ workspace = "name:" .. WS.WS6 }))
  hl.bind("SUPER + 7", hl.dsp.focus({ workspace = "name:" .. WS.WS7 }))
  hl.bind("SUPER + 8", hl.dsp.focus({ workspace = "name:" .. WS.WS8 }))
  hl.bind("SUPER + 9", hl.dsp.focus({ workspace = "name:9-ext3" }))
  hl.bind("SUPER + 0", hl.dsp.focus({ workspace = "name:10-ext4" }))

  hl.bind("SUPER + SHIFT + 1", hl.dsp.window.move({ workspace = "name:" .. WS.WS1 }))
  hl.bind("SUPER + SHIFT + 2", hl.dsp.window.move({ workspace = "name:" .. WS.WS2 }))
  hl.bind("SUPER + SHIFT + 3", hl.dsp.window.move({ workspace = "name:" .. WS.WS3 }))
  hl.bind("SUPER + SHIFT + 4", hl.dsp.window.move({ workspace = "name:" .. WS.WS4 }))
  hl.bind("SUPER + SHIFT + 5", hl.dsp.window.move({ workspace = "name:" .. WS.WS5 }))
  hl.bind("SUPER + SHIFT + 6", hl.dsp.window.move({ workspace = "name:" .. WS.WS6 }))
  hl.bind("SUPER + SHIFT + 7", hl.dsp.window.move({ workspace = "name:" .. WS.WS7 }))
  hl.bind("SUPER + SHIFT + 8", hl.dsp.window.move({ workspace = "name:" .. WS.WS8 }))
  hl.bind("SUPER + SHIFT + 9", hl.dsp.window.move({ workspace = "name:9-ext3" }))
  hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = "name:10-ext4" }))

  hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
  hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

  hl.window_rule({ match = { class = "^(gcr-prompter)$" }, workspace = "name:" .. WS.WS1 })
  hl.window_rule({ match = { class = "^(kitty)$" }, workspace = "name:" .. WS.WS1 })

  hl.window_rule({ match = { class = "^(.*)(qutebrowser)(.*)" }, workspace = "name:" .. WS.WS2 })
  hl.window_rule({
    match = { class = "^(kitty)$", title = "^(rbw password prompt)$" },
    float = true,
    center = true,
    size = { 780, 320 },
    workspace = "name:" .. WS.WS2,
  })

  hl.window_rule({ match = { tag = "game_launcher" }, workspace = "name:" .. WS.WS3 })
  hl.window_rule({ match = { tag = "game" }, workspace = "name:" .. WS.WS3 })
  hl.window_rule({ match = { workspace = "name:" .. WS.WS3, fullscreen = true }, tag = "+game" })
  hl.window_rule({ match = { class = "^(steam)$" }, center = true, workspace = "name:" .. WS.WS3 })
  hl.window_rule({
    match = { class = "^(steam)$", title = "^(Special Offers)(.*)$" },
    float = true,
    size = { 1059, 735 },
    workspace = "name:" .. WS.WS3,
  })
  hl.window_rule({ match = { class = "XIVLauncher.Core" }, float = true, center = true, size = { 1176, 642 }, workspace = "name:" .. WS.WS3 })
  hl.window_rule({ match = { class = "^(battle%.net%.exe)$" }, float = true, center = true, fullscreen_state = "0 0", size = { 1481, 867 }, workspace = "name:" .. WS.WS3 })
  hl.window_rule({ match = { title = "^(Wine System Tray)$" }, move = { 4313, 42 }, workspace = "name:" .. WS.WS3 })
  hl.window_rule({ match = { class = "^(explorer.exe)$" }, move = { 1945, 1072 }, workspace = "name:" .. WS.WS3 })
  hl.window_rule({ match = { class = "^(gamescope)$" }, no_blur = true, workspace = "name:" .. WS.WS3 })
  hl.window_rule({ match = { title = "^(007 First Light)$" }, no_blur = true, workspace = "name:" .. WS.WS3 })
  hl.window_rule({ match = { class = "^(steam_app_0)$" }, no_blur = true, workspace = "name:" .. WS.WS3 })

  hl.window_rule({ match = { class = "^(spicy)$" }, workspace = "name:" .. WS.WS4, fullscreen = true, idle_inhibit = "fullscreen" })
  hl.window_rule({ match = { class = "^(virt-manager)$" }, workspace = "name:" .. WS.WS4, float = true, center = true, size = { 970, 560 } })
  hl.window_rule({ match = { title = "^(th3h4x0r)$" }, idle_inhibit = "focus" })
  hl.window_rule({ match = { class = "^(burp-StartBurp|firefox)$" }, workspace = "name:" .. WS.WS4 })

  hl.window_rule({ match = { class = "^(WebCord)(.*)" }, workspace = "name:" .. WS.WS5 })
  hl.window_rule({ match = { class = "^(discord)(.*)" }, workspace = "name:" .. WS.WS5 })
  hl.window_rule({ match = { class = "^(signal)$" }, workspace = "name:" .. WS.WS5 })

  hl.window_rule({ match = { class = "^(cider)$" }, workspace = "name:" .. WS.WS6 })
  hl.window_rule({ match = { class = "^(.*)(mpv)(.*)$" }, workspace = "name:" .. WS.WS6, fullscreen = true })
  hl.window_rule({ match = { class = "^(.*)(org.jellyfin.JellyfinDesktop)(.*)$" }, workspace = "name:" .. WS.WS6 })

  hl.window_rule({ match = { class = "^(Bitwarden)$" }, workspace = "name:" .. WS.WS7 })

  hl.window_rule({ match = { class = "^(.*)(obs)(.*)$" }, workspace = "name:" .. WS.WS8 })

  hl.window_rule({ match = { class = "^(XIVLauncher.Core|heroic|stream|steam_app|battle.net)" }, tag = "+game_launcher" })
  hl.window_rule({ match = { class = "^(discord|signal|Webcord)$" }, tag = "+social" })
  hl.window_rule({ match = { class = "^(cider|org.jellyfin.JellyfinDesktop)" }, tag = "+media" })
  hl.window_rule({ match = { class = "^(burp-StartBurp|firefox)$" }, tag = "+h4x0r" })
  hl.window_rule({ match = { title = "^(Heroic Games Launcher)" }, tag = "+game_launcher" })

  hl.window_rule({ match = { class = "^(discord)$" }, group = "set lock always" })
  hl.window_rule({ match = { class = "^(signal)$" }, group = "invade always" })
  hl.window_rule({ match = { class = "^(cider)$" }, group = "set lock always" })
  hl.window_rule({ match = { class = "^(org.jellyfin.JellyfinDesktop)$" }, group = "invade always" })

  hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("[group new lock] discord")
    hl.exec_cmd("[group new lock] cider-2")
    hl.exec_cmd([[mpvpaper '*' /home/rickie/.config/Wallpapers/Cyberpunk/Cyberpunk-2077-Game-4K-Animated-Desktop.mp4 --mpv-options="profile=wallpaper" -f]])
    hl.exec_cmd("qutebrowser")
    hl.exec_cmd("bitwarden")
    hl.exec_cmd("kitty -1")
    hl.exec_cmd("signal-desktop")
    hl.exec_cmd("sleep 0.5 && hyprctl dispatch moveintogroup l")
    hl.exec_cmd("jellyfin-desktop")
    hl.exec_cmd("sleep 0.5 && hyprctl dispatch moveintogroup l")
    hl.exec_cmd("jellyfin-mpv-shim")
    hl.exec_cmd("openrgb --profile MainBlue.orp > /dev/null 2>&1")
  end)
end
