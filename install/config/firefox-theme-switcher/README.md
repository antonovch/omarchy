# Firefox Theme Switcher Extension

> **Disclaimer**: This Firefox extension was written by prompting ChatGPT and Claude with no manual editing and is not listed on addons.mozilla.org.

A Firefox extension that allows theme switching from command line via native messaging. Designed for automated theme management in Linux desktop environments.


## Features

- Switch Firefox themes from command line
- Supports both built-in themes (light/dark) and installed theme extensions
- Persistent theme switching for extension-based themes
- State management for themes applied when Firefox is closed
- Native messaging integration with UNIX socket communication

## Architecture

The extension consists of three components:

1. **Firefox Extension** (`background.js`, `background.html`, `manifest.json`)
   - Manages theme switching via browser APIs
   - Communicates with native host via native messaging
   - Handles startup state restoration

2. **Native Messaging Host** (`firefox_theme_host.py`)
   - Python script that bridges Firefox extension and command line
   - Creates UNIX socket for CLI communication
   - Manages file operations and message routing

3. **Command Line Interface** (`omarchy-theme-firefox-set`)
   - Bash script for theme switching from terminal
   - Supports live switching via socket or state file for offline Firefox

## Installation

### For Development/Testing

1. Create the extension package:
   ```bash
   cd install/config/firefox-theme-switcher
   zip -j remote-theme-switcher@local.xpi background* manifest.json
   ```

2. Load as temporary add-on:
   - Open Firefox
   - Go to `about:debugging`
   - Click "Load Temporary Add-on"
   - Select the `.xpi` file

3. Install the native messaging host by moving `firefox_theme_host.py` to `~/.local/bin/` and create its manifest:
    ```bash
    cat > ~/.mozilla/native-messaging-hosts/com.local.theme_switcher.json <<EOF
    {
    "name": "com.local.theme_switcher",
    "description": "Bridge to switch Firefox theme from a local UNIX socket",
    "path": "${HOME}/.local/bin/firefox_theme_host.py",
    "type": "stdio",
    "allowed_extensions": ["remote-theme-switcher@local"]
    }
    EOF
    ```

### For Production

1. **Sign the extension**:
   - Log into [addons.mozilla.org](https://addons.mozilla.org/developers/)
   - Submit extension for signing
   - Download the signed `.xpi` file

2. **Update repository**:
   - Replace the `.xpi` file in this folder, so that it's installed by `install/config/firefox.sh`

## Usage

### Command Line Interface

```bash
# Switch to specific theme by ID
omarchy-theme-firefox-set "{theme-extension-id}"

# Switch to built-in themes (temporary, not persistent)
omarchy-theme-firefox-set dark
omarchy-theme-firefox-set light
omarchy-theme-firefox-set toggle
```

### Theme IDs

Theme IDs can be found in Firefox's theme management or by inspecting installed extensions. Examples:
- `{f5525f34-4102-4f6e-8478-3cf23cfeff7a}` - Catppuccin
- `{21ab01a8-2464-4824-bccb-6db15659347e}` - Gruvbox Material

## Development

### File Structure

```
install/config/firefox-theme-switcher/
README.md                   # This file
manifest.json               # Extension manifest
background.html             # Background page
background.js               # Main extension logic
firefox_theme_host.py       # Native messaging host
```

### Key Functions

- `applyScheme(scheme)` - Apply built-in light/dark themes
- `applyThemeById(themeId)` - Enable extension-based themes
- `toggleScheme()` - Toggle between light/dark
- `applyStartupTheme()` - Restore theme from state file

### Native Messaging

The extension communicates with the native host using JSON messages:
- `{"cmd": "dark"}` - Apply dark theme
- `{"cmd": "light"}` - Apply light theme  
- `{"cmd": "toggle"}` - Toggle theme
- `{"cmd": "applyThemeId", "themeId": "id"}` - Apply specific theme

## Troubleshooting

### Extension not loading
- Check Browser Console (Ctrl+Shift+J) for errors
- Verify manifest.json syntax
- Ensure all files are included in the .xpi package

### Native messaging issues
- Verify native host script permissions: `chmod +x ~/.local/bin/firefox_theme_host.py`
- Check manifest location: `~/.mozilla/native-messaging-hosts/com.local.theme_switcher.json`
- Test socket creation: `ls -la /run/user/*/firefox-theme-switcher.sock`

### Command line not working
- Ensure Firefox is running for live switching
- Check if socket exists and is accessible
- For offline switching, state file is created at `~/.config/firefox-theme-switcher/state.json`

## License

Part of the Omarchy desktop environment configuration.
