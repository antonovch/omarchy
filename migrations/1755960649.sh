echo "Update GitHub repo name in application launcher"

for file in \
  ~/.config/walker/config.toml \
  /etc/systemd/system/omarchy-seamless-login.service
do 
  if [ -f "$file" ]; then
    sed -i "s|github.com/basecamp/omarchy|github.com/${OMARCHY_REPO}|g"
  fi
done
