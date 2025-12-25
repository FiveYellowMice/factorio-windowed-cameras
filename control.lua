local constants = require("constants")
local migrations = require("script.migrations")
local shortcut = require('script.shortcut')
local PlayerData = require('script.player_data')
local CameraWindow = require("script.camera_window")
local CameraWindowMenu = require('script.camera_window_menu')
require('script.remote')


script.register_metatable("PlayerData_map_metatable", PlayerData.map_metatable)
script.register_metatable("PlayerData", PlayerData.prototype)
script.register_metatable("CameraWindow", CameraWindow.prototype)
script.register_metatable("CameraWindowMenu", CameraWindowMenu.prototype)

CameraWindow.load_deps()
CameraWindowMenu.load_deps()

script.on_init(function()
  PlayerData.on_init()
end)

script.on_event(defines.events.on_player_removed, function(event)
  PlayerData.on_player_removed(event)
end)

script.on_configuration_changed(function(event)
  migrations.on_configuration_changed(event)
  PlayerData.on_configuration_changed(event)
end)


-- Handle shortcut button press
script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name ~= constants.shortcut_toggle_display_name then return end
  shortcut.on_activate(event)
end)
script.on_event(constants.input_toggle_display, shortcut.on_activate)

-- Handle GUI interactions
local event_handler_tag_map = {
  [defines.events.on_gui_click] = "on_click",
  [defines.events.on_gui_value_changed] = "on_value_changed",
  [defines.events.on_gui_text_changed] = "on_text_changed",
  [defines.events.on_gui_location_changed] = "on_location_changed",
}
---@param event
---| EventData.on_gui_click
---| EventData.on_gui_value_changed
---| EventData.on_gui_text_changed
---| EventData.on_gui_location_changed
local function gui_interaction_handler(event)
  if not event.element.tags[constants.gui_tag_event_enabled] then return end

  local object = CameraWindow:from_element(event.element) or CameraWindowMenu:from_element(event.element)
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
script.on_event(defines.events.on_gui_location_changed, gui_interaction_handler)

-- Handle remote view movement & zoom
---@param event EventData.on_player_changed_position | EventData.on_player_changed_surface | EventData.CustomInputEvent
local function player_move_zoom_handler(event)
  -- Only relavant when the player is editing a camera
  local camera_window = CameraWindow:get_editing(event.player_index)
  if not camera_window then return end

  local player = game.get_player(event.player_index)
  if not player then return end

  -- Ensure we are in remote view
  if player.controller_type ~= defines.controllers.remote then return end

  camera_window:set_view_from_player(player)
end
script.on_event(defines.events.on_player_changed_position, player_move_zoom_handler)
script.on_event(defines.events.on_player_changed_surface, player_move_zoom_handler)

---@param event EventData.CustomInputEvent
local function zoom_input_handler(event)
  -- Only relavant when the player is editing a camera
  if CameraWindow:is_editing(event.player_index) then return end

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
  local camera_window = CameraWindow:get_editing(event.player_index)
  if not camera_window then return end

  -- Exiting remote view
  if event.old_type ~= defines.controllers.remote then return end

  camera_window:end_editing()
end)

-- Handle player selecting entity to track
---@param event EventData.CustomInputEvent
script.on_event(constants.input_select_entity, function(event)
  local player = game.get_player(event.player_index)
  if not player then return end

  local cursor_stack = player.cursor_stack
  if
    not cursor_stack or
    not cursor_stack.valid_for_read or
    cursor_stack.name ~= constants.track_entity_selector_name
  then
    return
  end

  -- A selection tool is intended for selecting an area which may contain multiple entities, but
  -- we only want one, so we don't actually use its area selection functionality. Instead, we
  -- are only interested in the singular entity under the cursor when the selection begins.
  -- So we capture the input event before the selection begins, and cancel the selection
  -- immediately so that the selection box never shows.
  local entity = player.selected
  player.clear_selection()

  local window = CameraWindow:get(player, tonumber(cursor_stack.label)--[[@as integer]])
  if not window then return end

  local ret = window:select_tracked_entity(entity)

  if ret then
    cursor_stack.clear()
  end
end)

-- Handle display resolution and scale change
---@param event EventData.on_player_display_resolution_changed | EventData.on_player_display_scale_changed
local function display_resolution_scale_change_handler(event)
  CameraWindowMenu:on_display_resolution_scale_changed(event)
end
script.on_event(defines.events.on_player_display_resolution_changed, display_resolution_scale_change_handler)
script.on_event(defines.events.on_player_display_scale_changed, display_resolution_scale_change_handler)
