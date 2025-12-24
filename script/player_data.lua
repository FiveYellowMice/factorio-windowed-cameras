---@module 'script.camera_window'

local PlayerData = {}

---Information associated with a player. Resides in storage.
---@class PlayerData
---@field camera_windows table<uint, CameraWindow?>
---@field editing_camera_window uint? Ordinal of the currently editing window.
---@field is_editing_camera boolean Whether the player is editing a camera. This is just for quickly exiting in event handlers, the canonical way to check is `CameraWindow:get_editing()`.
PlayerData.prototype = {}
PlayerData.prototype.__index = PlayerData.prototype


---@package
---@return PlayerData
function PlayerData.new()
  return setmetatable({
    is_editing_camera = false,
    camera_windows = {},
  }--[[@as PlayerData]], PlayerData.prototype)
end

PlayerData.map_metatable = {
  __index = function(self, key)
    -- Create a new value for a non-existing player index
    local instance = PlayerData.new()
    self[key] = instance
    return instance
  end
}

function PlayerData.on_init()
  ---@type table<integer, PlayerData>
  storage.players = setmetatable({}, PlayerData.map_metatable)
end

---@param event ConfigurationChangedData
function PlayerData.on_configuration_changed(event)
  -- Remove dangling PlayerData had any been accidentally created
  for player_index, _ in pairs(storage.players) do
    if not game.get_player(player_index) then
      storage.players[player_index] = nil
    end
  end
end

---@param event EventData.on_player_removed
function PlayerData.on_player_removed(event)
  for _, window in pairs(storage.players[event.player_index].camera_windows) do
    window:destroy()
  end
  storage.players[event.player_index] = nil
end

return PlayerData
