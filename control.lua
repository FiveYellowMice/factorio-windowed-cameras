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
  header_flow.add{
    type = "label",
    style = constants.style_prefix.."camera_window_title",
    caption = {"windowed-cameras.window-title", window_ordinal},
    ignored_by_interaction = true,
  }
  header_flow.add{
    type = "empty-widget",
    style = constants.style_prefix.."camera_window_dragger",
    ignored_by_interaction = true,
  }
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
    name = constants.cemera_view_name,
    style = constants.style_prefix.."camera_window_camera_view",
    position = player.position,
    surface_index = player.surface_index,
    zoom = player.zoom,
  }
end


-- Handle shortcut button press
script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name ~= constants.shortcut_create_window_name then return end

  local player = game.get_player(event.player_index)
  if not player then return end
  create_camera_window(player)
end)

-- Handle button click
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

-- Handle remote view movement & zoom
---@param event EventData.on_player_changed_position | EventData.CustomInputEvent
local function player_move_zoom_handler(event)
  local player = game.get_player(event.player_index)
  if not player then return end

  -- Ensure we are in remote view
  if player.controller_type ~= defines.controllers.remote then return end

  -- Find the camera window that is selected for editing
  -- Temporarily it just finds the first window
  ---@type LuaGuiElement?
  local camera_window = nil
  for _, gui_element in ipairs(player.gui.screen.children) do
    if util.string_starts_with(gui_element.name, constants.camera_window_name_prefix) then
      camera_window = gui_element
      break
    end
  end
  if not camera_window then return end

  local camera_view = camera_window.children[2][constants.cemera_view_name]

  camera_view.position = player.position
  camera_view.zoom = player.zoom
end
script.on_event(defines.events.on_player_changed_position, player_move_zoom_handler)
script.on_event(constants.input_zoom_in, player_move_zoom_handler)
script.on_event(constants.input_zoom_out, player_move_zoom_handler)

-- Handle display changes
script.on_event(defines.events.on_player_display_scale_changed, function(event)
  game.print("on_player_display_scale_changed")
end)
script.on_event(defines.events.on_player_display_resolution_changed, function(event)
  game.print("on_player_display_resolution_changed")
end)