-- Remote interface

local CameraWindow = require("lib/camera_window.lua")

local remote_interface = {}


---@param player LuaPlayer
local function check_param_player(player)
  if not player or player.object_name ~= "LuaPlayer" or not player.valid then
    error("Expected valid LuaPlayer object for 'player' parameter")
  end
end

---@param spec CameraViewSpec
local function check_param_spec(spec)
  if not spec or type(spec) ~= "table" then
    error("Expected table for 'spec' parameter")
  end

  if spec.position and (type(spec.position) ~= "table" or 
     type(spec.position.x or spec.position[1]) ~= "number" or 
     type(spec.position.y or spec.position[2]) ~= "number") then
    error("spec.position must be a MapPosition with x and y coordinates")
  end

  if spec.surface_index and type(spec.surface_index) ~= "number" then
    error("spec.surface_index must be a number")
  end

  if spec.zoom and type(spec.zoom) ~= "number" then
    error("spec.zoom must be a number")
  end

  if spec.entity and (not spec.entity.valid or not spec.entity.position) then
    error("spec.entity must be a valid LuaEntity")
  end
end

---@param ordinal integer
local function check_param_ordinal(ordinal)
  if not ordinal or type(ordinal) ~= "number" or ordinal < 1 or math.floor(ordinal) ~= ordinal then
    error("Expected positive integer for 'ordinal' parameter")
  end
end

---@param size [integer, integer]
local function check_param_size(size)
  if type(size) ~= "table" or #size ~= 2 or
      type(size[1]) ~= "number" or type(size[2]) ~= "number" then
    error("Expected size to be a table of two numbers: [width, height]")
  end
end

---@param player LuaPlayer
---@param ordinal integer
---@return CameraWindow
local function check_and_get_window(player, ordinal)
  check_param_player(player)
  check_param_ordinal(ordinal)

  local window = CameraWindow:get(player, ordinal)
  if not window then
    error("The specified player does not have a camera window of the specified ordinal")
  end

  return window
end


---Create a new camera window.
---@param player LuaPlayer The player to create the camera window for.
---@param spec CameraViewSpec Specifies what the camera looks at.
---@param size [integer, integer]? Size of the camera window frame.
---@return integer #Ordinal of the new window.
function remote_interface.create(player, spec, size)
  check_param_player(player)
  check_param_spec(spec)
  if size then check_param_size(size) end

  local window = CameraWindow:create(player, spec, size)
  return window.window.tags.ordinal--[[@as integer]]
end

---Destroy a camera window.
---@param player LuaPlayer The player the camera window belongs to.
---@param ordinal integer The ordinal of the camera window.
function remote_interface.destroy(player, ordinal)
  local window = check_and_get_window(player, ordinal)

  window:destroy()
end

---Update the settings of a camera view, unspecified parameters are unchanged.
---@param player LuaPlayer The player the camera window belongs to.
---@param ordinal integer The ordinal of the camera window.
---@param spec CameraViewSpec Specifies what the camera looks at.
function remote_interface.update_view(player, ordinal, spec)
  local window = check_and_get_window(player, ordinal)
  check_param_spec(spec)

  window:update_view(spec)
end

---Get the camera view LuaGuiElement in a window. It's best to treat the obtained element as read-only.
---@param player LuaPlayer The player the camera window belongs to.
---@param ordinal integer The ordinal of the camera window.
---@return LuaGuiElement
function remote_interface.get_camera_element(player, ordinal)
  local window = check_and_get_window(player, ordinal)

  return window:get_camera()
end

---Get the window frame LuaGuiElement of a camera window. It's best to treat the obtained element as read-only.
---@param player LuaPlayer The player the camera window belongs to.
---@param ordinal integer The ordinal of the camera window.
---@return LuaGuiElement
function remote_interface.get_window_frame(player, ordinal)
  local window = check_and_get_window(player, ordinal)

  return window.window
end

---Get the size of a camera window.
---@param player LuaPlayer The player the camera window belongs to.
---@param ordinal integer The ordinal of the camera window.
---@return [integer, integer]
function remote_interface.get_window_size(player, ordinal)
  local window = check_and_get_window(player, ordinal)

  return window:get_size()
end

---Set the size of a camera window.
---@param player LuaPlayer The player the camera window belongs to.
---@param ordinal integer The ordinal of the camera window.
---@param size [integer, integer] The new size to set to.
function remote_interface.set_window_size(player, ordinal, size)
  local window = check_and_get_window(player, ordinal)
  check_param_size(size)

  window:set_size(size)
end


---Get the location of a camera window on screen.
---@param player LuaPlayer The player the camera window belongs to.
---@param ordinal integer The ordinal of the camera window.
---@return GuiLocation
function remote_interface.get_window_location(player, ordinal)
  local window = check_and_get_window(player, ordinal)

  return window.window.location
end

---Set the location of a camera window on screen.
---@param player LuaPlayer The player the camera window belongs to.
---@param ordinal integer The ordinal of the camera window.
---@param location GuiLocation The new location to set to.
function remote_interface.set_window_location(player, ordinal, location)
  local window = check_and_get_window(player, ordinal)

  window.window.location = location
  window:update_menu_location()
end


remote.add_interface("windowed-cameras", remote_interface)