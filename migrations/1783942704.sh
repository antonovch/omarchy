echo "Rename webapp desktop files to normalized (lowercase-hyphenated) names"

APPS_DIR="$HOME/.local/share/applications"

for pair in "ChatGPT:chatgpt" "Claude:claude" "Grok:grok" "GitHub:github" "YouTube:youtube" "WhatsApp:whatsapp"; do
  old="${pair%%:*}"
  new="${pair##*:}"
  if [[ -f "$APPS_DIR/$old.desktop" && ! -f "$APPS_DIR/$new.desktop" ]]; then
    mv "$APPS_DIR/$old.desktop" "$APPS_DIR/$new.desktop"
  fi
done

# Fix typo: google-calender → google-calendar
if [[ -f "$APPS_DIR/google-calender.desktop" && ! -f "$APPS_DIR/google-calendar.desktop" ]]; then
  mv "$APPS_DIR/google-calender.desktop" "$APPS_DIR/google-calendar.desktop"
  sed -i 's/^Name=Google Calender$/Name=Google Calendar/' "$APPS_DIR/google-calendar.desktop"
fi
