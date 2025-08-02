local constants = require("lib/constants.lua")
local util = require("util")
local PlayerData = require('lib/player_data.lua')
local CameraWindow = require("lib/camera_window.lua")
local CameraWindowMenu = require('lib/camera_window_menu.lua')


local PlayerData_map_metatable = PlayerData.map_metatable
script.register_metatable("PlayerData_map_metatable", PlayerData_map_metatable)
script.register_metatable("PlayerData", PlayerData)

script.on_init(function()
  PlayerData:on_init()
end)

script.on_event(defines.events.on_player_created, function(event)
  PlayerData:on_player_created(event)
end)

script.on_event(defines.events.on_player_removed, function(event)
  PlayerData:on_player_removed(event)
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

-- Handle window closing
---@param event CameraWindowClosedData
script.on_event(CameraWindow.event_window_closed, function(event)
  local player = game.get_player(event.player_index)
  if not player then return end

  -- Treat the shortcut as toggled off when there are no more windows remaining
  if not event.remaining then
    player.set_shortcut_toggled(constants.shortcut_toggle_display_name, false)
  end
end)

-- Handle GUI interactions
local event_handler_tag_map = {
  [defines.events.on_gui_click] = "on_click",
  [defines.events.on_gui_value_changed] = "on_value_changed",
  [defines.events.on_gui_text_changed] = "on_text_changed",
}
---@param event
---| EventData.on_gui_click
---| EventData.on_gui_value_changed
---| EventData.on_gui_text_changed
local function gui_interaction_handler(event)
  if not event.element.tags[constants.gui_tag_event_enabled] then return end

  local object = CameraWindow:from(event.element) or CameraWindowMenu:from(event.element)
  if not object then return end

  -- Call the method given by name in the on_* tags of the element
  local tag_name = event_handler_tag_map[event.name]
  local method_name = event.element.tags[tag_name]
  if method_name and method_name ~= "" then
    object[method_name](object)
  end
end
script.on_event(defines.events.on_gui_click, gui_interaction_handler)
script.on_event(defines.events.on_gui_value_changed, gui_interaction_handler)
script.on_event(defines.events.on_gui_text_changed, gui_interaction_handler)

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

---@param event EventData.CustomInputEvent
local function zoom_input_handler(event)
  -- Only relavant when the player is editing a camera
  if not storage.players[event.player_index].is_editing_camera then return end

  -- As a workaround for the absence of an on_player_zoom event, we listen on the zoom in and out
  -- controls being pressed.
  -- But custom input handlers are invoked before the game actually processes the zooming action,
  -- so we delay our processing of the event to the next tick.
  script.on_nth_tick(1, function()
    player_move_zoom_handler(event)
    script.on_nth_tick(1, nil)
  end)
end
script.on_event(constants.input_zoom_in, zoom_input_handler)
script.on_event(constants.input_zoom_out, zoom_input_handler)

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