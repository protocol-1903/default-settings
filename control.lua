script.on_init(function (event)
  storage.player_settings = {}
  storage.parameterizing = {}
  storage.confirmed = {}
end)

script.on_configuration_changed(function (event)
  storage.player_settings = storage.player_settings or {}
  storage.parameterizing = storage.parameterizing or {}
  storage.confirmed = storage.confirmed or {}
end)

local handlers = require "handlers"

local function generate_parameter_gui(player_index, parameters, entity)
  if not next(parameters) then return end
  local player = game.get_player(player_index)
  local gui = player.gui.screen["default-settings-parameters"]
  if gui then gui.destroy() end
  storage.parameterizing[player.index] = entity
  gui = player.gui.screen.add{
    name = "default-settings-parameters",
    type = "frame",
    direction = "vertical"
  }
  gui.style.maximal_height = 930
  gui.add{
    name = "header",
    type = "flow",
    style = "frame_header_flow",
    direction = "horizontal"
  }
  gui.header.drag_target = gui
  gui.header.style.vertically_stretchable = false
  gui.header.add{
    name = "title",
    type = "label",
    style = "frame_title",
    caption = {"ds-window.parameter-title"}
  }
  gui.header.title.drag_target = gui
  gui.header.title.style.vertically_stretchable = true
  gui.header.add{
    name = "drag",
    type = "empty-widget",
    style = "draggable_space"
  }
  gui.header.drag.drag_target = gui
  gui.header.drag.style.horizontally_stretchable = true
  gui.header.drag.style.vertically_stretchable = true
  gui.header.add{
    name = "close",
    type = "sprite-button",
    style = "close_button",
    sprite = "utility.close"
  }
  gui.add{
    name = "main",
    type = "flow",
    direction = "vertical"
  }
  gui.main.add{
    name = "shallow",
    type = "frame",
    style = "inside_shallow_frame"
  }
  gui.main.shallow.add{
    name = "pane",
    type = "scroll-pane",
    direction = "vertical",
    style = "entity_frame_scroll_pane"
  }
  gui.main.shallow.pane.horizontal_scroll_policy = "never"
  gui.main.shallow.pane.style.horizontally_stretchable = true
  gui.main.shallow.pane.style.horizontally_squashable = true
  gui.main.shallow.pane.add{
    name = "table",
    type = "table",
    column_count = 3
  }
  for _, parameter in pairs(parameters) do
    gui.main.shallow.pane.table.add{
      type = "label",
      caption = parameter.name
    }
    gui.main.shallow.pane.table.add{
      type = "choose-elem-button",
      style = "slot_button",
      elem_type = parameter.type,
      elem_filters = parameter.filters
    }
    if script.feature_flags.quality and parameter.type:match("quality") then
      gui.main.shallow.pane.table.add{
        type = "drop-down",
        selected_index = 1,
        items = {
          "[img=utility/any_quality]",
          ">",
          "<",
          "=",
          "≥",
          "≤",
          "≠"
        }
      }.style.width = 72
    else
      gui.main.shallow.pane.table.add{
        type = "empty-widget"
      }
    end
  end
  gui.main.add{
    name = "footer",
    type = "flow",
    direction = "horizontal",
    style = "dialog_buttons_horizontal_flow"
  }
  gui.main.footer.add{
    name = "drag",
    type = "empty-widget",
    style = "draggable_space"
  }
  gui.main.footer.drag.drag_target = gui
  gui.main.footer.drag.style.horizontally_stretchable = true
  gui.main.footer.drag.style.vertically_stretchable = true
  gui.main.footer.add{
    name = "confirm",
    type = "sprite-button",
    style = "item_and_count_select_confirm",
    sprite = "utility.confirm_slot",
    enabled = false
  }
  player.opened = gui
  gui.force_auto_center()
end

local function apply_parameters(player_index)
  local player = game.get_player(player_index)
  local entity = storage.parameterizing[player_index]
  storage.parameterizing[player_index] = nil
  if not entity or not entity.valid then return end
  local gui = player.gui.screen["default-settings-parameters"]
  local parameters = {}
  local table = gui.main.shallow.pane.table.children
  for i = 1, #gui.main.shallow.pane.table.children, 3 do
    local elem_value = table[i + 1].elem_value
    local comparator = table[i + 2]
    parameters[table[i].caption] = {
      name = type(elem_value) ~= "string" and elem_value.name or elem_value,
      quality = type(elem_value) ~= "string" and elem_value.quality or nil,
      comparator = comparator.type == "drop-down" and comparator.selected_index or nil
    }
  end
  gui.destroy()
  handlers.set_entity_parameters(entity, parameters)
  player.play_sound{path = "utility/confirm"}
end

local turret_guis = {
  ["ammo-turret"] = defines.relative_gui_type.turret_gui,
  ["artillery-turret"] = defines.relative_gui_type.turret_gui,
  ["electric-turret"] = defines.relative_gui_type.turret_gui,
  ["fluid-turret"] = defines.relative_gui_type.turret_gui,
  ["turret"] = defines.relative_gui_type.turret_gui,
}

local function update_subgui(entity, player_index)
  local type = entity and (entity.type == "entity-ghost" and entity.ghost_type or entity.type)
  local player = game.get_player(player_index)

  if not player then return end

  if player.gui.relative["default-settings"] then
    player.gui.relative["default-settings"].destroy()
  end

  if not player.is_shortcut_toggled("default-settings-show-gui") then return end

  if not entity or not handlers[type] then return end

  local defaults = handlers.defaults(entity, player_index)
  local window = player.gui.relative.add{
    type = "frame",
    name = "default-settings",
    caption = { "ds-window.frame" },
    direction = "vertical",
    anchor = {
      gui = defines.relative_gui_type[type:gsub("-", "_") .. "_gui"] or turret_guis[type] or defines.relative_gui_type.entity_with_energy_source_gui,
      position = defines.relative_gui_position.left
    }
  }.add{
    type = "frame",
    style = "inside_shallow_frame_with_padding_and_vertical_spacing",
    direction = "vertical"
  }
  local subheader = window.add{
    type = "frame",
    style = "subheader_frame"
  }
  subheader.style.left_margin = -12
  subheader.style.right_margin = -12
  subheader.style.top_margin = -12
  subheader.style.bottom_margin = 8
  subheader.style.horizontally_squashable = true
  subheader.style.horizontally_stretchable = true
  subheader = subheader.add{
    type = "flow",
    style = "player_input_horizontal_flow",
    direction = "horizontal"
  }
  subheader.style.left_padding = 12
  subheader.style.right_padding = 12
  subheader.add{
    type = "radiobutton",
    name = "prototype",
    state = defaults.individual == nil,
    caption = { "ds-window.radiobutton-prototype" }
  }
  subheader.add{
    type = "radiobutton",
    name = "individual",
    state = defaults.individual ~= nil,
    caption = { "ds-window.radiobutton-individual" }
  }

  -- only show option if entity settings supported/existant
  if handlers[type].basic_entity_settings or handlers[type].save_entity_settings then
    window.add{
      type = "label",
      style = "caption_label",
      caption = { "ds-window.entity-settings" }
    }
    window.add{
      type = "flow",
      name = "entity_settings",
      style = "player_input_horizontal_flow",
      direction = "horizontal"
    }
    window.entity_settings.add{
      type = "sprite-button",
      sprite = "ds-settings-save",
      style = "ds_action_button",
      tags = {handler = "save_entity_settings"},
      tooltip = { "ds-tooltip.save" }
    }
    window.entity_settings.add{
      type = "sprite-button",
      sprite = "ds-settings-load",
      style = "ds_action_button",
      tags = {handler = "apply_entity_settings"},
      tooltip = { "ds-tooltip.load" }
    }.enabled = defaults.entity_settings ~= nil or defaults.basic_entity_settings ~= nil
    window.entity_settings.add{
      type = "sprite-button",
      sprite = "ds-settings-delete",
      style = "ds_action_button",
      tags = {handler = "delete_entity_settings"},
      tooltip = { "ds-tooltip.delete" }
    }.enabled = defaults.entity_settings ~= nil or defaults.basic_entity_settings ~= nil
  end

  -- only show option if circuit network is supported
  if handlers[type].circuit_settings then
    window.add{
      type = "label",
      style = "caption_label",
      caption = { "ds-window.circuit-settings" }
    }
    window.add{
      type = "flow",
      name = "circuit_settings",
      style = "player_input_horizontal_flow",
      direction = "horizontal"
    }
    window.circuit_settings.add{
      type = "sprite-button",
      sprite = "ds-settings-save",
      style = "ds_action_button",
      tags = {handler = "save_circuit_settings"},
      tooltip = { "ds-tooltip.save" }
    }
    window.circuit_settings.add{
      type = "sprite-button",
      sprite = "ds-settings-load",
      style = "ds_action_button",
      tags = {handler = "apply_circuit_settings"},
      tooltip = { "ds-tooltip.load" }
    }.enabled = defaults.circuit_settings ~= nil
    window.circuit_settings.add{
      type = "sprite-button",
      sprite = "ds-settings-delete",
      style = "ds_action_button",
      tags = {handler = "delete_circuit_settings"},
      tooltip = { "ds-tooltip.delete" }
    }.enabled = defaults.circuit_settings ~= nil
  end
end

script.on_event(defines.events.on_built_entity, function (event)
  if handlers.is_default(event.entity) then
    handlers.apply_entity_settings(event.entity, event.player_index)
    generate_parameter_gui(event.player_index, handlers.get_entity_parameters(event.entity), event.entity)
  end
end)

script.on_event(defines.events.on_gui_opened, function (event)
  update_subgui(event.entity, event.player_index)
end)

script.on_event(defines.events.on_gui_closed, function (event)
  if not event.element or event.element.get_mod() ~= "default-settings" then return end
  local player = game.get_player(event.player_index)
  if storage.confirmed[player.index] == event.tick then
    apply_parameters(player.index)
  else
    local gui = player.gui.screen["default-settings-parameters"]
    if gui then gui.destroy() end
  end
end)

script.on_event(defines.events.on_gui_checked_state_changed, function (event)
  if event.element.get_mod() ~= "default-settings" then return end
  local entity = game.get_player(event.player_index).opened
  if not entity then return end
  local element = event.element

  if element.name == "individual" and element.state == element.parent.prototype.state then
    handlers.enable_individual_settings(entity, event.player_index)
  elseif element.name == "prototype" and element.state == element.parent.individual.state then
    handlers.disable_individual_settings(entity, event.player_index)
  end

  update_subgui(entity, event.player_index)
end)

script.on_event(defines.events.on_gui_click, function (event)
  if event.element.get_mod() ~= "default-settings" then return end
  local player = game.get_player(event.player_index)
  if player.opened_gui_type == defines.gui_type.entity and event.element.tags.handler then
    handlers[event.element.tags.handler](player.opened, player.index)
    update_subgui(player.opened, player.index)
  elseif player.opened_gui_type == defines.gui_type.custom and event.element.name == "close" then
    event.element.parent.parent.destroy()
  elseif player.opened_gui_type == defines.gui_type.custom and event.element.name == "confirm" then
    apply_parameters(player.index)
  end
end)

script.on_event("default-settings-confirm", function (event)
  storage.confirmed[event.player_index] = event.tick
end)

script.on_event(defines.events.on_gui_elem_changed, function (event)
  if event.element.get_mod() ~= "default-settings" then return end
  local player = game.get_player(event.player_index)
  local gui = player.gui.screen["default-settings-parameters"]
  local ready = true
  local table = gui.main.shallow.pane.table.children
  for i = 1, #table, 3 do
    local value = not not table[i + 1].elem_value
    ready = ready and value
    if event.element.index == table[i + 1].index then
      if value and table[i + 2].selected_index == 1 then
        table[i + 2].selected_index = 4
      elseif not value then
        table[i + 2].selected_index = 1
      end
    end
  end
  gui.main.footer.confirm.enabled = ready
end)

---@param event EventData.on_circuit_wire_added
script.on_event(defines.events.on_pre_circuit_wire_added, function (event)
  if not event.player_index then return end
  local source = event.source
  local destination = event.destination
  local source_base_id = event.source_connector_id - (event.source_connector_id + 1) % 2 + 1
  local destination_base_id = event.destination_connector_id - (event.destination_connector_id + 1) % 2 + 1
  if source.get_wire_connector(source_base_id, true).connection_count + source.get_wire_connector(source_base_id - 1, true).connection_count == 0 and handlers.defaults(source, event.player_index).circuit_settings and handlers.is_circuit_default(source) then
    handlers.apply_circuit_settings(source, event.player_index)
  end
  if destination.get_wire_connector(destination_base_id, true).connection_count + destination.get_wire_connector(destination_base_id - 1, true).connection_count == 0 and handlers.defaults(destination, event.player_index).circuit_settings and handlers.is_circuit_default(destination) then
    handlers.apply_circuit_settings(destination, event.player_index)
  end
end)

---@param event EventData.on_circuit_wire_removed
script.on_event(defines.events.on_circuit_wire_removed, function (event)
  if not event.player_index or not event.source or not event.destination then return end
  local source = event.source
  local destination = event.destination
  local source_base_id = event.source_connector_id - (event.source_connector_id + 1) % 2 + 1
  local destination_base_id = event.destination_connector_id - (event.destination_connector_id + 1) % 2 + 1
  if source.get_wire_connector(source_base_id, true).connection_count + source.get_wire_connector(source_base_id - 1, true).connection_count == 0 and handlers.is_circuit_custom_default(source, event.player_index) then
    handlers.clear_circuit_settings(source)
  end
  if destination.get_wire_connector(destination_base_id, true).connection_count + destination.get_wire_connector(destination_base_id - 1, true).connection_count == 0 and handlers.is_circuit_custom_default(destination, event.player_index) then
    handlers.clear_circuit_settings(destination)
  end
end)

-- handle the case where one entity was removed (this is ignored in the previous handler)
---@param event EventData.on_circuit_network_destroyed
script.on_event(defines.events.on_circuit_network_destroyed, function (event)
  if not event.player_index then return end
  if event.source and event.source.get_wire_connector(event.source_connector_id - (event.source_connector_id + 1) % 2 + 1, true).connection_count == 0 then
    handlers.clear_circuit_settings(event.source)
  end
  if event.destination and event.destination.get_wire_connector(event.destination_connector_id - (event.destination_connector_id + 1) % 2 + 1, true).connection_count == 0 then
    handlers.clear_circuit_settings(event.destination)
  end
end)

script.on_event(defines.events.on_lua_shortcut, function (event)
  log(event.prototype_name)
  if event.prototype_name == "default-settings-show-gui" then
    game.get_player(event.player_index).set_shortcut_toggled(
      "default-settings-show-gui",
      not game.get_player(event.player_index).is_shortcut_toggled("default-settings-show-gui")
    )
    update_subgui(game.get_player(event.player_index).opened, event.player_index)
  end
end)