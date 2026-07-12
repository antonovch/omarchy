echo "Fix suspend/resume hangs and add fan control on Intel MacBooks"

if omarchy-hw-intel-macbook; then
  source "$OMARCHY_PATH/install/config/hardware/apple/fix-suspend.sh"
  source "$OMARCHY_PATH/install/config/hardware/apple/fix-fan.sh"

  if omarchy-cmd-present limine-update; then
    sudo limine-update
  fi
fi
