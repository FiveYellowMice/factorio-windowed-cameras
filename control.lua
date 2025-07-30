local constants = require("lib/constants.lua")
local util = require("util")
local CameraWindow = require("lib.camera_window")


---@class PlayerData
---@field is_editing_camera boolean Whether the player is editing a camera.

script.on_init(function()
  ---@type PlayerData[]
  storage.players = {}
end)

script.on_event(defines.events.on_player_created, function(event)
  storage.players[event.player_index] = {
    is_editing_camera = false,
  }
end)

script.on_event(defines.events.on_player_removed, function(event)
  if not storage.players then
    storage.players = {}
  end
  storage.players[event.player_index] = nil
end)


-- Handle shortcut button press
---@param event EventData.on_lua_shortcut | EventData.CustomInputEvent
function shortcut_handler(event)
  local player = game.get_player(event.player_index)
  if not player then return end

  if not player.is_shortcut_toggled(constants.shortcut_toggle_display_name) then
    -- Show all windows, or create one of none exists
    local n = CameraWindow:set_all_visible(player, true)
    if n == 0 then
      CameraWindow:create(player)
    end
    player.set_shortcut_toggled(constants.shortcut_toggle_display_name, true)
  else
    -- Hide all windows
    CameraWindow:set_all_visible(player, false)
    player.set_shortcut_toggled(constants.shortcut_toggle_display_name, false)
  end
end
script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name ~= constants.shortcut_toggle_display_name then return end
  shortcut_handler(event)
end)
script.on_event(constants.input_toggle_display, shortcut_handler)

-- Handle button clicks
script.on_event(defines.events.on_gui_click, function(event)
  if not util.string_starts_with(event.element.name, constants.gui_name_prefix) then return end

  local camera_window = CameraWindow:from(event.element)
  if not camera_window then return end

  -- Call the method given by name in the on_click tag of the element
  local on_click_method_name = event.element.tags.on_click
  if on_click_method_name and on_click_method_name ~= "" then
    camera_window[on_click_method_name](camera_window)
  end
end)

-- Handle remote view movement & zoom
---@param event EventData.on_player_changed_position | EventData.on_player_changed_surface | EventData.CustomInputEvent
local function player_move_zoom_handler(event)
  -- Only relavant when the player is editing a camera
  if not storage.players[event.player_index].is_editing_camera then return end

  local player = game.get_player(event.player_index)
  if not player then return end

  -- Ensure we are in remote view
  if player.controller_type ~= defines.controllers.remote then return end

  local camera_window = CameraWindow:get_editing(player)
  if not camera_window then
    storage.players[player.index].is_editing_camera = false
    return
  end

  camera_window:set_view_from_player(player)
end
script.on_event(defines.events.on_player_changed_position, player_move_zoom_handler)
script.on_event(defines.events.on_player_changed_surface, player_move_zoom_handler)
script.on_event(constants.input_zoom_in, player_move_zoom_handler)
script.on_event(constants.input_zoom_out, player_move_zoom_handler)

-- Handle player exiting remote view
script.on_event(defines.events.on_player_controller_changed, function(event)
  -- Only relavant when the player is editing a camera
  if not storage.players[event.player_index].is_editing_camera then return end

  local player = game.get_player(event.player_index)
  if not player then return end

  -- Exiting remote view
  if event.old_type ~= defines.controllers.remote then return end

  local camera_window = CameraWindow:get_editing(player)
  if not camera_window then
    storage.players[player.index].is_editing_camera = false
    return
  end

  camera_window:end_editing()
end)