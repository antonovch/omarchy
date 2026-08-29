# Omarchy

Omarchy is a beautiful, modern & opinionated Linux distribution by DHH.

Read more at [omarchy.org](https://omarchy.org).

## The Omarchy Manual

The manual lives in [`manual/`](manual/), which is its authoritative source. It's
mirrored to [learn.omacom.io](https://learn.omacom.io/2/the-omarchy-manual), where
its screenshots are also hosted.

- [Welcome to Omarchy!](manual/01-welcome-to-omarchy.md)

**The Basics**

- [Getting Started](manual/02-getting-started.md)
- [Coming From Mac or Windows](manual/03-coming-from-mac-or-windows.md)
- [Navigation](manual/04-navigation.md)
- [The top bar](manual/05-the-top-bar.md)
- [Themes](manual/06-themes.md)
- [Hotkeys](manual/07-hotkeys.md)
- [Unified Clipboard & History](manual/08-unified-clipboard-history.md)
- [Reminders](manual/09-reminders.md)
- [Notices](manual/10-notices.md)
- [Text Extraction & Dictation](manual/11-text-extraction-dictation.md)
- [Screenshots & Recording](manual/12-screenshots-recording.md)
- [Toggles, idle & screensaver](manual/13-toggles-idle-screensaver.md)
- [Omarchy CLI](manual/14-omarchy-cli.md)

**The Applications**

- [Terminal](manual/15-terminal.md)
- [Neovim](manual/16-neovim.md)
- [AI](manual/17-ai.md)
- [Development Tools](manual/18-development-tools.md)
- [Shell Tools](manual/19-shell-tools.md)
- [Shell Functions](manual/20-shell-functions.md)
- [TUIs](manual/21-tuis.md)
- [GUIs](manual/22-guis.md)
- [Browsers](manual/23-browsers.md)
- [Commercial apps/services](manual/24-commercial-apps-services.md)
- [Web Apps](manual/25-web-apps.md)
- [Gaming](manual/26-gaming.md)
- [Filling out PDFs](manual/27-filling-out-pdfs.md)
- [Windows VM](manual/28-windows-vm.md)
- [Other Packages](manual/29-other-packages.md)

**Configuration**

- [Updates](manual/30-updates.md)
- [Dotfiles](manual/31-dotfiles.md)
- [Shell plugins](manual/32-shell-plugins.md)
- [Monitors](manual/33-monitors.md)
- [Keyboard, Mouse, Trackpad](manual/34-keyboard-mouse-trackpad.md)
- [Networking](manual/35-networking.md)
- [System sleep](manual/36-system-sleep.md)
- [Hardware authentication](manual/37-hardware-authentication.md)
- [Fonts](manual/38-fonts.md)
- [Backgrounds](manual/39-backgrounds.md)
- [Prompt](manual/40-prompt.md)
- [Branding](manual/41-branding.md)
- [Common tweaks](manual/42-common-tweaks.md)
- [Making your own theme](manual/43-making-your-own-theme.md)

**The Rest**

- [Mac support](manual/44-mac-support.md)
- [Troubleshooting](manual/45-troubleshooting.md)
- [FAQ](manual/46-faq.md)
- [System snapshots](manual/47-system-snapshots.md)
- [Security](manual/48-security.md)
- [Omarchy on...](manual/49-omarchy-on.md)
- [Dual Boot Install](manual/50-dual-boot-install.md)
- [Unattended Installs](manual/51-unattended-installs.md)

## Running this fork

This is a personal fork. It is **not** an installer, and it is not what gets
installed — Omarchy 4 is package-backed and ISO-only, so the packages always come
from upstream. The fork is an overlay switched on afterwards with
`omarchy-dev-link`, which writes `/etc/omarchy.conf` to point `$OMARCHY_PATH` at
this checkout instead of `/usr/share/omarchy`.

That is the opposite of the pre-4.0 arrangement, where the checkout at
`~/.local/share/omarchy` *was* the installation.

### Fresh install

1. **Install stock Omarchy from the ISO.** Reboot. Don't customize anything yet.
2. **Clone this fork** and check out the branch tracking the current release:

   ```bash
   git clone git@github.com:antonovch/omarchy ~/Projects/omarchy
   ```

3. **Point Omarchy at it**, then reboot so the shell, session, systemd and
   launcher environments all agree:

   ```bash
   omarchy-dev-link ~/Projects/omarchy
   ```

4. **Run the fork's install leaves.** A fresh install already ran
   `omarchy-apply-hardware` and `omarchy-provision-user` out of the *package*,
   before this checkout existed, so the MacBook fixes, Firefox setup, keepmenu
   and zsh never executed. Both are idempotent:

   ```bash
   sudo OMARCHY_PATH="$HOME/Projects/omarchy" omarchy-apply-hardware --install-user "$USER"
   omarchy-provision-user --force
   ```

   The `OMARCHY_PATH=` prefix is not optional. `sudo` does not preserve it, and
   `omarchy-apply-hardware` defaults to `/usr/share/omarchy`, so a bare
   `sudo omarchy-apply-hardware` silently runs the *packaged* leaves and skips
   every fix — while the sudoers entry `omarchy-dev-link` installs makes it look
   like the checkout is in charge. `sudo -i omarchy-apply-hardware …` also works.

5. **Copy the customized configs into `$HOME`.** `/etc/skel` only seeds a brand
   new user, so an existing `~/.config` file is never replaced by an update:

   ```bash
   for f in hypr/bindings.lua hypr/hyprland.lua hypr/input.lua hypr/looknfeel.lua \
            keepmenu/config.ini btop/btop.conf Code/User/keybindings.json \
            omarchy/extensions/omarchy-menu.jsonc \
            omarchy/hooks/post-update.d/restore-branding; do
     omarchy-refresh-config "$f"
   done
   ```

   Check what still differs at any time with:

   ```bash
   for f in $(git diff v4.0.1 --name-only -- config/ | sed 's|^config/||'); do
     diff -q "config/$f" "$HOME/.config/$f" >/dev/null 2>&1 || echo "$f differs"
   done
   ```

6. **Restore the branding** at the package paths `omarchy-dev-link` cannot shadow:

   ```bash
   omarchy-refresh-plymouth       # also sets the device scale; rebuilds the initramfs
   omarchy-refresh-sddm
   omarchy-branding-screensaver reset
   omarchy-branding-about reset
   ```

   Kept across upgrades by `NoUpgrade` in `default/pacman/pacman.conf` plus the
   `post-update.d/restore-branding` hook installed in step 5.

7. **Machine-specific leftovers**, which nothing in the repo can do for you:

   - `~/.config/hypr/monitors.lua` — per-machine, deliberately not in the repo.
     Restore from a backup or re-tune.
   - `~/.config/keepmenu/config.ini` — set `database_1`; refreshing that file in
     step 5 clobbers it, since the repo copy has to stay generic.

### Upgrading an existing pre-4.0 machine

Use the one-shot upgrader instead of steps 1–2. It shipped in 3.8.5, which this
fork never had, so fetch it from upstream:

```bash
curl -fsSL https://raw.githubusercontent.com/basecamp/omarchy/master/bin/omarchy-upgrade-to-quattro -o /tmp/upg
less /tmp/upg && bash /tmp/upg
```

It detects the channel from `/etc/pacman.d/mirrorlist`. Back up
`~/.config/hypr/monitors.lua` first — the upgrader force-replaces every
`hypr/*.lua` with the stock default (it does keep a `.bak`). Then continue from
step 3.

### Staying current

The fork sits on the **release** line, not `quattro` (which is upstream's
development branch). Rebase onto the next tag when it lands:

```bash
git fetch upstream --tags
git rebase --onto v4.0.2 v4.0.1 quattro
git log --oneline v4.0.2..HEAD    # must show only local commits
```

That last check matters: rebasing from one line onto another silently drags along
any upstream commits that were in the old base but absent from the new one.

## License

Omarchy is released under the [MIT License](https://opensource.org/licenses/MIT).
