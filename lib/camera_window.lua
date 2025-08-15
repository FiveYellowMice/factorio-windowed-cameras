-- Camera window GUI functionalities, encapsulates interactions with the GUI elements

local constants = require('lib/constants.lua')
local util = require('util')
local CameraWindowMenu = require('lib/camera_window_menu.lua')

---@class CameraWindow
---@field window LuaGuiElement
local prototype = {}

local CameraWindow = {
  __index = prototype,
}

---Create a new camera window.
---@param player LuaPlayer
---@param reference (LuaPlayer | LuaGuiElement)? Reference to set initial position/zoom/surface from.
---@param size [integer, integer]? Width and height of the window.
function CameraWindow:create(player, reference, size)
  if not reference then
    reference = player
  end

  local instance = setmetatable({}, self)

  -- Find the smallest ordinal that isn't taken by any existing window
  local existing_ordinals = {}
  for _, gui_element in ipairs(player.gui.screen.children) do
    if gui_element.valid and util.string_starts_with(gui_element.name, constants.camera_window_name_prefix) then
      existing_ordinals[tonumber(gui_element.tags.ordinal)] = true
    end
  end
  local window_ordinal = 1
  while existing_ordinals[window_ordinal] do
    window_ordinal = window_ordinal + 1
  end

  instance.window = player.gui.screen.add{
    type = "frame",
    name = constants.camera_window_name_prefix..window_ordinal,
    direction = "vertical",
    tags = {
      ordinal = window_ordinal,
      editing = false,
      [constants.gui_tag_event_enabled] = true,
      on_location_changed = "update_menu_location",
    },
  }
  if size then
    instance.window.style.size = size
  else
    instance.window.style.size = constants.camera_window_size_default
  end

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
    name = "clone-button",
    sprite = "utility/add_white",
    tooltip = {"windowed-cameras.clone-button-tooltip"},
    mouse_button_filter = {"left"},
    tags = {
      [constants.gui_tag_event_enabled] = true,
      on_click = "clone",
    },
  }
  header_flow.add{
    type = "sprite-button",
    style = "frame_action_button",
    name = "edit-button",
    sprite = constants.sprite_edit_camera,
    tooltip = {"windowed-cameras.edit-button-tooltip"},
    mouse_button_filter = {"left"},
    tags = {
      [constants.gui_tag_event_enabled] = true,
      on_click = "toggle_editing",
    },
  }
  header_flow.add{
    type = "sprite-button",
    style = "frame_action_button",
    name = "menu-button",
    sprite = constants.sprite_menu_button,
    tooltip = {"windowed-cameras.menu-button-tooltip"},
    mouse_button_filter = {"left"},
    tags = {
      [constants.gui_tag_event_enabled] = true,
      on_click = "toggle_menu",
    },
  }
  header_flow.add{
    type = "sprite-button",
    style = "close_button",
    name = "close-button",
    sprite = "utility/close",
    tooltip = {"gui.close"},
    mouse_button_filter = {"left"},
    tags = {
      [constants.gui_tag_event_enabled] = true,
      on_click = "destroy",
    },
  }

  local content_flow = instance.window.add{
    type = "frame",
    style = "inside_shallow_frame"
  }
  local camera = content_flow.add{
    type = "camera",
    name = "camera-view",
    style = constants.style_prefix.."camera_window_camera_view",
    position = reference.position,
    surface_index = reference.surface_index,
    zoom = reference.zoom,
    tags = {
      [constants.gui_tag_event_enabled] = true,
      on_click = "toggle_editing",
    },
  }

  if reference.object_name == "LuaPlayer" then
    camera.entity = reference.centered_on
  elseif reference.object_name == "LuaGuiElement" then
    camera.entity = reference.entity
  end

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

  return setmetatable({
    window = element,
  }, self)
end

---Find the window with the given ordinal
---@param player LuaPlayer
---@param ordinal integer
function CameraWindow:get(player, ordinal)
  local window = nil
  for _, gui_element in ipairs(player.gui.screen.children) do
    if util.string_starts_with(gui_element.name, constants.camera_window_name_prefix) then
      if gui_element.tags.ordinal == ordinal then
        window = gui_element
        break
      end
    end
  end
  if not window then return nil end

  return setmetatable({
    window = window,
  }, self)
end

---Find the corresponding window of a CameraWindowMenu
---@param menu CameraWindowMenu
---@return CameraWindow?
function CameraWindow:for_menu(menu)
  local player = game.get_player(menu.frame.player_index)
  if not player then return nil end

  return self:get(player, menu.frame.tags.ordinal --[[@as integer]])
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

  return setmetatable({
    window = window,
  }, self)
end

function CameraWindow.__eq(a, b)
  return a.window == b.window
end

---Show or hide all windows, ending all edits in the process.
---@param player LuaPlayer
---@param visible boolean
---@return int #The number of windows affected.
function CameraWindow:set_all_visible(player, visible)
  local editing = CameraWindow:get_editing(player)
  if editing then editing:end_editing() end

  local count = 0
  for _, gui_element in ipairs(player.gui.screen.children) do
    local camera_window = gui_element.valid and CameraWindow:from(gui_element)
    if camera_window then
      count = count + 1
      camera_window:set_visible(visible)
    end
  end
  return count
end

---An event raised when a camera window has been closed.
CameraWindow.event_window_closed = script.generate_event_name()
---@package
---@param player_index integer
function CameraWindow:raise_window_closed(player_index)
  local player = game.get_player(player_index)
  if not player then return end

  local remaining = false
  for _, gui_element in ipairs(player.gui.screen.children) do
    if gui_element.valid and util.string_starts_with(gui_element.name, constants.camera_window_name_prefix) then
      remaining = true
      break
    end
  end

  ---@class CameraWindowClosedData
  local event = {
    player_index = player_index,
    ---Whether there are camera windows remaining open afterwards.
    remaining = remaining,
  }
  script.raise_event(self.event_window_closed, event)
end

function prototype:get_camera()
  return self.window.children[2]["camera-view"]
end

function prototype:get_edit_button()
  return self.window.children[1]["edit-button"]
end

function prototype:get_menu_button()
  return self.window.children[1]["menu-button"]
end

function prototype:destroy()
  local player_index = self.window.player_index

  self:end_editing()
  self:close_menu()
  self.window.destroy()

  getmetatable(self):raise_window_closed(player_index)
end

function prototype:is_visible()
  return self.window.visible
end

---@param visible boolean
function prototype:set_visible(visible)
  if not visible then
    self:close_menu()
  end
  self.window.visible = visible
end

function prototype:clone()
  self:end_editing()

  local player = game.get_player(self.window.player_index)
  if not player then return end

  local new_window = CameraWindow:create(player, self:get_camera(), self:get_size())
  -- Offset the new window a little
  new_window.window.location = {self.window.location.x + 20, self.window.location.y + 20}
  return new_window
end

---@return [integer, integer]
function prototype:get_size()
  return {self.window.style.minimal_width, self.window.style.minimal_height}
end

---Resize the window.
---Anchoring to top right so that the menu button stays at the same place relative to the menu.
---@param size [integer, integer]
function prototype:set_size(size)
  local player = game.get_player(self.window.player_index)
  if not player then return end

  local old_size = self:get_size()
  local old_location = self.window.location --[[@as GuiLocation]]

  self.window.style.width = size[1]
  self.window.style.height = size[2]

  self.window.location = {
    x = old_location.x - (size[1] - old_size[1]) * player.display_scale,
    y = old_location.y,
  }
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
  local editing = CameraWindow:get_editing(player)
  if editing then editing:end_editing() end

  -- Hide other windows
  for _, gui_element in ipairs(player.gui.screen.children) do
    local other = gui_element.valid and CameraWindow:from(gui_element)
    if other and other ~= self then
      other:set_visible(false)
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
  player.centered_on = camera.entity

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

  -- Clear entity selector
  if player.cursor_stack.valid_for_read and player.cursor_stack.name == constants.track_entity_selector_name then
    player.cursor_stack.clear()
  end

  -- Show other windows
  for _, gui_element in ipairs(player.gui.screen.children) do
    local other = gui_element.valid and CameraWindow:from(gui_element)
    if other and other ~= self then
      other:set_visible(true)
    end
  end

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
  camera.entity = player.centered_on
end

---@param entity LuaEntity?
---@return boolean success
function prototype:select_tracked_entity(entity)
  local player = game.get_player(self.window.player_index)
  if not player then return false end

  if not entity then
    player.create_local_flying_text{
      text = {"windowed-cameras.track-entity-selection-empty-message"},
      create_at_cursor = true,
    }
    return false
  end

  if entity.force_index ~= player.force_index then
    player.create_local_flying_text{
      text = {"windowed-cameras.track-entity-selection-force-differ-message"},
      create_at_cursor = true,
    }
    return false
  end

  -- Selecting tracked entity may happen in or outside of editing mode, we handle both
  if self:is_editing() then
    player.centered_on = entity
    self:set_view_from_player(player)
  else
    local camera = self:get_camera()
    camera.entity = entity
    camera.zoom = player.zoom
  end

  player.create_local_flying_text{
    text = {"windowed-cameras.track-entity-selection-success-message", entity.name_tag or entity.localised_name},
    create_at_cursor = true,
  }

  return true
end

function prototype:toggle_menu()
  local menu = CameraWindowMenu:for_window(self)
  if not menu then
    CameraWindowMenu:create(self)
  else
    menu:destroy()
  end
end

function prototype:close_menu()
  local menu = CameraWindowMenu:for_window(self)
  if menu then
    menu:destroy()
  end
end

function prototype:update_menu_location()
  local menu = CameraWindowMenu:for_window(self)
  if menu then
    menu:align_location_to_window(self)
  end
end

CameraWindowMenu.set_window_module(CameraWindow)
return CameraWindow