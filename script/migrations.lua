-- Migrations triggered on_configuration_changed. We roll our own migration mechanism because
-- Factorio's built-in migrations run even when this mod is newly added, but we want migrations
-- to only run when the mod is upgraded.

local util = require("util")
local CameraWindow = require("script.camera_window")

local migrations = {}

---@param event ConfigurationChangedData
function migrations.on_configuration_changed(event)
  -- Run when this mod has been upgraded.
  local mod_change = event.mod_changes[script.mod_name]
  if not (mod_change and mod_change.old_version) then return end

  -- Run migrations.
  for version, func in pairs(migrations.this_mod_migrations) do
    if helpers.compare_versions(mod_change.old_version, version) < 0 then
      log("Run migrations for v"..version)
      func()
    end
  end

  -- Recreate GUIs.
  for _, player_data in pairs(storage.players) do
    for _, window in pairs(player_data.camera_windows) do
      window:destroy_frame()
      window:create_frame()
      if window.menu then
        window.menu:destroy_frame()
        window.menu:create_frame()
      end
    end
  end
end

---Migrations applicable to this mod.
---Ensure this is ordered in ascending versions.
---@type table<string, function>
migrations.this_mod_migrations = {
  ["0.2.0"] = function()
    for _, player in pairs(game.players) do
      for _, gui_element in ipairs(player.gui.screen.children) do
        if util.string_starts_with(gui_element.name, "windowed-cameras-camera-window-main-") then
          -- The localisation keys of the tooltips of these buttons have been changed.
          gui_element.children[1]["clone-button"].tooltip = {"windowed-cameras.clone-button-tooltip"}
          gui_element.children[1]["edit-button"].tooltip = {"windowed-cameras.edit-button-tooltip"}
          gui_element.children[1]["menu-button"].tooltip = {"windowed-cameras.menu-button-tooltip"}
        end

        if util.string_starts_with(gui_element.name, "windowed-cameras-camera-window-menu-") then
          -- A "Track entity" button has been added.
          local buttons_flow = gui_element.add{
            type = "flow",
            name = "buttons",
            direction = "horizontal",
          }
          buttons_flow.add{
            type = "button",
            name = "track-entity-button",
            caption = {"windowed-cameras.track-entity-button-caption"},
            tooltip = {"windowed-cameras.track-entity-button-tooltip"},
            mouse_button_filter = {"left"},
            tags = {
              ["windowed-cameras-event-enabled"] = true,
              on_click = "handle_track_entity_clicked",
            }
          }
        end
      end
    end
  end,

  ["0.4.0"] = function()
    for _, player in pairs(game.players) do
      -- Discard old PlayerData.
      storage.players[player.index] = {
        camera_windows = {},
      }
      -- End all edits, but checking for edit states is too much work,
      -- so remote views are untouched, and GUI elements are destroyed anyway,
      -- Just clear track eneity selector.
      if player.cursor_stack and player.cursor_stack.valid_for_read and
        player.cursor_stack.name == "windowed-cameras-track-entity-selector"
      then
        player.cursor_stack.clear()
      end

      for _, gui_element in ipairs(player.gui.screen.children) do
        -- Migrate camera window data from being stored in LuaGuiElement states to storage table.
        if util.string_starts_with(gui_element.name, "windowed-cameras-camera-window-main-") then
          local tags = gui_element.tags
          if type(tags.ordinal) ~= "number" then goto continue end
          local camera = gui_element.children[2]["camera-view"]

          local window_obj = setmetatable({
            player = player,
            ordinal = tags.ordinal--[[@as number]],
            view_settings = {
              position = {x = camera.position.x, y = camera.position.y},
              surface_index = camera.surface_index,
              zoom = camera.zoom,
              entity = camera.entity,
            },
            window_settings = {
              size = {x = gui_element.style.minimal_width, y = gui_element.style.minimal_height},
            },
          }, CameraWindow.prototype)
          storage.players[player.index].camera_windows[window_obj.ordinal] = window_obj

          gui_element.destroy()

        -- Discard old camera window menus.
        elseif util.string_starts_with(gui_element.name, "windowed-cameras-camera-window-menu-") then
          gui_element.destroy()
        end
        ::continue::
      end

    end
  end,
}

return migrations
