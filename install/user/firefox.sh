# Firefox is the default browser here (see omarchy-finalize-user), so set it up
# unconditionally rather than leaving it to Setup > Browser. omarchy-install-browser
# is idempotent: it applies policies to both the system install and the firefoxpwa
# runtime, installs the theme-switcher bridge, and enables Wayland.
omarchy-install-browser firefox

# socat carries theme changes to a running Firefox over the theme-switcher
# socket; without it omarchy-theme-firefox-set only writes the pending state.
omarchy-pkg-add socat || echo "Warning: socat unavailable; Firefox theme changes will apply on next start."

# Thunderbird backs the mailto handler that omarchy-finalize-user registers.
omarchy-pkg-add thunderbird || echo "Warning: thunderbird unavailable; the mailto handler will not resolve."

# Firefox has no --app, so the shipped web apps only get their own windows once
# each site is registered with firefoxpwa. Idempotent, so reruns are cheap.
omarchy-webapp-sync
