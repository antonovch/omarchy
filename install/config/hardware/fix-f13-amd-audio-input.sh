AMD_AUDIO_CARD=$(pactl list cards 2>/dev/null | grep -B20 "Family 17h/19h" | grep "Name: " | awk '{print $2}' || true)

if [[ -n $AMD_AUDIO_CARD ]]; then
  pactl set-card-profile "$AMD_AUDIO_CARD" "HiFi (Mic1, Mic2, Speaker)" 2>/dev/null || true
fi

# Fix DELL laptop audio
INTEL_AUDIO_CARD=$(pactl list cards | grep -B20 "alsa_card.pci-0000_00_1f.3" | grep "Name: " | awk '{print $2}')

if [[ -n $INTEL_AUDIO_CARD ]]; then
  pactl set-card-profile "$INTEL_AUDIO_CARD" output:analog-stereo+input:analog-stereo 2>/dev/null || true
fi
