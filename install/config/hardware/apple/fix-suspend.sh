# Fix suspend/resume hangs on Intel MacBooks (non-T2)
# See: https://github.com/basecamp/omarchy/discussions/4695
#
# Deep (S3) suspend is unreliable on this hardware - the machine can hang
# entering sleep or come back unresponsive on resume. Forcing s2idle, disabling
# i915 panel self-refresh/framebuffer compression (known to hang MacBook Intel
# graphics on resume), and cycling the Wi-Fi driver around the sleep
# transition gives a clean suspend/resume cycle.

if omarchy-hw-intel-macbook; then
  echo "Configuring suspend fixes for Intel MacBook..."

  sudo mkdir -p /etc/limine-entry-tool.d
  cat <<EOF | sudo tee /etc/limine-entry-tool.d/apple-macbook-suspend.conf >/dev/null
# Suspend fix for Intel MacBooks (Omarchy)
KERNEL_CMDLINE[default]+=" mem_sleep_default=s2idle pcie_ports=compat i915.enable_psr=0 i915.enable_fbc=0"
EOF

  sudo mkdir -p /etc/systemd/sleep.conf.d
  cat <<EOF | sudo tee /etc/systemd/sleep.conf.d/apple-macbook-suspend.conf >/dev/null
[Sleep]
SuspendState=freeze
EOF

  # Broadcom Wi-Fi (brcmfmac) doesn't reliably survive the sleep transition
  # on these machines - unload it before suspend and reload it on resume.
  if lspci -k | grep -q "brcmfmac"; then
    cat <<EOF | sudo tee /etc/systemd/system/omarchy-macbook-suspend-wifi.service >/dev/null
[Unit]
Description=Unload Broadcom Wi-Fi driver around suspend (Omarchy MacBook fix)
Before=sleep.target
StopWhenUnneeded=yes

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'rmmod brcmfmac_wcc 2>/dev/null; rmmod brcmfmac 2>/dev/null'
ExecStop=/usr/bin/modprobe brcmfmac

[Install]
WantedBy=sleep.target
EOF

    sudo systemctl daemon-reload
    chrootable_systemctl_enable omarchy-macbook-suspend-wifi.service
  fi
fi
