# Omarchy

Omarchy is a beautiful, fun & agentic Linux distribution by DHH.

Read more at [omarchy.org](https://omarchy.org).

## The Omarchy Manual

The manual lives in [`manual/`](manual/), which is its authoritative source.

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
2. **Clone this fork** on the branch for the current release, `quattro-v4.5.0`.
   Name it: the remote's default branch is `master`, and `quattro` is the old
   4.0.6 line, so a plain clone gets neither:

   ```bash
   git clone -b quattro-v4.5.0 git@github.com:antonovch/omarchy ~/Projects/omarchy
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
            hypr/workspaces.lua keepmenu/config.ini btop/btop.conf \
            udiskie/config.yml Code/User/keybindings.json \
            omarchy/extensions/omarchy-menu.jsonc \
            omarchy/hooks/post-update.d/restore-branding; do
     omarchy-refresh-config "$f"
   done
   ```

   `hypr/workspaces.lua` is required by `hypr/hyprland.lua`. Without it the
   Hyprland config stops loading at that line, and everything after it
   (`looknfeel.lua`, autostart, the toggles) silently never applies, with
   nothing in `hyprctl configerrors`.

   Check what still differs at any time with:

   ```bash
   for f in $(git diff v4.5.0 --name-only -- config/ | sed 's|^config/||'); do
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

   Kept across upgrades by `NoUpgrade` in `default/pacman/pacman-*.conf` (one per channel) plus the
   `post-update.d/restore-branding` hook installed in step 5.

7. **Machine-specific leftovers**, which nothing in the repo can do for you:

   - `~/.config/hypr/monitors.lua` — per-machine, deliberately not in the repo.
     Restore from a backup or re-tune.
   - `~/.config/keepmenu/config.ini` — set `database_1`; refreshing that file in
     step 5 clobbers it, since the repo copy has to stay generic.

### Workspaces

Omarchy 4.5 gives every monitor workspaces 1-10 of its own and folds an unplugged
monitor's workspaces into the laptop's block, which reorders apps when you dock
and undock. This fork keeps the pre-4.5 global numbering instead:
`config/hypr/workspaces.lua` stops the per-monitor logic and rebinds the number
keys, `Super + Tab` and `Super + Shift + Alt + Arrow` to plain workspaces. Set
`global_workspaces = false` at the top of `~/.config/hypr/workspaces.lua` for the
4.5 behavior.

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

### Updating

`omarchy update` still does everything, exactly as before the 4.0 split:

```
omarchy-update-dev          git pull --ff-only on this checkout
omarchy-update-keyring
omarchy-update-system-pkgs  pacman -Syu
omarchy-migrate             migrations
omarchy-hook post-update    restore-branding, etc.
omarchy-update-aur-pkgs / -mise / -orphan-pkgs
```

The checkout is pulled *first*, so an `omarchy update` on the second machine picks
up whatever was pushed from the first. Nothing else is needed day to day.

### Moving onto a new upstream release

Separate and occasional. Do it on one machine, push, and let the other machine
take it through its next `omarchy update`.

The fork sits on upstream's **release** line (the `vX.Y.Z` tags), *not* on
`upstream/quattro`, which is upstream's development branch. The branch is named for
the release it carries (`quattro-v4.5.0`).

**A patch release in the same line (4.5.0 to 4.5.1)**: merge the tag. It descends
from the one already merged, so the merge is small, and nothing is rewritten:

```bash
git fetch upstream --tags
git merge v4.5.1 --no-edit
./test/cli
git push
```

**A jump across lines (4.0 to 4.5)**: a merge conflicts across hundreds of files.
Replay the fork's own commits onto the new tag instead, in a separate worktree so
the checkout `$OMARCHY_PATH` points at stays usable:

```bash
git fetch upstream --tags
git worktree add ../omarchy-next -b quattro-vX.Y.Z
cd ../omarchy-next
git rev-list --no-merges --topo-order --reverse quattro-v4.5.0 \
  --not --remotes=upstream --tags='v*' > /tmp/own-commits
git reset --hard vX.Y.Z
git cherry-pick $(cat /tmp/own-commits)   # resolve each conflict, then --continue
```

The rev-list is the fork's own commits: those reachable from no upstream ref or
tag. A plain `git rebase` would also carry along the upstream release-branch
commits that earlier tag merges brought in. When a conflict comes up:

- Personal config (`config/hypr/*.lua`): the fork's version wins.
- Shared code: take upstream's, then re-apply only what the fork adds.
- A commit that can't be ported cheaply: leave it out and note it.
- A feature spread over many commits (Firefox): squash it into one commit, so the
  next sync conflicts once and not once per step.

Then check, in this order:

```bash
git log --oneline vX.Y.Z..HEAD   # must show ONLY local commits
./test/cli
./test/shell
```

Run the failing shell tests once on a pristine `vX.Y.Z` worktree: whatever fails
there too is the host, not the port.

Push it as a **new branch**, not over the old one:

```bash
git push -u origin quattro-vX.Y.Z
```

On each machine, switch the checkout and update:

```bash
git -C ~/Projects/omarchy fetch origin
git -C ~/Projects/omarchy checkout quattro-vX.Y.Z
omarchy update
```

A new branch means no force-push, the old branch stays as a way back, and
`omarchy-update-dev`'s `git pull --ff-only` keeps working, because the new branch
tracks its own remote. Overwriting a published branch breaks that pull on every
other machine (`fatal: Not possible to fast-forward`), and since `omarchy update`
runs under `set -e` it aborts the **whole** update before keyring, packages and
migrations.

### Do not let the fork lag a release

`omarchy-migrate` reads `$OMARCHY_PATH/migrations`, and under `omarchy-dev-link`
that is this checkout, not the package. The same goes for `bin/`, `shell/` and
`themes/`.

So when 4.5.1 lands, `omarchy update` upgrades the *packages* to 4.5.1 while this
checkout keeps serving 4.5.0 code, including 4.5.0's migration set: 4.5.1's new
migrations never run. Move the fork onto each release promptly rather than
deferring it.

## License

Omarchy is released under the [MIT License](https://opensource.org/licenses/MIT).
