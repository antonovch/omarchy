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

  mkdir -p /etc/limine-entry-tool.d
  cat <<EOF >/etc/limine-entry-tool.d/apple-macbook-suspend.conf
# Suspend fix for Intel MacBooks (Omarchy)
KERNEL_CMDLINE[default]+=" mem_sleep_default=s2idle pcie_ports=compat i915.enable_psr=0 i915.enable_fbc=0"
EOF

  mkdir -p /etc/systemd/sleep.conf.d
  cat <<EOF >/etc/systemd/sleep.conf.d/apple-macbook-suspend.conf
[Sleep]
SuspendState=freeze
EOF

  # Broadcom Wi-Fi (brcmfmac) doesn't reliably survive the sleep transition
  # on these machines - unload it before suspend and reload it on resume.
  if lspci -k | grep -q "brcmfmac"; then
    cat <<EOF >/etc/systemd/system/omarchy-macbook-suspend-wifi.service
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

    systemctl daemon-reload
    systemctl enable omarchy-macbook-suspend-wifi.service
  fi

  # Some Intel MacBooks' Thunderbolt controller fails to return from D3cold
  # on resume, wedging the xHCI controller behind it dead. Unbind both
  # before sleep and rebind after, forcing a clean re-enumeration.
  if [[ -d /sys/bus/pci/drivers/thunderbolt ]]; then
    # install -m 0755 rather than cp -p: systemd-sleep only runs hooks that are
    # executable, and the repo copy's mode should not decide that.
    install -D -m 0755 "$OMARCHY_PATH/default/systemd/system-sleep/tb-xhci-unbind" \
      /usr/lib/systemd/system-sleep/tb-xhci-unbind
  fi
fi
