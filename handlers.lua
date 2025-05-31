handlers = handlers or {}

handlers.defaults = function (entity, player)
  local name = entity.type == "entity-ghost" and entity.ghost_name or entity.name
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type

  -- create empty table if nil
  if not storage[player.index] then
    storage[player.index] = {
      individual = {
        [name] = {
          individual = false
        }
      },
      [type] = {}
    }
  end

  if not storage[player.index][type] then
    storage[player.index][type] = {}
  end
  
  if not storage[player.index].individual[name] then
    storage[player.index].individual[name] = {
      individual = false
    }
  end

  return storage[player.index].individual[name].individual and storage[player.index].individual[name] or storage[player.index][type]
end

handlers.save_entity_settings = function (entity, player)
  local defaults = handlers.defaults(entity, player)
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  defaults.basic_entity_settings = {}

  -- save basic settings (R/W values)
  for _, index in pairs(handlers[type].basic_entity_settings) do
    defaults.basic_entity_settings[index] = entity[index]
  end

  handlers[type].save_entity_settings(entity, player)
end

handlers.apply_entity_settings = function (entity, player)
  local defaults = handlers.defaults(entity, player)
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type

  -- apply basic settings (R/W values)
  for index, value in pairs(defaults.basic_entity_settings or {}) do
    entity[index] = value
  end

  if not defaults.entity_settings then return end
  handlers[type].apply_entity_settings(entity, player)
end

handlers.save_circuit_settings = function (entity, player)
  local defaults = handlers.defaults(entity, player)
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  defaults.circuit_settings = {}

  -- load relevant circuit settings
  local control_behavior = entity.get_or_create_control_behavior()
  if control_behavior then
    for _, index in pairs(handlers[type].circuit_settings) do
      defaults.circuit_settings[index] = control_behavior[index]
    end
  end
end

handlers.apply_circuit_settings = function (entity, player)
  local defaults = handlers.defaults(entity, player)

  -- load relevant circuit settings
  local control_behavior = entity.get_or_create_control_behavior()
  if control_behavior then
    for index, value in pairs(defaults.circuit_settings or {}) do
      control_behavior[index] = value
    end
  end
end

handlers.inserter = {
  gui_type = defines.relative_gui_type.inserter_gui,
  circuit_settings = {
    "circuit_enable_disable",
    "circuit_condition",
    "connect_to_logistic_network",
    "logistic_condition",

    "circuit_set_filters",
    "circuit_read_hand_contents",
    "circuit_hand_read_mode",
    "circuit_set_stack_size",
    "circuit_stack_control_signal"
  },
  basic_entity_settings = {
    "use_filters",
    "inserter_stack_size_override",
    "inserter_filter_mode",
    "inserter_spoil_priority"
  },
  apply_entity_settings = function (entity, player)
    local defaults = handlers.defaults(entity, player)
    -- clear old filters
    for i = 1, entity.filter_slot_count do
      entity.set_filter(i)
    end
    -- set new filters manually, only fills as many as required
    for i = 1, entity.filter_slot_count do
      entity.set_filter(i, defaults.entity_settings.filters[i])
    end
  end,
  save_entity_settings = function (entity, player)
    local defaults = handlers.defaults(entity, player)
    local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
    defaults.entity_settings = {filters = {}}
    for i = 1, entity.filter_slot_count do
      defaults.entity_settings.filters[i] = entity.get_filter(i)
    end
  end
}

return handlers