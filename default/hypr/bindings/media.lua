-- Volume, brightness, keyboard backlight, and touchpad controls.
o.bind("XF86AudioRaiseVolume", "Volume up", "omarchy-swayosd-client --output-volume raise", { locked = true, repeating = true })
o.bind("XF86AudioLowerVolume", "Volume down", "omarchy-swayosd-client --output-volume lower", { locked = true, repeating = true })
o.bind("XF86AudioMute", "Mute", "omarchy-swayosd-client --output-volume mute-toggle", { locked = true, repeating = true })
o.bind("XF86AudioMicMute", "Mute microphone", "omarchy-audio-input-mute", { locked = true, repeating = true })
o.bind("XF86MonBrightnessUp", "Brightness up", "omarchy-brightness-display +5%", { locked = true, repeating = true })
o.bind("XF86MonBrightnessDown", "Brightness down", "omarchy-brightness-display 5%-", { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessUp", "Brightness maximum", "omarchy-brightness-display 100%", { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessDown", "Brightness minimum", "omarchy-brightness-display 1%", { locked = true, repeating = true })

-- Keyboard brightness with 10% increments and swayosd feedback
local kbdBacklightCmd = function(action)
  return "brightnessctl --device=spi::kbd_backlight set " .. action .. " && omarchy-swayosd-client --custom-progress=$(awk 'BEGIN {print $(brightnessctl --device=spi::kbd_backlight get)/255}') --custom-icon=input-keyboard"
end

o.bind("XF86KbdBrightnessDown", "Keyboard brightness down", kbdBacklightCmd("10%-"), { locked = true, repeating = true })
o.bind("XF86KbdBrightnessUp", "Keyboard brightness up", kbdBacklightCmd("+10%"), { locked = true, repeating = true })

-- Keyboard brightness min/max with SHIFT
o.bind("SHIFT + XF86KbdBrightnessDown", "Keyboard brightness minimum", kbdBacklightCmd("0%"), { locked = true })
o.bind("SHIFT + XF86KbdBrightnessUp", "Keyboard brightness maximum", kbdBacklightCmd("100%"), { locked = true })

-- Keyboard brightness precise 1% increments with ALT
o.bind("ALT + XF86KbdBrightnessDown", "Keyboard brightness down precise", kbdBacklightCmd("1%-"), { locked = true, repeating = true })
o.bind("ALT + XF86KbdBrightnessUp", "Keyboard brightness up precise", kbdBacklightCmd("+1%"), { locked = true, repeating = true })

o.bind("XF86KbdLightOnOff", "Keyboard backlight cycle", "omarchy-brightness-keyboard cycle", { locked = true })
o.bind("XF86TouchpadToggle", "Toggle touchpad", "omarchy-toggle-touchpad", { locked = true })
o.bind("XF86TouchpadOn", "Enable touchpad", "omarchy-toggle-touchpad on", { locked = true })
o.bind("XF86TouchpadOff", "Disable touchpad", "omarchy-toggle-touchpad off", { locked = true })

-- Precise volume and brightness controls.
o.bind("ALT + XF86AudioRaiseVolume", "Volume up precise", "omarchy-swayosd-client --output-volume +1", { locked = true, repeating = true })
o.bind("ALT + XF86AudioLowerVolume", "Volume down precise", "omarchy-swayosd-client --output-volume -1", { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessUp", "Brightness up precise", "omarchy-brightness-display +1%", { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessDown", "Brightness down precise", "omarchy-brightness-display 1%-", { locked = true, repeating = true })

-- Media controls.
o.bind("XF86AudioNext", "Next track", "omarchy-swayosd-client --playerctl next", { locked = true })
o.bind("XF86AudioPause", "Pause", "omarchy-swayosd-client --playerctl play-pause", { locked = true })
o.bind("XF86AudioPlay", "Play", "omarchy-swayosd-client --playerctl play-pause", { locked = true })
o.bind("XF86AudioPrev", "Previous track", "omarchy-swayosd-client --playerctl previous", { locked = true })

o.bind("SUPER + XF86AudioMute", "Switch audio output", "omarchy-audio-output-switch", { locked = true })
