script.on_init(function (event)
  storage = {
    player_settings = {}
  }
end)

script.on_configuration_changed(function (event)
  storage = {
    player_settings = storage.player_settings or {}
  }
end)

local handlers = require "handlers"

-- belts, speakers, display panels, pumps

invalid_circuit_setting = {
  valid = true,
  object_name = true,
  disabled = true,
  type = true,
  entity = true,
  signals_last_tick = true,
  sections = true,
  sections_count = true,
  color = true,
}

local function update_gui(entity, player_index)
  ---@type string
  local type = entity and (entity.type == "entity-ghost" and entity.ghost_type or entity.type)
  local player = game.get_player(player_index)

  if not player then return end

  if player.gui.relative["default-settings"] then
    player.gui.relative["default-settings"].destroy()
  end

  if not player.is_shortcut_toggled("default-settings-show-gui") then return end
  
  if not entity or not handlers[type] or not defines.relative_gui_type[type:gsub("-", "_") .. "_gui"] then return end
  
  local defaults = handlers.defaults(entity, player_index)
  ---@type LuaGuiElement
  local window = player.gui.relative.add{
    type = "frame",
    name = "default-settings",
    caption = { "ds-window.frame" },
    direction = "vertical",
    anchor = {
      gui = defines.relative_gui_type[type:gsub("-", "_") .. "_gui"],
      position = defines.relative_gui_position.left
    }
  }.add{
    type = "frame",
    style = "inside_shallow_frame_with_padding_and_vertical_spacing",
    direction = "vertical"
  }
  subheader = window.add{
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
  end
end)

script.on_event(defines.events.on_player_setup_blueprint, function (event)

end)

script.on_event(defines.events.on_gui_opened, function (event)
  update_gui(event.entity, event.player_index)
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

  update_gui(entity, event.player_index)
end)

script.on_event(defines.events.on_gui_click, function (event)
  if event.element.get_mod() ~= "default-settings" then return end
  local entity = game.get_player(event.player_index).opened
  if not entity then return end
  handlers[event.element.tags.handler](entity, event.player_index)
  update_gui(entity, event.player_index)
end)

---@param event EventData.on_circuit_wire_added
script.on_event(defines.events.on_pre_circuit_wire_added, function (event)
  if not event.player_index then return end
  local source = event.source
  local destination = event.destination
  ---@type defines.wire_connector_id
  local source_base_id = event.source_connector_id - (event.source_connector_id + 1) % 2 + 1
  ---@type defines.wire_connector_id
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
  ---@type LuaEntity
  local destination = event.destination
  ---@type defines.wire_connector_id
  local source_base_id = event.source_connector_id - (event.source_connector_id + 1) % 2 + 1
  ---@type defines.wire_connector_id
  local destination_base_id = event.destination_connector_id - (event.destination_connector_id + 1) % 2 + 1
  if source.get_wire_connector(source_base_id, true).connection_count + source.get_wire_connector(source_base_id - 1, true).connection_count == 0 and handlers.is_circuit_custom_default(source, event.player_index) then
    handlers.clear_circuit_settings(source, event.player_index)
  end
  if destination.get_wire_connector(destination_base_id, true).connection_count + destination.get_wire_connector(destination_base_id - 1, true).connection_count == 0 and handlers.is_circuit_custom_default(destination, event.player_index) then
    handlers.clear_circuit_settings(destination, event.player_index)
  end
end)

-- handle the case where one entity was removed (this is ignored in the previous handler)
---@param event EventData.on_circuit_network_destroyed
script.on_event(defines.events.on_circuit_network_destroyed, function (event)
  if not event.player_index then return end
  if event.source and event.source.get_wire_connector(event.source_connector_id - (event.source_connector_id + 1) % 2 + 1, true).connection_count == 0 then
    handlers.clear_circuit_settings(event.source, event.player_index)
  end
  if event.destination and event.destination.get_wire_connector(event.destination_connector_id - (event.destination_connector_id + 1) % 2 + 1, true).connection_count == 0 then
    handlers.clear_circuit_settings(event.destination, event.player_index)
  end
end)

script.on_event(defines.events.on_lua_shortcut, function (event)
  log(event.prototype_name)
  if event.prototype_name == "default-settings-show-gui" then
    game.get_player(event.player_index).set_shortcut_toggled(
      "default-settings-show-gui",
      not game.get_player(event.player_index).is_shortcut_toggled("default-settings-show-gui")
    )
    update_gui(game.get_player(event.player_index).opened, event.player_index)
  end
end)