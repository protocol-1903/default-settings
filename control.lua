script.on_init(function (event)
  storage = {
    player_settings = {},
    monitor = {},
    deathrattles = {}
  }
end)

script.on_configuration_changed(function (event)
  storage = {
    player_settings = storage.player_settings or {},
    monitor = storage.monitor or {},
    deathrattles = storage.deathrattles or {}
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

  if not entity or not handlers[type] or not defines.relative_gui_type[type:gsub("-", "_") .. "_gui"] then return end

  local defaults = handlers.defaults(entity, player_index, false)

  if player.gui.relative["default-settings"] then
    player.gui.relative["default-settings"].destroy()
  end

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
    local defaults = handlers.defaults(entity, event.player_index, false)
    if parent == "entity_settings" then
      defaults.entity_settings = nil
      defaults.basic_entity_settings = nil
    else
      defaults.circuit_settings = nil
    end
  end

  update_gui(entity, event.player_index)
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function (event)
  local player = game.get_player(event.player_index)
  local item = player.cursor_stack
  if player.is_cursor_empty() or not item or not item.valid_for_read or (item.name ~= "green-wire" and item.name ~= "red-wire") then
    -- remove from monitor
    storage.monitor[event.player_index] = nil
  else
    storage.monitor[event.player_index] = {
      connected = {},
      disconnected = {}
    }
    -- if player is currently hovering over an entity, check if it should be added to check
    if player.selected and handlers[player.selected] then
      storage.monitor[event.player_index][
      player.selected.get_wire_connector(defines.wire_connector_id.circuit_green, true).connection_count +
      player.selected.get_wire_connector(defines.wire_connector_id.circuit_red, true).connection_count
      == 0 and "disconnected" or "connected"][player.selected.unit_number] = player.selected
    end
  end
end)

script.on_event(defines.events.on_selected_entity_changed, function (event)
  local entity = game.get_player(event.player_index).selected
  -- if we're monitoring that player and there is a handler for hovered entity
  if entity and handlers[entity.type] and storage.monitor[event.player_index] then
    storage.monitor[event.player_index][entity.get_wire_connector(defines.wire_connector_id.circuit_green, true).connection_count + entity.get_wire_connector(defines.wire_connector_id.circuit_red, true).connection_count == 0 and "disconnected" or "connected"][entity.unit_number] = entity
  end
end)

script.on_event("default-settings-build", function (event)
  if not storage.monitor[event.player_index] then return end
  local trigger = game.surfaces[1].create_entity{name = "default-settings-trigger-entity", position = {0,0}}
  storage.deathrattles = {}
  storage.deathrattles[script.register_on_object_destroyed(trigger)] = event.player_index
  trigger.destroy()
end)

script.on_event(defines.events.on_object_destroyed, function (event)
  local player_index = storage.deathrattles[event.registration_number]
  if not player_index then return end
  storage.deathrattles[event.registration_number] = nil
  local metadata = storage.monitor[player_index]
  for unit_number, entity in pairs(metadata.connected) do
    -- check for it to be disconnected
    if entity.get_wire_connector(defines.wire_connector_id.circuit_green, true).connection_count + entity.get_wire_connector(defines.wire_connector_id.circuit_red, true).connection_count == 0 then
      storage.monitor[player_index].connected[unit_number] = nil
      storage.monitor[player_index].disconnected[unit_number] = entity

      -- if entity is custom but unchanged, clear settings
      if handlers.is_custom_default(entity, player_index) then
        game.print("clear settings", {skip = defines.print_skip.never})
        handlers.clear_circuit_settings(entity, player_index)
      end
    end
  end
  for unit_number, entity in pairs(metadata.disconnected) do
    -- check for it to be connected
    if entity.get_wire_connector(defines.wire_connector_id.circuit_green, true).connection_count + entity.get_wire_connector(defines.wire_connector_id.circuit_red, true).connection_count ~= 0 then
      storage.monitor[player_index].disconnected[unit_number] = nil
      storage.monitor[player_index].connected[unit_number] = entity
      -- if entity is vanilla and settings existent, then apply
      if handlers.defaults(entity, player_index, false).circuit_settings and handlers.is_default(entity) then
        game.print("apply settings", {skip = defines.print_skip.never})
        handlers.apply_circuit_settings(entity, player_index)
      end
    end
  end
end)