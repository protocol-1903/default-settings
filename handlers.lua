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

  if not handlers[type].save_entity_settings then return end
  handlers[type].save_entity_settings(entity, player)
end

handlers.apply_entity_settings = function (entity, player)
  local defaults = handlers.defaults(entity, player)
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type

  -- apply basic settings (R/W values)
  for index, value in pairs(defaults.basic_entity_settings or {}) do
    entity[index] = value
  end

  if not defaults.entity_settings or not handlers[type].apply_entity_settings then return end
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

-- belt speaker display panel pump

-- handlers["accumulator"] = {}
-- handlers["agricultural-tower"] = {}
-- handlers["ammo-turret"] = {}
-- handlers["arithmetic-combinator"] = {}
-- handlers["artillery-turret"] = {}
-- handlers["artillery-wagon"] = {}
-- handlers["assembling-machine"] = {}
-- handlers["asteroid-collector"] = {}
-- handlers["beacon"] = {}
-- handlers["boiler"] = {}
-- handlers["burner-generator"] = {}
-- handlers["car"] = {}
-- handlers["cargo-bay"] = {}
-- handlers["cargo-landing-pad"] = {}
-- handlers["cargo-wagon"] = {}
-- handlers["constant-combinator"] = {}
-- handlers["container"] = {}
-- handlers["decider-combinator"] = {}
handlers["display-panel"] = {
  circuit_settings = {
    "messages"
  }
}
-- handlers["electric-energy-interface"] = {}
-- handlers["electric-pole"] = {}
-- handlers["electric-turret"] = {}
-- handlers["fluid-turret"] = {}
-- handlers["fluid-wagon"] = {}

handlers["furnace"] = {
  circuit_settings = {
    "circuit_enable_disable",
    "circuit_condition",
    "connect_to_logistic_network",
    "logistic_condition",

    "circuit_read_contents",
    "include_in_crafting",
    "include_fuel",
    "circuit_read_recipe_finished",
    "circuit_recipe_finished_signal",
    "circuit_read_working",
    "circuit_working_signal"
  }
}

-- handlers["fusion-generator"] = {}
-- handlers["fusion-reactor"] = {}
-- handlers["gate"] = {}
-- handlers["generator"] = {}
-- handlers["heat-interface"] = {}
-- handlers["infinity-cargo-wagon"] = {}
-- handlers["infinity-container"] = {}
-- handlers["infinity-pipe"] = {}

handlers["inserter"] = {
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

-- handlers["lab"] = {}
-- handlers["lamp"] = {}
-- handlers["land-mine"] = {}
-- handlers["lane-splitter"] = {}
-- handlers["linked-belt"] = {}
-- handlers["linked-container"] = {}
-- handlers["loader"] = {}
-- handlers["loader-1x1"] = {}
-- handlers["locomotive"] = {}
-- handlers["logistic-container"] = {}
-- handlers["market"] = {}
-- handlers["mining-drill"] = {}
-- handlers["offshore-pump"] = {}
-- handlers["power-switch"] = {}
handlers["programmable-speaker"] = {
  circuit_settings = {
    "circuit_condition",
    "circuit_parameters"
  },
  basic_entity_settings = {
    "parameters",
    "alert_parameters"
  }
}
-- handlers["proxy-container"] = {}
handlers["pump"] = {
  circuit_settings = {
    "circuit_enable_disable",
    "circuit_condition",
    "connect_to_logistic_network",
    "logistic_condition",

    "set_filter"
  }
}
-- handlers["radar"] = {}
-- handlers["rail-chain-signal"] = {}
-- handlers["rail-signal"] = {}
-- handlers["reactor"] = {}
-- handlers["roboport"] = {}
-- handlers["rocket-silo"] = {}
-- handlers["selector-combinator"] = {}
-- handlers["spider-vehicle"] = {}
-- handlers["splitter"] = {}
-- handlers["storage-tank"] = {}
-- handlers["thruster"] = {}
-- handlers["train-stop"] = {}
-- handlers["transport-belt"] = {}
-- handlers["turret"] = {}
-- handlers["wall"] = {}

return handlers