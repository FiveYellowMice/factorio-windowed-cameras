-- Data type stored in `storage.players`, a map of player_index => PlayerData

---@class PlayerData
---@field is_editing_camera boolean Whether the player is editing a camera. This is just for quickly exiting in event handlers, the canonical way to check is `CameraWindow:get_editing()`.
local prototype = {}

local PlayerData = {
  __index = prototype,
}

---@return PlayerData
function PlayerData:new()
  return setmetatable({
    is_editing_camera = false,
  }, self)
end

PlayerData.map_metatable = {
  __index = function()
    -- Return a default value for a non-existing player index
    return PlayerData:new()
  end
}

function PlayerData:on_init()
  ---@type table<integer, PlayerData>
  storage.players = setmetatable({}, self.map_metatable)
end

---@param event EventData.on_player_created
function PlayerData:on_player_created(event)
  storage.players[event.player_index] = self:new()
end

---@param event EventData.on_player_removed
function PlayerData:on_player_removed(event)
  storage.players[event.player_index] = nil
end

return PlayerData