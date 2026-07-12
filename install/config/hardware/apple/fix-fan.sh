# Install fan control for Intel MacBooks (non-T2)
# T2 MacBooks get t2fanrd via fix-t2.sh; Intel (non-T2) MacBooks need mbpfan
# instead, since t2fanrd drives its curve through the T2 SMC path.

if omarchy-hw-intel-macbook; then
  echo "Installing fan control for Intel MacBook..."

  omarchy-pkg-add mbpfan

  cat <<EOF | sudo tee /etc/mbpfan.conf >/dev/null
[general]
min_fan1_speed = 1200
max_fan1_speed = 7200
low_temp = 63
high_temp = 75
max_temp = 90
polling_interval = 3
EOF

  sudo systemctl enable mbpfan.service
fi
