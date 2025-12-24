-- Shortcut to show or hide all camera windows.

local constants = require('constants')
local CameraWindow = require('script.camera_window')

local shortcut = {}

---@param event EventData.on_lua_shortcut | EventData.CustomInputEvent
function shortcut.on_activate(event)
  local player = game.get_player(event.player_index)
  if not player then return end

  shortcut.set_toggled(player, not shortcut.get_toggled(player))
end

---@param player LuaPlayer
---@param toggled boolean
function shortcut.set_toggled(player, toggled)
  player.set_shortcut_toggled(constants.shortcut_toggle_display_name, toggled)

  if toggled then
    -- Create a camera window if none exists
    if not next(storage.players[player.index].camera_windows) then
      CameraWindow:create(player)
    end
  else
    CameraWindow:end_editing(player)
  end
  CameraWindow:update_visibility(player)
end

---@param player LuaPlayer
---@return boolean
function shortcut.get_toggled(player)
  return player.is_shortcut_toggled(constants.shortcut_toggle_display_name)
end

return shortcut
