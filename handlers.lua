local handlers = handlers or {}

-- deep compare for equality, works for any data type
handlers.compare = function (data1, data2)
  if type(data1) ~= type(data2) or type(data1) ~= "table" and data1 ~= data2 then
    log(type(data1))
    log(type(data2))
    return false
  elseif type(data1) == "table" then
    local checked_indices = {fulfilled = true}
    for index, data in pairs(data1) do
      if not checked_indices[index] and not handlers.compare(data, data2[index]) then return false end
      checked_indices[index] = true
    end
    for index, data in pairs(data2) do
      if not checked_indices[index] and not handlers.compare(data, data1[index]) then return false end
    end
  end
  return true
end

handlers.defaults = function (entity, player_index, create)
  local name = entity.type == "entity-ghost" and entity.ghost_name or entity.name
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type

  if not handlers[type] then return end
  if create == nil then create = true end

  -- create empty table if nil
  if not storage.player_settings[player_index] then
    storage.player_settings[player_index] = {
      individual = {
        [name] = {
          individual = false
        }
      },
      [type] = {}
    }
  end

  if not storage.player_settings[player_index][type] then
    storage.player_settings[player_index][type] = {}
  end

  -- if create and not storage.player_settings[player_index][type].circuit_settings then
  --   storage.player_settings[player_index][type].circuit_settings = {}
  --   for _, index in pairs(handlers[type]) do
  --     storage.player_settings[player_index][type].circuit_settings[index] = handlers.default_state(index, type) or false
  --   end
  -- end
  
  if not storage.player_settings[player_index].individual[name] then
    storage.player_settings[player_index].individual[name] = {individual = false}
  end

  -- if create and not storage.player_settings[player_index].individual[name].circuit_settings then
  --   storage.player_settings[player_index].individual[name].circuit_settings = {}
  --   for _, index in pairs(handlers[type]) do
  --     storage.player_settings[player_index].individual[name].circuit_settings[index] = handlers.default_state(index, type) or false
  --   end
  -- end

  return storage.player_settings[player_index].individual[name].individual and storage.player_settings[player_index].individual[name] or storage.player_settings[player_index][type]
end

handlers.save_entity_settings = function (entity, player_index)
  local defaults = handlers.defaults(entity, player_index, false)
  if not defaults then return end
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  defaults.basic_entity_settings = {}

  -- save basic settings (R/W values)
  for _, index in pairs(handlers[type].basic_entity_settings) do
    defaults.basic_entity_settings[index] = entity[index]
  end

  if not handlers[type].save_entity_settings then return end
  handlers[type].save_entity_settings(entity, player_index)
end

handlers.apply_entity_settings = function (entity, player_index)
  local defaults = handlers.defaults(entity, player_index, false)
  if not defaults then return end
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type

  -- apply basic settings (R/W values)
  for index, value in pairs(defaults.basic_entity_settings or {}) do
    entity[index] = value
  end

  if not defaults.entity_settings or not handlers[type].apply_entity_settings then return end
  handlers[type].apply_entity_settings(entity, player_index)
end

handlers.save_circuit_settings = function (entity, player_index)
  local defaults = handlers.defaults(entity, player_index, false)
  if not defaults then return end
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

handlers.apply_circuit_settings = function (entity, player_index)
  local defaults = handlers.defaults(entity, player_index, false)
  if not defaults then return end
  
  -- load relevant circuit settings
  local control_behavior = entity.get_or_create_control_behavior()
  if control_behavior then
    for index, value in pairs(defaults.circuit_settings or {}) do
      log(index)
      control_behavior[index] = value
    end
  end
end

handlers.clear_circuit_settings = function (entity, player_index)
  local defaults = handlers.defaults(entity, player_index, false)
  if not defaults then return end
  local control_behavior = entity.get_or_create_control_behavior(true)
  if control_behavior then
    for index, value in pairs(defaults.circuit_settings or {}) do
      control_behavior[index] = handlers.default_state(index, type) or false
    end
  end
end

-- vanilla settings
handlers.is_default = function (entity)
  local control_behavior = entity.get_or_create_control_behavior()
  local prototype = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  if handlers[prototype] and control_behavior then
    for _, index in pairs(handlers[prototype].circuit_settings or {}) do
      if not handlers.compare(handlers.default_state(index, prototype), control_behavior[index]) then return false end
    end
  end
  return true
end

-- also returns false if no defaults exist
handlers.is_custom_default = function (entity, player_index)
  local defaults = handlers.defaults(entity, player_index, false)
  if not defaults.circuit_settings then return false end
  local control_behavior = entity.get_or_create_control_behavior()
  -- return handlers.compare(defaults.circuit_settings, control_behavior)
  if control_behavior then
    for index, value in pairs(defaults.circuit_settings or {}) do
      if not handlers.compare(value, control_behavior[index]) then return false end
    end
  end
  return true
end

-- default state for circuit settings, if anything is amiss it will be overridden
-- these are exceptions, "true" default is off/false
handlers.default_state = function(index, type)
  if index == "circuit_condition" or index == "logistic_condition" or index == "ignore_unlisted_targets_condition" then
    return {comparator = "<", constant = 0}
  elseif index == "include_in_crafting" or index == "open_gate" then
    return true
  elseif index == "circuit_recipe_finished_signal" or index == "circuit_working_signal" or index == "damage_taken_signal" or index == "circuit_read_resources" then
    return {}
  elseif index == "circuit_exclusive_mode_of_operation" and type == "cargo-landing-pad" then
    return defines.control_behavior.cargo_landing_pad.exclusive_mode.send_contents
  elseif index == "circuit_hand_read_mode" and type == "inserter" then
    return defines.control_behavior.inserter.hand_read_mode.pulse
  elseif index == "color_mode" then
    return defines.control_behavior.lamp.color_mode.color_mapping
  elseif index == "circuit_exclusive_mode_of_operation" and type == "logistic-container" then
    return defines.control_behavior.logistic_container.exclusive_mode.send_contents
  elseif index == "resource_read_mode" then
    return defines.control_behavior.mining_drill.resource_read_mode.this_miner
  elseif index == "circuit_parameters" then
    return -- something to add here aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa for progrmmable speaker
  elseif index == "read_contents_mode" then
    return defines.control_behavior.transport_belt.content_read_mode.pulse
  elseif index == "read_items_mode" then
    return defines.control_behavior.roboport.read_items_mode.logistics
  elseif index == "read_mode" then
    return defines.control_behavior.rocket_silo.read_mode.orbital_requests -- TODO CHECK WITH SA
  elseif index == "speed_signal" then
    return -- CHECK AGAIN ijdoqwe jdijoewjoqjoidjewqojdeoiwqjiodew
  elseif index == "damage_taken_signal" then
    return -- something idk djiewqjiodjeiwqjiodjeiowqjoidjeowiqj
  elseif index == "red_signal" then
    return {type = "virtual", name = "signal-red"}
  elseif index == "orange_signal" then
    return {type = "virtual", name = "signal-yellow"}
  elseif index == "green_signal" then
    return {type = "virtual", name = "signal-green"}
  elseif index == "blue_signal" then
    return {type = "virtual", name = "signal-blue"}
  elseif index == "rgb_signal" then
    return {type = "virtual", name = "signal-white"}
  elseif index == "output_signal" and type == "accumulator" then
    return {type = "virtual", name = "signal-A"}
  elseif index == "trains_count_signal" then
    return {type = "virtual", name = "signal-C"}
  elseif index == "output_signal" and type == "wall" then
    return {type = "virtual", name = "signal-G"}
  elseif index == "trains_limit_signal" then
    return {type = "virtual", name = "signal-L"}
  elseif index == "priority_signal" then
    return {type = "virtual", name = "signal-P"}
  elseif index == "roboport_count_output_signal" then
    return {type = "virtual", name = "signal-R"}
  elseif index == "circuit_stack_control_signal" then
    return {type = "virtual", name = "signal-S"}
  elseif index == "total_construction_output_signal" or index == "stopped_train_signal" or index == "temperature_signal" then
    return {type = "virtual", name = "signal-T"}
  elseif index == "available_logistic_output_signal" then
    return {type = "virtual", name = "signal-X"}
  elseif index == "total_logistic_output_signal" then
    return {type = "virtual", name = "signal-Y"}
  elseif index == "available_construction_output_signal" then
    return {type = "virtual", name = "signal-Z"}
  end
  return false
end

-- handlers["accumulator"] = {}
-- handlers["agricultural-tower"] = {}
-- handlers["ammo-turret"] = {}
-- handlers["artillery-turret"] = {}
-- handlers["assembling-machine"] = {}
-- handlers["asteroid-collector"] = {}
-- handlers["beacon"] = {}
-- handlers["burner-generator"] = {}
handlers["display-panel"] = {
  circuit_settings = {
    "messages"
  }
}
-- handlers["electric-turret"] = {}
-- handlers["fluid-turret"] = {}
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
-- handlers["generator"] = {}
-- handlers["heat-interface"] = {}
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
  apply_entity_settings = function (entity, player_index)
    local defaults = handlers.defaults(entity, player_index)
    -- clear old filters
    for i = 1, entity.filter_slot_count do
      entity.set_filter(i)
    end
    -- set new filters manually, only fills as many as required
    for i = 1, entity.filter_slot_count do
      entity.set_filter(i, defaults.entity_settings.filters[i])
    end
  end,
  save_entity_settings = function (entity, player_index)
    local defaults = handlers.defaults(entity, player_index)
    local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
    defaults.entity_settings = {filters = {}}
    for i = 1, entity.filter_slot_count do
      defaults.entity_settings.filters[i] = entity.get_filter(i)
    end
  end
}
-- handlers["lamp"] = {}
-- handlers["lane-splitter"] = {}
-- handlers["loader"] = {}
-- handlers["loader-1x1"] = {}
-- handlers["logistic-container"] = {}
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
-- handlers["reactor"] = {}
-- handlers["roboport"] = {}
-- handlers["rocket-silo"] = {}
-- handlers["splitter"] = {}
-- handlers["storage-tank"] = {}
-- handlers["train-stop"] = {}
handlers["transport-belt"] = {
  circuit_settings = {
    "circuit_enable_disable",
    "circuit_condition",
    "connect_to_logistic_network",
    "logistic_condition",

    "read_contents",
    "read_contents_mode"
  }
}
-- handlers["turret"] = {}
-- handlers["wall"] = {}

return handlers