Name = "brightness"
NamePretty = "Brightness"
HideFromProviderlist = true
FixedOrder = true
Cache = true
Action = "brightnessctl set %VALUE%%; notify-send 'Brightness' 'Set to %VALUE%%'"

function GetEntries()
	local entries = {}
	for i = 5, 100, 5 do
		table.insert(entries, {
			Text = i .. "%",
			Value = tostring(i),
		})
	end
	return entries
end
