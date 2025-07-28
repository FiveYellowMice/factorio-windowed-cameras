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
    zoom = constants.zoom_exp_base ^ constants.zoom_init_power - 1,
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

-- Handle zoom input
---@param event EventData.CustomInputEvent
local function zoom_input_handler(event)
  -- This function is called whenever the built-in zoom in or out control is pressed (by default
  -- is mouse scroll), anywhere in the game screen. We can check whether this happens while the
  -- mouse is inside our camera view, but we can' conditionally block the game from zooming its
  -- main view. So unfortunately, the UX will have to be that both the main view and camera view
  -- zoom when the user scrolls their mouse in a camera view.
  if not event.element or event.element.name ~= constants.cemera_view_name then return end

  ---@type LuaGuiElement
  local camera_view = event.element
  -- Make the camera view zoom in or out, in exponential scale
  local zoom_power = math.log(camera_view.zoom + 1, constants.zoom_exp_base)
  if event.input_name == constants.input_zoom_in then
    zoom_power = zoom_power + 1
  else
    zoom_power = zoom_power - 1
  end
  local new_zoom_level = constants.zoom_exp_base ^ zoom_power - 1
  -- Clamp the zoom level between (0, 4)
  if new_zoom_level > 0 and new_zoom_level < 4 then
    camera_view.zoom = new_zoom_level
  end
end

script.on_event(constants.input_zoom_in, zoom_input_handler)
script.on_event(constants.input_zoom_out, zoom_input_handler)