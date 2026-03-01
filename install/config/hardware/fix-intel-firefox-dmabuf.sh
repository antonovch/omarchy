# Fix Firefox crashing on Hyprland config reloads when using Intel GPU
# DMA-BUF shared surface transport is unstable on Intel iGPUs under Wayland,
# causing crashes when the compositor reapplies settings or reloads config.

if lspci | grep -iE 'vga|3d|display' | grep -qi 'intel'; then
  if ! grep -q "MOZ_DMA_BUF" ~/.config/hypr/envs.conf 2>/dev/null; then
    echo "Disabling Firefox DMA-BUF on Intel GPU for stability..."
    cat >>~/.config/hypr/envs.conf <<'EOF'

# Fix Firefox crash on Hyprland reload (Intel GPU DMA-BUF instability)
env = MOZ_DMA_BUF,0
EOF
  fi
fi
