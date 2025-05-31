script.on_init(function (event)
  storage = {}
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

local function update_gui(entity, player)
  local type = entity and (entity.type == "entity-ghost" and entity.ghost_type or entity.type)
  local name = entity and (entity.type == "entity-ghost" and entity.ghost_name or entity.name)

  if not entity or not handlers[type] then return end

  local defaults = handlers.defaults(entity, player)

  if player.gui.relative["default-settings"] then
    player.gui.relative["default-settings"].destroy()
  end

  local window = player.gui.relative.add{
    type = "frame",
    name = "default-settings",
    caption = { "ds-window.frame" },
    direction = "vertical",
    anchor = {
      gui = handlers[type].gui_type,
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
    type = "label",
    style = "caption_label",
    caption = { "ds-window.radiobutton-label" }
  }
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
  local entity = event.entity
  local player = game.players[event.player_index]

  -- load settings
  handlers.apply_entity_settings(entity, player)
  handlers.apply_circuit_settings(entity, player)
end)

script.on_event(defines.events.on_gui_opened, function (event)
  update_gui(event.entity, game.players[event.player_index])
end)

script.on_event(defines.events.on_gui_checked_state_changed, function (event)
  if event.element.get_mod() ~= "default-settings" then return end
  
  local player = game.players[event.player_index]
  local entity = player.opened
  if not entity then return end

  local element = event.element
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  local name = entity.type == "entity-ghost" and entity.ghost_name or entity.name

  if element.name == "individual" and element.state == element.parent.prototype.state then
    storage[player.index].individual[name].individual = true

  elseif element.name == "prototype" and element.state == element.parent.individual.state then
    storage[player.index].individual[name].individual = false
  end

  update_gui(entity, player)
end)

script.on_event(defines.events.on_gui_click, function (event)
  if event.element.get_mod() ~= "default-settings" then return end

  local player = game.players[event.player_index]
  local entity = player.opened

  if not entity then return end

  local element = event.element
  local parent = element.parent.name
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  local name = entity.type == "entity-ghost" and entity.ghost_name or entity.name


  if element.name == "save" then
    if parent == "entity_settings" then
      handlers.save_entity_settings(entity, player)
    else
      handlers.save_circuit_settings(entity, player)
    end
  elseif element.name == "load" then
    if parent == "entity_settings" then
      handlers.apply_entity_settings(entity, player)
    else
      handlers.apply_circuit_settings(entity, player)
    end
  elseif element.name == "delete" then
    local defaults = handlers.defaults(entity, player)
    if parent == "entity_settings" then
      defaults.entity_settings = nil
      defaults.basic_entity_settings = nil
    else
      defaults.circuit_settings = nil
    end
  end

  update_gui(entity, player)
end)