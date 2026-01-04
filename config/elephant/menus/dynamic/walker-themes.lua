Name = "walker_themes"
NamePretty = "Walker Themes"
HideFromProviderlist = true
FixedOrder = true
Cache = false
Action = "bash -c 'sed -i \"s/theme = \\\".*\\\"/theme = \\\"%VALUE%\\\"/\" ~/.config/walker/config.toml && pkill -f \"walker --gapplication-service\" && sleep 0.5 && setsid uwsm-app -- walker --gapplication-service & notify-send \"Walker Theme\" \"Changed to %VALUE%\"'"

function GetEntries()
	local entries = {}
	local config_dir = os.getenv("HOME") .. "/.local/share/omarchy/default/walker/themes/"
	
	-- Read directories from the themes folder
	local handle = io.popen("ls -1 '" .. config_dir .. "' 2>/dev/null")
	if handle then
		for theme in handle:lines() do
			-- Check if it's a directory
			local stat = io.popen("test -d '" .. config_dir .. theme .. "' && echo 'dir'"):read("*a")
			if stat:match("dir") then
				table.insert(entries, {
					Text = theme,
					Value = theme,
				})
			end
		end
		handle:close()
	end
	
	-- Sort alphabetically
	table.sort(entries, function(a, b) return a.Text < b.Text end)
	
	return entries
end
