-- Camera window GUI functionalities, encapsulates interactions with the GUI elements

local constants = require('lib/constants.lua')
local util = require('util')

---@class CameraWindow
---@field window LuaGuiElement
local prototype = {}

local CameraWindow = {
  __index = prototype,
}

---Create a new camera window.
---@param player LuaPlayer
---@param reference (LuaPlayer | LuaGuiElement)? Reference to set initial position/zoom/surface from.
function CameraWindow:create(player, reference)
  if not reference then
    reference = player
  end

  local instance = setmetatable({}, self)

  -- Find the largest ordinal of existing windows, the new window will have an ordinal of that + 1
  local n_window = 0
  for _, gui_element in ipairs(player.gui.screen.children) do
    if util.string_starts_with(gui_element.name, constants.camera_window_name_prefix) then
      n_window = math.max(n_window, tonumber(gui_element.tags.ordinal) or 0)
    end
  end
  local window_ordinal = n_window + 1

  instance.window = player.gui.screen.add{
    type = "frame",
    name = constants.camera_window_name_prefix..window_ordinal,
    direction = "vertical",
    tags = {
      ordinal = window_ordinal,
      editing = false,
    },
  }
  instance.window.style.size = {400, 400}

  local header_flow = instance.window.add{
    type = "flow",
    direction = "horizontal",
    style = "frame_header_flow"
  }
  header_flow.drag_target = instance.window
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
    style = "frame_action_button",
    name = constants.clone_button_name,
    sprite = "utility/add_white",
    tooltip = {"windowed-cameras.clone-button-title"},
    mouse_button_filter = {"left"},
    tags = {
      on_click = "clone",
    },
  }
  header_flow.add{
    type = "sprite-button",
    style = "frame_action_button",
    name = constants.camera_edit_button_name,
    sprite = constants.sprite_edit_camera,
    tooltip = {"windowed-cameras.edit-button-title"},
    mouse_button_filter = {"left"},
    tags = {
      on_click = "toggle_editing",
    },
  }
  header_flow.add{
    type = "sprite-button",
    style = "close_button",
    name = constants.close_button_name,
    sprite = "utility/close",
    tooltip = {"gui.close"},
    mouse_button_filter = {"left"},
    tags = {
      on_click = "destroy",
    },
  }

  local content_flow = instance.window.add{
    type = "frame",
    style = "inside_shallow_frame"
  }
  content_flow.add{
    type = "camera",
    name = constants.cemera_view_name,
    style = constants.style_prefix.."camera_window_camera_view",
    position = reference.position,
    surface_index = reference.surface_index,
    zoom = reference.zoom,
    tags = {
      on_click = "toggle_editing",
    },
  }

  return instance
end

---Obtain a CameraWindow from a LuaGuiElement.
---@param element LuaGuiElement
---@return CameraWindow?
function CameraWindow:from(element)
  while not util.string_starts_with(element.name, constants.camera_window_name_prefix) do
    element = element.parent
    if not element then return nil end
  end

  local instance = setmetatable({}, self)
  instance.window = element
  return instance
end

---Find the CameraWindow that is currently being edited.
---@return CameraWindow?
function CameraWindow:get_editing(player)
  local window = nil
  for _, gui_element in ipairs(player.gui.screen.children) do
    if util.string_starts_with(gui_element.name, constants.camera_window_name_prefix) then
      if gui_element.tags.editing then
        window = gui_element
        break
      end
    end
  end
  if not window then return nil end

  local instance = setmetatable({}, self)
  instance.window = window
  return instance
end

---Show or hide all windows, ending all edits in the process.
---@param player LuaPlayer
---@param visible boolean
---@return int #The number of windows affected.
function CameraWindow:set_all_visible(player, visible)
  local count = 0
  for _, gui_element in ipairs(player.gui.screen.children) do
    local camera_window = CameraWindow:from(gui_element)
    if camera_window then
      count = count + 1
      camera_window:end_editing()
      camera_window:set_visible(visible)
    end
  end
  return count
end

function prototype:get_camera()
  return self.window.children[2][constants.cemera_view_name]
end

function prototype:get_edit_button()
  return self.window.children[1][constants.camera_edit_button_name]
end

function prototype:destroy()
  self:end_editing()
  self.window.destroy()
end

function prototype:is_visible()
  return self.window.visible
end

---@param visible boolean
function prototype:set_visible(visible)
  self.window.visible = visible
end

function prototype:clone()
  self:end_editing()

  local player = game.get_player(self.window.player_index)
  if not player then return end

  local new_window = CameraWindow:create(player, self:get_camera())
  -- Offset the new window a little
  new_window.window.location = {self.window.location.x + 20, self.window.location.y + 20}
  return new_window
end

function prototype:is_editing()
  return self.window.tags.editing and true or false
end

function prototype:toggle_editing()
  if not self.window.tags.editing then
    self:begin_editing()
  else
    self:end_editing()
  end
end

function prototype:begin_editing()
  if self.window.tags.editing then return end
  
  local player = game.get_player(self.window.player_index)
  if not player then return end

  -- End editing of other windows
  for _, gui_element in ipairs(player.gui.screen.children) do
    local other = CameraWindow:from(gui_element)
    if other then
      other:end_editing()
    end
  end

  -- Open remote view at the position of the camera
  local camera = self:get_camera()
  player.set_controller{
    type = defines.controllers.remote,
    position = camera.position,
    surface = camera.surface_index,
  }
  player.zoom = camera.zoom

  self:get_edit_button().toggled = true
  self.window.tags = util.merge{self.window.tags, {editing = true}}
  storage.players[player.index].is_editing_camera = true
end

function prototype:end_editing()
  if not self.window.tags.editing then return end

  local player = game.get_player(self.window.player_index)
  if not player then return end

  -- Close remote view
  player.exit_remote_view()

  self:get_edit_button().toggled = false
  self.window.tags = util.merge{self.window.tags, {editing = false}}
  storage.players[player.index].is_editing_camera = false
end

---@param player LuaPlayer
function prototype:set_view_from_player(player)
  local camera = self:get_camera()
  camera.position = player.position
  camera.surface_index = player.surface_index
  camera.zoom = player.zoom
end

return CameraWindow