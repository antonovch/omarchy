-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

-- Keyboard layout and options.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
  input = {
    -- US and Ukrainian layouts, switched with CapsLock.
    kb_layout = "us,ua",

    -- Put Super on the key next to the space bar everywhere. PC keyboards need
    -- the Alt/Super swap for that; Apple keyboards already have Cmd there, so
    -- they are exempted below.
    kb_options = "altwin:swap_alt_win,grp:caps_toggle,apple:alupckeys",

    -- Change speed of keyboard repeat.
    repeat_rate = 40,
    repeat_delay = 250,

    -- Start with numlock on by default.
    numlock_by_default = true,

    -- Use natural (inverse) scrolling.
    natural_scroll = true,

    touchpad = {
      -- Use natural (inverse) scrolling.
      natural_scroll = true,

      -- Use two-finger clicks for right-click instead of lower-right corner.
      clickfinger_behavior = true,

      -- Tap-to-click.
      tap_to_click = false,

      -- Control the speed of your scrolling.
      scroll_factor = 0.4,
    },
  },
})

-- The built-in MacBook keyboard is SPI-attached and driven by applespi, which
-- unlike hid_apple has no swap_opt_cmd parameter -- only fnmode, fnremap,
-- iso_layout and touchpad_dimensions. So the /etc/modprobe.d/hid_apple.conf
-- counter-swap never reaches it, and the global altwin:swap_alt_win above lands
-- unopposed, putting Super one key too far from the space bar.
--
-- Override it per device instead. hid_apple's swap_opt_cmd stays relevant for
-- external Apple USB/Bluetooth boards, where it cancels the global swap.
hl.device({ name = "apple-spi-keyboard", kb_options = "grp:caps_toggle,apple:alupckeys" })

-- App-specific touchpad scroll speeds.
o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Enable touchpad gestures for changing workspaces.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
-- hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
