-- Migrations triggered on_configuration_changed. We roll our own migration mechanism because
-- Factorio's built-in migrations run even when this mod is newly added, but we want migrations
-- to only run when the mod is upgraded.

local util = require("util")

local migrations = {}

---@param event ConfigurationChangedData
function migrations.on_configuration_changed(event)
  local mod_change = event.mod_changes[script.mod_name]
  if not (mod_change and mod_change.old_version) then return end

  for version, func in pairs(migrations.this_mod_migrations) do
    if helpers.compare_versions(mod_change.old_version, version) < 0 then
      func()
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
  end
}

return migrations