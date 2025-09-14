#!/bin/bash

# Install separate runtime for PWA
wget -q -O firefox.tar.xz 'https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US'
if [[ -v XDG_DATA_HOME ]]; then
  PWA_RUNTIME_DIR="$XDG_DATA_HOME/firefoxpwa/runtime/"
else
  PWA_RUNTIME_DIR="$HOME/.local/share/firefoxpwa/runtime/"
fi

mkdir -p $PWA_RUNTIME_DIR
tar -xf firefox.tar.xz --strip-components 1 -C $PWA_RUNTIME_DIR
rm firefox.tar.xz

# Default policy and addons (PWA and themes)
if [[ ! -f /usr/lib/firefox/distribution/policies.json ]]; then
  sudo tee /usr/lib/firefox/distribution/policies.json > /dev/null <<EOF
{
  "policies": {
    "DisableTelemetry": true,
    "DisableFirefoxStudies": true,
    "DNSOverHTTPS": {
      "Enabled": true,
      "ProviderURL": "https://cloudflare-dns.com/dns-query",
      "Locked": false
    },
    "Extensions": {
      "Install": [
        "file://${HOME}/.local/share/omarchy/install/config/firefox-theme-switcher/remote-theme-switcher@local.xpi"
      ]
    },
    "SearchEngines": {
      "Default": "DuckDuckGo",
      "PreventInstalls": false
    },
    "ExtensionSettings": {
      "firefoxpwa@filips.si": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/file/4537285/pwas_for_firefox-2.15.0.xpi"
      },
      "{f5525f34-4102-4f6e-8478-3cf23cfeff7a}": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/file/3880040/catppuccin-1.0.xpi"
      },
      "{c827c446-3d00-4160-a992-3ebcbe6d81a6}": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/file/3990326/catppuccin_latte_mauve_git-2.0.xpi"
      },
      "{0e5c8ff0-b54b-4bd1-b33e-d5e016e066f0}": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/file/4565364/everforest_dark_medium_theme-2.4.xpi"
      },
      "{21ab01a8-2464-4824-bccb-6db15659347e}": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/file/4503497/gruvbox_material_soft_theme-1.8.xpi"
      },
      "{21ab01a8-2464-4824-bccb-6db15659347e}": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/file/2589656/japan_style_kanagawa_gr_232767-2.0.xpi"
      },
      "{f2b832a9-f0f5-4532-934c-74b25eb23fb9}": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/file/4226379/matte_black_v1-2024.1.24.xpi"
      },
      "{f4c9e1d6-6630-4600-ad50-d223eab7f3e7}": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/file/3849722/nord_firefox-2.41.xpi"
      },
      "{820afd08-7271-4f9d-8cec-43211ff42102}": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/file/4005577/lambo_countach_darkgreen-1.0.xpi"
      },
      "{930de1b4-9447-4927-9877-4f7cc369bc57}": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/file/3880719/monokai_pro_filter_ristretto-1.2.xpi"
      },
      "{cebd391d-f568-473f-bb6e-698d08ec81ec}": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/file/4567102/tokyo_night_dark_theme-2.6.xpi"
      }
    }
  }
}
EOF
fi

if [[ ! -f /usr/lib/firefox/firefox.cfg ]]; then
  sudo tee /usr/lib/firefox/firefox.cfg > /dev/null <<EOF
// First line must be a comment
// Use defaultPref to set defaults that can be overridden
defaultPref("browser.urlbar.trimURLs", false);
defaultPref("browser.urlbar.placeholderName", "DuckDuckGo");
defaultPref("browser.urlbar.placeholderName.private", "DuckDuckGo");
defaultPref("browser.tabs.insertAfterCurrent", true);
defaultPref("browser.startup.page", 3); // 3 = restore previous session
EOF
fi

if [[ ! -f /usr/lib/firefox/defaults/pref/autoconfig.js ]]; then
  sudo tee /usr/lib/firefox/defaults/pref/autoconfig.js > /dev/null <<EOF
pref("general.config.filename", "firefox.cfg");
pref("general.config.obscure_value", 0);
EOF
fi

cp ~/.local/share/omarchy/install/config/firefox-theme-switcher/firefox_theme_host.py ~/.local/bin/firefox_theme_host.py
chmod +x ~/.local/bin/firefox_theme_host.py

xdg-settings set default-web-browser firefox.desktop

mkdir -p ~/.mozilla/native-messaging-hosts
cat > ~/.mozilla/native-messaging-hosts/com.local.theme_switcher.json <<EOF
{
  "name": "com.local.theme_switcher",
  "description": "Bridge to switch Firefox theme from a local UNIX socket",
  "path": "${HOME}/.local/bin/firefox_theme_host.py",
  "type": "stdio",
  "allowed_extensions": ["remote-theme-switcher@local"]
}
EOF
