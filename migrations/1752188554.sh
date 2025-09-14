echo "Update firefox.desktop to ensure we are always using wayland"
if [[ ! -f ~/.local/share/applications/firefox.desktop ]]; then
  cp ~/.local/share/omarchy/applications/firefox.desktop ~/.local/share/applications/
  xdg-settings set default-web-browser firefox.desktop
  xdg-mime default firefox.desktop x-scheme-handler/http
  xdg-mime default firefox.desktop x-scheme-handler/https
fi
