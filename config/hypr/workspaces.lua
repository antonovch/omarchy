-- Global workspace numbering, as before Omarchy 4.5: workspace N is the same
-- workspace whichever monitor shows it, so unplugging a monitor renumbers
-- nothing and your apps keep their order on the laptop.
--
-- Omarchy 4.5 instead gives every monitor workspaces 1-10 of its own and folds
-- an unplugged monitor's workspaces into the remaining one's block. That suits
-- several screens in use at once; flip this to false for it.
local global_workspaces = true

if not global_workspaces then
  return
end

-- Stop the per-monitor block logic. Its event hooks (start, reload, monitor
-- added and removed) call this through the module table, so replacing it here
-- reaches them all.
o.workspaces.reconcile = function() end

local function action(expression, fn)
  o.bind_expressions[fn] = expression
  return fn
end

-- The bar widget and `omarchy-hyprland-window-close-all` call these with a slot
-- (and a monitor name) in per-monitor terms. Here a slot is just the workspace.
function o.workspaces.focus(workspace)
  return action("o.workspaces.focus(" .. string.format("%q", tostring(workspace)) .. ")", function()
    hl.dispatch(hl.dsp.focus({ workspace = tostring(workspace) }))
  end)
end

function o.workspaces.move_window(workspace, follow)
  return action("o.workspaces.move_window(" .. workspace .. ", " .. tostring(follow ~= false) .. ")", function()
    hl.dispatch(hl.dsp.window.move({ workspace = tostring(workspace), follow = follow ~= false }))
  end)
end

function o.workspaces.move_to_monitor(direction)
  return action("o.workspaces.move_to_monitor(" .. string.format("%q", direction) .. ")", function()
    hl.dispatch(hl.dsp.workspace.move({ monitor = direction }))
  end)
end

for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  o.rebind("SUPER + " .. key, "Switch to workspace " .. workspace, o.workspaces.focus(workspace))
  o.rebind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, o.workspaces.move_window(workspace))
  o.rebind("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace " .. workspace, o.workspaces.move_window(workspace, false))
end

o.rebind("SUPER + TAB", "Next workspace", o.workspaces.focus("e+1"))
o.rebind("SUPER + SHIFT + TAB", "Previous workspace", o.workspaces.focus("e-1"))
o.rebind("SUPER + CTRL + TAB", "Former workspace", o.workspaces.focus("previous"))
o.rebind("SUPER + mouse_down", "Scroll active workspace forward", o.workspaces.focus("e+1"))
o.rebind("SUPER + mouse_up", "Scroll active workspace backward", o.workspaces.focus("e-1"))

for key, direction in pairs({ LEFT = "l", RIGHT = "r", UP = "u", DOWN = "d" }) do
  o.rebind("SUPER + SHIFT + ALT + " .. key, "Move workspace to " .. key:lower() .. " monitor", o.workspaces.move_to_monitor(direction))
end
