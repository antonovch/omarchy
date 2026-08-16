-- Personal keybinding overrides.
--
-- hypr/hyprland.lua sets omarchy_preinstalled_bindings = false, so Omarchy's
-- preinstalled app/web app keys are off and the ones below replace them.
--
-- The core app bindings in default/hypr/bindings/applications.lua are NOT gated
-- by that flag and already match what I want, so they're deliberately absent
-- here -- redefining them would bind those keys twice:
--   SUPER + RETURN            Terminal
--   SUPER + SHIFT + RETURN    Browser
--   SUPER + SHIFT + B         Browser
--   SUPER + SHIFT + ALT + B   Browser (private)
--   SUPER + SHIFT + F         File manager
--   SUPER + ALT + SHIFT + F   File manager (cwd)
--   SUPER + SHIFT + N         Editor
--
-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- Application bindings.
o.bind("SUPER + ALT + RETURN", "Tmux", { omarchy = "terminal-tmux" })
o.bind("SUPER + SHIFT + M", "Music", { omarchy = "or-focus spotify" })
o.bind("SUPER + SHIFT + ALT + M", "Music TUI", { tui = "cliamp", focus = true })
o.bind("SUPER + SHIFT + D", "Docker", { tui = "lazydocker" })
o.bind("SUPER + SHIFT + G", "Signal", { launch = "signal-desktop", focus = "^signal$" })
o.bind("SUPER + SHIFT + SLASH", "Passwords", { launch = "keepmenu" })
o.bind("SUPER + SHIFT + E", "Thunderbird", { launch = "thunderbird" })

-- Web app bindings.
o.bind("SUPER + SHIFT + A", "ChatGPT", o.cmd_present("chatgpt")
  and { launch = "chatgpt", focus = "chatgpt" }
  or { webapp = "https://chatgpt.com" })
o.bind("SUPER + SHIFT + ALT + A", "Grok", { webapp = "https://grok.com" })
o.bind("SUPER + SHIFT + CTRL + A", "Claude", { webapp = "https://claude.ai" })
o.bind("SUPER + SHIFT + Y", "YouTube", { webapp = "https://youtube.com/" })
o.bind("SUPER + SHIFT + ALT + G", "GitHub", { webapp = "https://github.com" })
o.bind("SUPER + SHIFT + W", "WhatsApp", { webapp = "https://web.whatsapp.com/", focus = true })
o.bind("SUPER + SHIFT + C", "Google Calendar", { webapp = "https://calendar.google.com/" })
o.bind("SUPER + SHIFT + S", "Google Maps", { webapp = "https://maps.google.com/", focus = true })
-- o.bind("SUPER + SHIFT + CTRL + G", "Google Messages", { webapp = "https://messages.google.com/web/conversations", focus = true })
-- o.bind("SUPER + SHIFT + P", "Google Photos", { webapp = "https://photos.google.com/", focus = true })
-- o.bind("SUPER + SHIFT + X", "X", { webapp = "https://x.com/" })

-- Universal undo, to sit alongside Omarchy's universal copy/paste/cut.
-- default/hypr/bindings/clipboard.lua keeps send_shortcut_once file-local, so
-- this repeats it. The down/up split works around Hyprland send_shortcut
-- sometimes leaving synthetic key state stuck/repeating, and the window target
-- is omitted so the chord also reaches focused layer-shell surfaces.
-- https://github.com/hyprwm/Hyprland/discussions/14099
local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

o.bind("SUPER + Z", "Universal undo", send_shortcut_once("CTRL", "Z"))
