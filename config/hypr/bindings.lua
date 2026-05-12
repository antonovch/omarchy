-- Application bindings.
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd([[uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)"]]), { description = "Terminal" })
hl.bind("SUPER + ALT + RETURN", hl.dsp.exec_cmd([[uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" bash -c "tmux attach || tmux new -s Work"]]), { description = "Tmux" })
hl.bind("SUPER + SHIFT + RETURN", hl.dsp.exec_cmd("omarchy-launch-browser"), { description = "Browser" })
hl.bind("SUPER + SHIFT + F", hl.dsp.exec_cmd("uwsm-app -- nautilus --new-window"), { description = "File manager" })
hl.bind("SUPER + ALT + SHIFT + F", hl.dsp.exec_cmd([[uwsm-app -- nautilus --new-window "$(omarchy-cmd-terminal-cwd)"]]), { description = "File manager (cwd)" })
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("omarchy-launch-browser"), { description = "Browser" })
hl.bind("SUPER + SHIFT + ALT + B", hl.dsp.exec_cmd("omarchy-launch-browser --private"), { description = "Browser (private)" })
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("omarchy-launch-or-focus spotify"), { description = "Music" })
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("omarchy-launch-editor"), { description = "Editor" })
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("omarchy-launch-tui lazydocker"), { description = "Docker" })
hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd([[omarchy-launch-or-focus ^signal$ "uwsm-app -- signal-desktop"]]), { description = "Signal" })
hl.bind("SUPER + SHIFT + SLASH", hl.dsp.exec_cmd("uwsm-app -- keepmenu"), { description = "Passwords" })
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("uwsm-app -- code"), { description = "VS Code" })

-- Web app bindings.
hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd("uwsm-app -- ~/.local/share/applications/ChatGPT.desktop"), { description = "ChatGPT" })
hl.bind("SUPER + SHIFT + ALT + A", hl.dsp.exec_cmd("uwsm-app -- ~/.local/share/applications/Grok.desktop"), { description = "Grok" })
hl.bind("SUPER + SHIFT + CTRL + A", hl.dsp.exec_cmd("uwsm-app -- ~/.local/share/applications/Claude.desktop"), { description = "Claude" })
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("uwsm-app -- thunderbird"), { description = "Email" })
hl.bind("SUPER + SHIFT + Y", hl.dsp.exec_cmd("uwsm-app -- ~/.local/share/applications/YouTube.desktop"), { description = "YouTube" })
hl.bind("SUPER + SHIFT + ALT + G", hl.dsp.exec_cmd("uwsm-app -- ~/.local/share/applications/GitHub.desktop"), { description = "GitHub" })
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("uwsm-app -- ~/.local/share/applications/WhatsApp.desktop"), { description = "WhatsApp" })
-- hl.bind("SUPER + SHIFT + X", hl.dsp.exec_cmd("uwsm-app -- ~/.local/share/applications/X.desktop"), { description = "X" })

-- Add extra bindings below.
-- hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("alacritty -e ssh your-server"), { description = "SSH" })

-- Overwrite existing bindings with hl.unbind() first if needed.
-- hl.unbind("SUPER + SPACE")
-- hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("omarchy-menu"), { description = "Omarchy menu" })

-- Logitech MX Keys examples:
-- hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("omarchy-capture-screenshot"))
-- hl.bind("SUPER + H", hl.dsp.exec_cmd("voxtype record toggle"))
-- hl.bind("SUPER + PERIOD", hl.dsp.exec_cmd("omarchy-launch-walker -m symbols"))
