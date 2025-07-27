local constants = require("lib/constants.lua")
local util = require("util")


--- @param player LuaPlayer
local function create_camera_window(player)
  -- Find the largest ordinal of existing windows, the new window will have an ordinal of that + 1
  local n_window = 0
  for _, gui_element in ipairs(player.gui.screen.children) do
    if util.string_starts_with(gui_element.name, constants.camera_window_name_prefix) then
      n_window = math.max(n_window, tonumber(gui_element.tags.ordinal) or 0)
    end
  end
  local window_ordinal = n_window + 1

  local window = player.gui.screen.add{
    type = "frame",
    name = constants.camera_window_name_prefix .. window_ordinal,
    tags = {ordinal = window_ordinal},
    direction = "vertical",
  }
  window.style.size = {400, 400}

  local header_flow = window.add{
    type = "flow",
    direction = "horizontal",
    style = "frame_header_flow"
  }
  header_flow.drag_target = window
  local header_title = header_flow.add{
    type = "label",
    style = "frame_title",
    caption = {"windowed-cameras.window-title", window_ordinal},
    ignored_by_interaction = true,
  }
  header_title.style.top_margin = -3
  local header_drag = header_flow.add{
    type = "empty-widget",
    style = "draggable_space",
    ignored_by_interaction = true,
  }
  header_drag.style.horizontally_stretchable = true
  header_drag.style.right_margin = 4
  header_drag.style.height = 24
  header_flow.add{
    type = "sprite-button",
    style = "close_button",
    name = "close",
    sprite = "utility/close",
    tooltip = {"gui.close"},
    mouse_button_filter = {"left"},
  }

  local content_flow = window.add{
    type = "frame",
    style = "inside_shallow_frame"
  }
  local camera_view = content_flow.add{
    type = "camera",
    name = "camera-view",
    position = player.position,
    surface_index = player.surface_index,
  }
  camera_view.style.horizontally_stretchable = true
  camera_view.style.vertically_stretchable = true
end


script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name ~= constants.shortcut_create_window_name then return end

  local player = game.get_player(event.player_index)
  if not player then return end
  create_camera_window(player)
end)

script.on_event(defines.events.on_gui_click, function(event)
  if
    event.element.type == "sprite-button" and
    event.element.name == "close" and
    event.element.parent.parent and
    util.string_starts_with(event.element.parent.parent.name, constants.camera_window_name_prefix)
  then
    -- Close window
    event.element.parent.parent.destroy()
  end
end)