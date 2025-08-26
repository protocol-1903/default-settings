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
  local type = entity and (entity.type == "entity-ghost" and entity.ghost_type or entity.type)
  local name = entity and (entity.type == "entity-ghost" and entity.ghost_name or entity.name)
  local player = game.get_player(player_index)

  if player.gui.relative["default-settings"] then
    player.gui.relative["default-settings"].destroy()
  end

  if not player.is_shortcut_toggled("default-settings-show-gui") then return end
  
  if not entity or not handlers[type] or not defines.relative_gui_type[type:gsub("-", "_") .. "_gui"] then return end
  
  local defaults = handlers.defaults(entity, player_index)
  
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
  -- subheader.add{
  --   type = "label",
  --   style = "caption_label",
  --   caption = { "ds-window.radiobutton-label" }
  -- }
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
      name = "save",
      sprite = "ds-settings-save",
      style = "ds_action_button",
      tooltip = { "ds-tooltip.save" }
    }
    window.entity_settings.add{
      type = "sprite-button",
      name = "load",
      sprite = "ds-settings-load",
      style = "ds_action_button",
      tooltip = { "ds-tooltip.load" }
    }.enabled = defaults.entity_settings ~= nil or defaults.basic_entity_settings ~= nil
    window.entity_settings.add{
      type = "sprite-button",
      name = "delete",
      sprite = "ds-settings-delete",
      style = "ds_action_button",
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
      name = "save",
      sprite = "ds-settings-save",
      style = "ds_action_button",
      tooltip = { "ds-tooltip.save" }
    }
    window.circuit_settings.add{
      type = "sprite-button",
      name = "load",
      sprite = "ds-settings-load",
      style = "ds_action_button",
      tooltip = { "ds-tooltip.load" }
    }.enabled = defaults.circuit_settings ~= nil
    window.circuit_settings.add{
      type = "sprite-button",
      name = "delete",
      sprite = "ds-settings-delete",
      style = "ds_action_button",
      tooltip = { "ds-tooltip.delete" }
    }.enabled = defaults.circuit_settings ~= nil
  end
end

script.on_event(defines.events.on_built_entity, function (event)
  handlers.apply_entity_settings(event.entity, event.player_index)
end)

script.on_event(defines.events.on_gui_opened, function (event)
  update_gui(event.entity, event.player_index)
end)

script.on_event(defines.events.on_gui_checked_state_changed, function (event)
  if event.element.get_mod() ~= "default-settings" then return end
  
  local entity = game.get_player(event.player_index).opened
  if not entity then return end

  local element = event.element
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  local name = entity.type == "entity-ghost" and entity.ghost_name or entity.name

  if element.name == "individual" and element.state == element.parent.prototype.state then
    storage.player_settings[event.player_index].individual[name].individual = true

  elseif element.name == "prototype" and element.state == element.parent.individual.state then
    storage.player_settings[event.player_index].individual[name].individual = false
  end

  update_gui(entity, event.player_index)
end)

script.on_event(defines.events.on_gui_click, function (event)
  if event.element.get_mod() ~= "default-settings" then return end

  local entity = game.get_player(event.player_index).opened

  if not entity then return end

  local element = event.element
  local parent = element.parent.name
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  local name = entity.type == "entity-ghost" and entity.ghost_name or entity.name


  if element.name == "save" then
    if parent == "entity_settings" then
      handlers.save_entity_settings(entity, event.player_index)
    else
      handlers.save_circuit_settings(entity, event.player_index)
    end
  elseif element.name == "load" then
    if parent == "entity_settings" then
      handlers.apply_entity_settings(entity, event.player_index)
    else
      handlers.apply_circuit_settings(entity, event.player_index)
    end
  elseif element.name == "delete" then
    local defaults = handlers.defaults(entity, event.player_index)
    if parent == "entity_settings" then
      defaults.entity_settings = nil
      defaults.basic_entity_settings = nil
    else
      defaults.circuit_settings = nil
    end
  end

  update_gui(entity, event.player_index)
end)

---@param event EventData.on_circuit_wire_added
script.on_event(defines.events.on_pre_circuit_wire_added, function (event)
  local source = event.source
  local destination = event.destination
  local source_base_id = event.source_connector_id - (event.source_connector_id + 1) % 2 + 1
  local destination_base_id = event.destination_connector_id - (event.destination_connector_id + 1) % 2 + 1
  if source.get_wire_connector(source_base_id, true).connection_count + source.get_wire_connector(source_base_id - 1, true).connection_count == 0 and handlers.defaults(source, event.player_index).circuit_settings and handlers.is_default(source) then
    handlers.apply_circuit_settings(source, event.player_index)
  end
  if destination.get_wire_connector(destination_base_id, true).connection_count + destination.get_wire_connector(destination_base_id - 1, true).connection_count == 0 and handlers.defaults(destination, event.player_index).circuit_settings and handlers.is_default(destination) then
    handlers.apply_circuit_settings(destination, event.player_index)
  end
end)

---@param event EventData.on_circuit_wire_removed
script.on_event(defines.events.on_circuit_wire_removed, function (event)
  local source = event.source
  local destination = event.destination
  local source_base_id = event.source_connector_id - (event.source_connector_id + 1) % 2 + 1
  local destination_base_id = event.destination_connector_id - (event.destination_connector_id + 1) % 2 + 1
  if source.get_wire_connector(source_base_id, true).connection_count + source.get_wire_connector(source_base_id - 1, true).connection_count == 0 and handlers.is_custom_default(source, event.player_index) then
    handlers.clear_circuit_settings(source, event.player_index)
  end
  if destination.get_wire_connector(destination_base_id, true).connection_count + destination.get_wire_connector(destination_base_id - 1, true).connection_count == 0 and handlers.is_custom_default(destination, event.player_index) then
    handlers.clear_circuit_settings(destination, event.player_index)
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