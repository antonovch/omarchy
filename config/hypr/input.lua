-- Control your input devices.
-- See https://wiki.hypr.land/Configuring/Variables/#input
hl.config({
  input = {
    -- Use multiple keyboard layouts and switch between them with CapsLock.
    kb_layout = "us,ua",

    kb_options = "altwin:swap_alt_win,grp:caps_toggle,apple:alupckeys",

    -- Change speed of keyboard repeat.
    repeat_rate = 40,
    repeat_delay = 250,

    -- Start with numlock on by default.
    numlock_by_default = true,

    -- Use natural (inverse) scrolling.
    natural_scroll = true,

    -- Increase sensitivity for mouse/trackpad (default: 0).
    -- sensitivity = 0.35,

    -- Turn off mouse acceleration (default: adaptive).
    -- accel_profile = "flat",

    touchpad = {
      -- Use natural (inverse) scrolling.
      natural_scroll = true,

      -- Use two-finger clicks for right-click instead of lower-right corner.
      clickfinger_behavior = true,

      -- Tap-to-click.
      tap_to_click = true,

      -- Control the speed of your scrolling.
      scroll_factor = 0.4,

      -- Enable the touchpad while typing.
      -- disable_while_typing = false,

      -- Left-click-and-drag with three fingers.
      -- drag_3fg = 1,
    },
  },
})

-- Built-in MacBook keyboard: keep native Mac layout (no Alt/Super swap).
-- Note: hl.device() is not available in omarchy's hl API
-- TODO: Configure per-device input via alternative method if needed
-- hl.device({
--   name = "apple-spi-keyboard",
--   kb_layout = "us,ua",
--   kb_options = "grp:caps_toggle,apple:alupckeys",
-- })

-- Scroll nicely in the terminal.
o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Enable touchpad gestures for changing workspaces.
-- See https://wiki.hypr.land/Configuring/Gestures/
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Enable touchpad gestures for moving focus (helpful on scrolling layout).
-- hl.gesture({ fingers = 3, direction = "left", action = function() hl.dispatch(hl.dsp.focus({ direction = "l" })) end })
-- hl.gesture({ fingers = 3, direction = "right", action = function() hl.dispatch(hl.dsp.focus({ direction = "r" })) end })

-- Enable per-window layout switching.
hl.on("hyprland.start", function()
  hl.exec_cmd("/usr/bin/hyprland-per-window-layout")
end)
