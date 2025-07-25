-- script.on_event(defines.events.on_player_created, function(event)
--   local player = game.get_player(event.player_index)
--   if not player then return end

--   local screen_element = player.gui.screen
--   local main_frame = screen_element.add{type="frame", name="windowed-cameras-camera-1", caption={"windowed-cameras.window-title", 1}}
--   main_frame.style.size = {385, 165}
-- end)

local constants = require("__windowed-cameras__/lib/constants.lua")
require("__windowed-cameras__/lib/utils.lua")


--- @param player LuaPlayer
local function create_camera_window(player)
  -- Find the largest ordinal of existing windows, the new window will have an ordinal of that + 1
  n_window = 0
  for _, gui_element in ipairs(player.gui.screen.children) do
    if string.starts(gui_element.name, constants.camera_window_name_prefix) then
      n_window = math.max(n_window, tonumber(gui_element.tags.ordinal) or 0)
    end
  end

  local window = player.gui.screen.add{
    type = "frame",
    name = constants.camera_window_name_prefix .. n_window + 1,
    caption = {"windowed-cameras.window-title", n_window + 1},
    tags = {ordinal = n_window + 1},
  }
  window.style.size = {400, 400}
end


script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name ~= constants.shortcut_create_window_name then return end

  local player = game.get_player(event.player_index)
  if not player then return end
  create_camera_window(player)
end)
