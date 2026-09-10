# Neovim Configuration

This directory contains Omarchy's default nvim configuration.

## Setup

To enable Ukrainian spellchecking, install the required dictionary:

```bash
omarchy-pkg-add aspell-uk
```

## Configuration

The spellcheck configuration is in `lua/config/spellcheck.lua` and enables:
- English (en) and Ukrainian (uk) spell checking
- Spell checking is enabled by default

To use this configuration, symlink or copy the `init.lua` to your nvim config directory, or source it from your existing configuration.
