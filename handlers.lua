---@diagnostic disable: no-unknown
---@diagnostic disable-next-line: undefined-global
local handlers = handlers or {}

-- deep compare for equality, works for any data type
handlers.equal = function (data1, data2)
  if type(data1) ~= type(data2) or type(data1) ~= "table" and data1 ~= data2 then
    return false
  elseif type(data1) == "table" then
    local checked_indices = {fulfilled = true}
    for index, data in pairs(data1) do
      if not checked_indices[index] and not handlers.equal(data, data2[index]) then return false end
      checked_indices[index] = true
    end
    for index, data in pairs(data2) do
      if not checked_indices[index] and not handlers.equal(data, data1[index]) then return false end
    end
  end
  return true
end

handlers.defaults = function (entity, player_index)
  local name = entity.type == "entity-ghost" and entity.ghost_name or entity.name
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type

  if not handlers[type] then return {} end

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

  local metadata = storage.player_settings[player_index]

  if not metadata[type] then
    metadata[type] = {}
  end

  if not metadata.individual[name] then
    metadata.individual[name] = {individual = false}
  end

  return metadata.individual[name].individual and metadata.individual[name] or metadata[type]
end

handlers.enable_individual_settings = function (entity, player_index)
  storage.player_settings[player_index].individual[entity.type == "entity-ghost" and entity.ghost_name or entity.name].individual = true
end

handlers.disable_individual_settings = function (entity, player_index)
  storage.player_settings[player_index].individual[entity.type == "entity-ghost" and entity.ghost_name or entity.name].individual = false
end

handlers.save_entity_settings = function (entity, player_index)
  local defaults = handlers.defaults(entity, player_index)
  if not defaults then return end
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  defaults.basic_entity_settings = {}
  -- save basic settings (R/W values)
  for index in pairs(handlers[type].basic_entity_settings or {}) do
    defaults.basic_entity_settings[index] = entity[index]
  end
  if not handlers[type].save_entity_settings then return end
  handlers[type].save_entity_settings(entity, player_index)
end

handlers.apply_entity_settings = function (entity, player_index)
  local defaults = handlers.defaults(entity, player_index)
  if not defaults then return end
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  -- apply basic settings (R/W values)
  for index, value in pairs(defaults.basic_entity_settings or {}) do
    entity[index] = handlers.get_nan_eq(value)
  end
  if not defaults.entity_settings or not handlers[type].apply_entity_settings then return end
  handlers[type].apply_entity_settings(entity, player_index)
end

handlers.delete_entity_settings = function (entity, player_index)
  local defaults = handlers.defaults(entity, player_index)
  if not defaults then return end
  defaults.basic_entity_settings = nil
  defaults.entity_settings = nil
end

handlers.clear_entity_settings = function (entity)
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  if not handlers[type] then return end
  for index, value in pairs(handlers[type].basic_entity_settings or {}) do
    entity[index] = handlers.get_nan_eq(value)
  end
  if not handlers[type].clear_entity_settings then return end
  handlers[type].clear_entity_settings(entity)
end

-- vanilla settings
handlers.is_default = function (entity)
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  if not handlers[type] then return false end
  -- save basic settings (R/W values)
  for index, value in pairs(handlers[type].basic_entity_settings or {}) do
    if not handlers.equal(handlers.get_nan_eq(value), entity[index]) then return false end
  end
  return handlers[type].is_default and handlers[type].is_default(entity) or true
end

handlers.get_entity_parameters = function (entity)
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  if not handlers[type] or not handlers[type].get_entity_parameters then return {} end
  return handlers[type].get_entity_parameters(entity) or {}
end

handlers.set_entity_parameters = function (entity, parameters)
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  if not handlers[type] or not handlers[type].set_entity_parameters then return end
  handlers[type].set_entity_parameters(entity, parameters)
end

handlers.save_circuit_settings = function (entity, player_index)
  local defaults = handlers.defaults(entity, player_index)
  if not defaults then return end
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  defaults.circuit_settings = {}
  -- load relevant circuit settings
  local control_behavior = entity.get_or_create_control_behavior()
  if control_behavior then
    for index in pairs(handlers[type].circuit_settings or {}) do
      defaults.circuit_settings[index] = control_behavior[index]
    end
  end
end

handlers.apply_circuit_settings = function (entity, player_index)
  local defaults = handlers.defaults(entity, player_index)
  if not defaults then return end
  -- load relevant circuit settings
  local control_behavior = entity.get_or_create_control_behavior()
  if control_behavior then
    for index, value in pairs(defaults.circuit_settings or {}) do
      control_behavior[index] = handlers.get_nan_eq(value)
    end
  end
end

handlers.delete_circuit_settings = function (entity, player_index)
  local defaults = handlers.defaults(entity, player_index)
  if not defaults then return end
  defaults.circuit_settings = nil
end

handlers.clear_circuit_settings = function (entity)
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  local control_behavior = entity.get_or_create_control_behavior(true)
  if not handlers[type] or not control_behavior then return end
  for index, value in pairs(handlers[type].circuit_settings or {}) do
    control_behavior[index] = handlers.get_nan_eq(value)
  end
end

-- vanilla circuit settings
handlers.is_circuit_default = function (entity)
  local control_behavior = entity.get_or_create_control_behavior()
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  if handlers[type] and control_behavior then
    for index, value in pairs(handlers[type].circuit_settings or {}) do
      if not handlers.equal(handlers.get_nan_eq(value), control_behavior[index]) then return false end
    end
  end
  return true
end

handlers.get_circuit_parameters = function (entity)
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  if not handlers[type] or not handlers[type].get_circuit_parameters then return end
  return handlers[type].get_circuit_parameters(entity)
end

handlers.set_circuit_parameters = function (entity, parameters)
  local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
  if not handlers[type] or not handlers[type].set_circuit_parameters then return end
  handlers[type].set_circuit_parameters(entity, parameters)
end

-- also returns false if no defaults exist (circuit settings)
handlers.is_circuit_custom_default = function (entity, player_index)
  local defaults = handlers.defaults(entity, player_index)
  if not defaults.circuit_settings then return false end
  local control_behavior = entity.get_or_create_control_behavior()
  if control_behavior then
    for index, value in pairs(defaults.circuit_settings or {}) do
      if not handlers.equal(handlers.get_nan_eq(value), control_behavior[index]) then return false end
    end
  end
  return true
end

local nan = "1GTTkEMVwZiJ7O30Bt3s" -- noncompare string for entries that exist, but are default nil
handlers.get_nan_eq = function(input)
  return input ~= nan and input or nil
end

local comparators = {
  nil,
  ">",
  "<",
  "=",
  "≥",
  "≤",
  "≠"
}

handlers["accumulator"] = {
  circuit_settings = {
    read_charge = true,
    output_signal = {type = "virtual", name = "signal-A"}
  }
}
handlers["agricultural-tower"] = {
  circuit_settings = {
    circuit_enable_disable = false,
    circuit_condition = {comparator = "<", constant = 0},
    connect_to_logistic_network = false,
    logistic_condition = {comparator = "<", constant = 0},

    read_contents = false
  },
}
handlers["ammo-turret"] = {
  circuit_settings = {
    circuit_enable_disable = false,
    circuit_condition = {comparator = "<", constant = 0},
    connect_to_logistic_network = false,
    logistic_condition = {comparator = "<", constant = 0},

    set_priority_list = false,
    set_ignore_unlisted_targets = false,
    ignore_unlisted_targets_condition = {comparator = "<", constant = 0},
    read_ammo = false
  },
  basic_entity_settings = {
    ignore_unprioritised_targets = false
  },
  save_entity_settings = function (entity, player_index)
    local defaults = handlers.defaults(entity, player_index)
    defaults.entity_settings = {priorities = {}}
    for i, target in pairs(entity.priority_targets) do
      defaults.entity_settings.priorities[i] = target.name
    end
  end,
  apply_entity_settings = function (entity, player_index)
    local defaults = handlers.defaults(entity, player_index)
    -- clear old priorities
    for _ = 1, #entity.priority_targets do
      entity.set_priority_target(1)
    end
    -- set new filters manually, only fills as many as required
    for i, target in pairs(defaults.entity_settings.priorities) do
      entity.set_priority_target(i, target)
    end
  end,
  clear_entity_settings = function (entity)
    for _ = 1, #entity.priority_targets do
      entity.set_priority_target(1)
    end
  end,
  is_default = function (entity)
    return #entity.priority_targets == 0
  end
}
handlers["artillery-turret"] = {
  circuit_settings = {
    circuit_enable_disable = false,
    circuit_condition = {comparator = "<", constant = 0},
    connect_to_logistic_network = false,
    logistic_condition = {comparator = "<", constant = 0},

    read_ammo = false
  },
  basic_entity_settings = {
    artillery_auto_targeting = true
  }
}
handlers["assembling-machine"] = {
  circuit_settings = {
    circuit_enable_disable = false,
    circuit_condition = {comparator = "<", constant = 0},
    connect_to_logistic_network = false,
    logistic_condition = {comparator = "<", constant = 0},

    circuit_set_recipe = false,
    circuit_read_contents = false,
    include_in_crafting = true,
    include_fuel = false,
    circuit_read_ingredients = false,
    circuit_read_recipe_finished = false,
    circuit_recipe_finished_signal = nan,
    circuit_read_working = false,
    circuit_working_signal = nan
  },
  save_entity_settings = function (entity, player_index)
    local defaults = handlers.defaults(entity, player_index)
    local recipe, quality = entity.get_recipe()
    defaults.entity_settings = {recipe = recipe, quality = quality}
  end,
  apply_entity_settings = function (entity, player_index)
    local defaults = handlers.defaults(entity, player_index)
    -- clear old priorities
    entity.set_recipe(defaults.entity_settings.recipe, defaults.entity_settings.quality)
  end,
  clear_entity_settings = function (entity)
    entity.set_recipe()
  end,
  is_default = function (entity)
    return not entity.get_recipe()
  end,
  get_entity_parameters = function (entity)
    local recipe = entity.get_recipe()
    if recipe and recipe.has_category("parameters") then
      return {[recipe.name:sub(10) + 0] = {name = recipe.name, type = script.feature_flags.quality and "recipe-with-quality" or "recipe"}}
    end
  end,
  set_entity_parameters = function (entity, parameters)
    local _, data = next(parameters)
    entity.set_recipe(data.name, data.quality)
  end
}
handlers["asteroid-collector"] = {
  circuit_settings = {
    circuit_enable_disable = false,
    circuit_condition = {comparator = "<", constant = 0},
    connect_to_logistic_network = false,
    logistic_condition = {comparator = "<", constant = 0},

    set_filter = false,
    read_contents = false,
    include_hands = true
  },
  save_entity_settings = function (entity, player_index)
    local defaults = handlers.defaults(entity, player_index)
    defaults.entity_settings = {filters = {}}
    for i = 1, entity.filter_slot_count do
      defaults.entity_settings.filters[i] = entity.get_filter(i)
    end
  end,
  apply_entity_settings = function (entity, player_index)
    local defaults = handlers.defaults(entity, player_index)
    -- clear old filters
    for _ = 1, entity.filter_slot_count do
      entity.set_filter(1)
    end
    -- set new filters manually, only fills as many as required
    for i = 1, #defaults.entity_settings.filters do
      entity.set_filter(i, defaults.entity_settings.filters[i])
    end
  end,
  clear_entity_settings = function (entity)
    for _ = 1, entity.filter_slot_count do
      entity.set_filter(1)
    end
  end,
  is_default = function (entity)
    for i = 1, entity.filter_slot_count do
      if entity.get_filter(i) then return false end
    end
    return true
  end,
  get_entity_parameters = function (entity)
    local parameters = {}
    for i = 1, entity.filter_slot_count do
      local filter = entity.get_filter(i)
      if filter and filter.name:sub(1, 10) == "parameter-" then
        parameters[tonumber(filter.name:sub(10))] = {
          name = filter.name,
          type = "asteroid-chunk"
        }
      end
    end
    return parameters
  end,
  set_entity_parameters = function (entity, parameters)
    for i = 1, entity.filter_slot_count do
      local filter = entity.get_filter(i)
      if filter and filter.name:sub(1, 10) == "parameter-" then
        entity.set_filter(i, parameters[filter.name].name)
      end
    end
  end
}
-- handlers["display-panel"] = {
--   circuit_settings = {
--     "messages"
--   }
-- }
handlers["electric-turret"] = {
  circuit_settings = {
    circuit_enable_disable = false,
    circuit_condition = {comparator = "<", constant = 0},
    connect_to_logistic_network = false,
    logistic_condition = {comparator = "<", constant = 0},

    set_priority_list = false,
    set_ignore_unlisted_targets = false,
    ignore_unlisted_targets_condition = {comparator = "<", constant = 0}
  },
  basic_entity_settings = {
    ignore_unprioritised_targets = false
  },
  save_entity_settings = function (entity, player_index)
    local defaults = handlers.defaults(entity, player_index)
    defaults.entity_settings = {priorities = {}}
    for i, target in pairs(entity.priority_targets) do
      defaults.entity_settings.priorities[i] = target.name
    end
  end,
  apply_entity_settings = function (entity, player_index)
    local defaults = handlers.defaults(entity, player_index)
    -- clear old priorities
    for _ = 1, #entity.priority_targets do
      entity.set_priority_target(1)
    end
    -- set new filters manually, only fills as many as required
    for i, target in pairs(defaults.entity_settings.priorities) do
      entity.set_priority_target(i, target)
    end
  end,
  clear_entity_settings = function (entity)
    for _ = 1, #entity.priority_targets do
      entity.set_priority_target(1)
    end
  end,
  is_default = function (entity)
    return #entity.priority_targets == 0
  end
}
handlers["fluid-turret"] = {
  circuit_settings = {
    circuit_enable_disable = false,
    circuit_condition = {comparator = "<", constant = 0},
    connect_to_logistic_network = false,
    logistic_condition = {comparator = "<", constant = 0},

    set_priority_list = false,
    set_ignore_unlisted_targets = false,
    ignore_unlisted_targets_condition = {comparator = "<", constant = 0},
    read_ammo = false
  },
  basic_entity_settings = {
    ignore_unprioritised_targets = false
  },
  save_entity_settings = function (entity, player_index)
    local defaults = handlers.defaults(entity, player_index)
    defaults.entity_settings = {priorities = {}}
    for i, target in pairs(entity.priority_targets) do
      defaults.entity_settings.priorities[i] = target.name
    end
  end,
  apply_entity_settings = function (entity, player_index)
    local defaults = handlers.defaults(entity, player_index)
    -- clear old priorities
    for _ = 1, #entity.priority_targets do
      entity.set_priority_target(1)
    end
    -- set new filters manually, only fills as many as required
    for i, target in pairs(defaults.entity_settings.priorities) do
      entity.set_priority_target(i, target)
    end
  end,
  clear_entity_settings = function (entity)
    for _ = 1, #entity.priority_targets do
      entity.set_priority_target(1)
    end
  end,
  is_default = function (entity)
    return #entity.priority_targets == 0
  end
}
handlers["furnace"] = {
  circuit_settings = {
    circuit_enable_disable = false,
    circuit_condition = {comparator = "<", constant = 0},
    connect_to_logistic_network = false,
    logistic_condition = {comparator = "<", constant = 0},

    circuit_read_contents = false,
    include_in_crafting = true,
    include_fuel = false,
    circuit_read_ingredients = false,
    circuit_read_recipe_finished = false,
    circuit_recipe_finished_signal = nan,
    circuit_read_working = false,
    circuit_working_signal = nan
  }
}
handlers["inserter"] = {
  circuit_settings = {
    circuit_enable_disable = false,
    circuit_condition = {comparator = "<", constant = 0},
    connect_to_logistic_network = false,
    logistic_condition = {comparator = "<", constant = 0},

    circuit_set_filters = false,
    circuit_read_hand_contents = false,
    circuit_hand_read_mode = defines.control_behavior.inserter.hand_read_mode.pulse,
    circuit_set_stack_size = false,
    circuit_stack_control_signal = {type = "virtual", name = "signal-S"}
  },
  basic_entity_settings = {
    use_filters = false,
    inserter_stack_size_override = 0,
    inserter_filter_mode = "whitelist",
    inserter_spoil_priority = "none"
  },
  save_entity_settings = function (entity, player_index)
    local defaults = handlers.defaults(entity, player_index)
    defaults.entity_settings = {filters = {}}
    for i = 1, entity.filter_slot_count do
      defaults.entity_settings.filters[i] = entity.get_filter(i)
    end
  end,
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
  clear_entity_settings = function (entity)
    for i = 1, entity.filter_slot_count do
      entity.set_filter(i)
    end
  end,
  is_default = function (entity)
    for i = 1, entity.filter_slot_count do
      if entity.get_filter(i) then return false end
    end
    return true
  end,
  get_entity_parameters = function (entity)
    local parameters = {}
    for i = 1, entity.filter_slot_count do
      local filter = entity.get_filter(i)
      if filter and filter.name:sub(1, 10) == "parameter-" then
        parameters[tonumber(filter.name:sub(10))] = {
          name = filter.name,
          type = script.feature_flags.quality and "item-with-quality" or "item"
        }
      end
    end
    return parameters
  end,
  set_entity_parameters = function (entity, parameters)
    for i = 1, entity.filter_slot_count do
      local filter = entity.get_filter(i)
      if filter and filter.name:sub(1, 10) == "parameter-" then
        local comparator = comparators[parameters[filter.name].comparator or 0]
        entity.set_filter(i, {
          name = parameters[filter.name].name,
          quality = comparator and parameters[filter.name].quality or nil,
          comparator = comparator
        })
      end
    end
  end
}
handlers["lamp"] = {
  circuit_settings = {
    circuit_enable_disable = false,
    circuit_condition = {comparator = "<", constant = 0},
    connect_to_logistic_network = false,
    logistic_condition = {comparator = "<", constant = 0},

    use_colors = false,
    color_mode = defines.control_behavior.lamp.color_mode.color_mapping,
    red_signal = {type = "virtual", name = "signal-red"},
    green_signal = {type = "virtual", name = "signal-green"},
    blue_signal = {type = "virtual", name = "signal-blue"},
    rgb_signal = {type = "virtual", name = "signal-white"}
  },
  basic_entity_settings = {
    color = {255, 255, 191},
    always_on = false
  }
}
handlers["loader"] = {
  circuit_settings = {
    circuit_enable_disable = false,
    circuit_condition = {comparator = "<", constant = 0},
    connect_to_logistic_network = false,
    logistic_condition = {comparator = "<", constant = 0},

    circuit_set_filters = false,
    circuit_read_transfers = false
  },
  basic_entity_settings = {
    loader_filter_mode = "none",
    loader_belt_stack_size_override = 0
  },
  save_entity_settings = function (entity, player_index)
    local defaults = handlers.defaults(entity, player_index)
    defaults.entity_settings = {filters = {}}
    for i = 1, entity.filter_slot_count do
      defaults.entity_settings.filters[i] = entity.get_filter(i)
    end
  end,
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
  clear_entity_settings = function (entity)
    for i = 1, entity.filter_slot_count do
      entity.set_filter(i)
    end
  end,
  is_default = function (entity)
    for i = 1, entity.filter_slot_count do
      if entity.get_filter(i) then return false end
    end
    return true
  end
}
handlers["loader-1x1"] = handlers["loader"]
-- handlers["logistic-container"] = {
--   circuit_settings = {
--     circuit_exclusive_mode_of_operation,
--     circuit_condition_enabled = false,
--     circuit_condition = {comparator = "<", constant = 0}
--   }
-- }
handlers["mining-drill"] = {
  circuit_settings = {
    circuit_enable_disable = false,
    circuit_condition = {comparator = "<", constant = 0},
    connect_to_logistic_network = false,
    logistic_condition = {comparator = "<", constant = 0},

    circuit_read_resources = true,
    resource_read_mode = defines.control_behavior.mining_drill.resource_read_mode.this_miner
  },
  basic_entity_settings = {
    mining_drill_filter_mode = "whitelist",
  },
  save_entity_settings = function (entity, player_index)
    local defaults = handlers.defaults(entity, player_index)
    defaults.entity_settings = {filters = {}}
    for i = 1, entity.filter_slot_count do
      defaults.entity_settings.filters[i] = entity.get_filter(i)
    end
  end,
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
  clear_entity_settings = function (entity)
    for i = 1, entity.filter_slot_count do
      entity.set_filter(i)
    end
  end,
  is_default = function (entity)
    for i = 1, entity.filter_slot_count do
      if entity.get_filter(i) then return false end
    end
    return true
  end
}
handlers["offshore-pump"] = {
  circuit_settings = {
    circuit_enable_disable = false,
    circuit_condition = {comparator = "<", constant = 0},
    connect_to_logistic_network = false,
    logistic_condition = {comparator = "<", constant = 0}
  }
}
handlers["power-switch"] = {
  circuit_settings = {
    circuit_enable_disable = false,
    circuit_condition = {comparator = "<", constant = 0},
    connect_to_logistic_network = false,
    logistic_condition = {comparator = "<", constant = 0}
  },
  basic_entity_settings = {
    power_switch_state = false
  }
}
handlers["programmable-speaker"] = {
  -- circuit_settings = {
  --   circuit_condition = {comparator = "<", constant = 0},
  --   circuit_parameters = 
  -- },
  basic_entity_settings = {
    parameters = {
      allow_polyphony = false,
      playback_mode = "local",
      playback_volume = 1,
      volume_controlled_by_signal = false
    },
    alert_parameters = {
      alert_message = "",
      show_alert = false,
      show_on_map = true
    }
  }
}
handlers["pump"] = {
  circuit_settings = {
    circuit_enable_disable = false,
    circuit_condition = {comparator = "<", constant = 0},
    connect_to_logistic_network = false,
    logistic_condition = {comparator = "<", constant = 0},

    set_filter = false
  }
}
handlers["reactor"] = {
  circuit_settings = {
    read_fuel = false,
    read_temperature = false,
    temperature_signal = {type = "virtual", name = "signal-T"}
  }
}
handlers["roboport"] = {
  circuit_settings = {
    read_items_mode = defines.control_behavior.roboport.read_items_mode.logistics,
    read_robot_stats = false,
    available_logistic_output_signal = {type = "virtual", name = "signal-X"},
    total_logistic_output_signal = {type = "virtual", name = "signal-Y"},
    available_construction_output_signal = {type = "virtual", name = "signal-Z"},
    total_construction_output_signal = {type = "virtual", name = "signal-T"},
    roboport_count_output_signal = {type = "virtual", name = "signal-R"}
  }
}
handlers["rocket-silo"] = {
  circuit_settings = {
    read_mode = defines.control_behavior.rocket_silo.read_mode.logistic_inventory
  },
  basic_entity_settings = {
    send_to_orbit_automatically = false,
    use_transitional_requests = false
  }
}
handlers["splitter"] = {
  circuit_settings = {
    set_input_side = false,
    input_left_condition = {first_signal = {type = "virtual", name = "signal-I"}, comparator = "<", constant = 0},
    input_right_condition = {first_signal = {type = "virtual", name = "signal-I"}, comparator = ">", constant = 0},
    set_output_side = false,
    output_left_condition = {first_signal = {type = "virtual", name = "signal-O"}, comparator = "<", constant = 0},
    output_right_condition = {first_signal = {type = "virtual", name = "signal-O"}, comparator = ">", constant = 0},
    set_filter = false
  },
  basic_entity_settings = {
    splitter_filter = {},
    splitter_input_priority = "none",
    splitter_output_priority = "none",
  }
}
handlers["lane-splitter"] = handlers["splitter"]
handlers["storage-tank"] = {
  circuit_settings = {
    read_contents = true
  }
}
handlers["train-stop"] = {
  circuit_settings = {
    circuit_enable_disable = false,
    circuit_condition = {comparator = "<", constant = 0},
    connect_to_logistic_network = false,
    logistic_condition = {comparator = "<", constant = 0},

    send_to_train = true,
    set_trains_limit = false,
    trains_limit_signal = {type = "virtual", name = "signal-L"},
    read_from_train = false,
    read_stopped_train = false,
    stopped_train_signal = {type = "virtual", name = "signal-T"},
    read_trains_count = false,
    trains_count_signal = {type = "virtual", name = "signal-C"},
    set_priority = false,
    priority_signal = {type = "virtual", name = "signal-P"}
  },
  basic_entity_settings = {
    color = nan,
    trains_limit = nan,
    train_stop_priority = 50
  }
}
handlers["transport-belt"] = {
  circuit_settings = {
    circuit_enable_disable = false,
    circuit_condition = {comparator = "<", constant = 0},
    connect_to_logistic_network = false,
    logistic_condition = {comparator = "<", constant = 0},

    read_contents = false,
    read_contents_mode = defines.control_behavior.transport_belt.content_read_mode.pulse
  }
}
handlers["turret"] = {
  circuit_settings = {
    circuit_enable_disable = false,
    circuit_condition = {comparator = "<", constant = 0},
    connect_to_logistic_network = false,
    logistic_condition = {comparator = "<", constant = 0},

    set_priority_list = false,
    set_ignore_unlisted_targets = false,
    ignore_unlisted_targets_condition = {comparator = "<", constant = 0}
  },
  basic_entity_settings = {
    ignore_unprioritised_targets = false
  },
  save_entity_settings = function (entity, player_index)
    local defaults = handlers.defaults(entity, player_index)
    defaults.entity_settings = {priorities = {}}
    for i, target in pairs(entity.priority_targets) do
      defaults.entity_settings.priorities[i] = target.name
    end
  end,
  apply_entity_settings = function (entity, player_index)
    local defaults = handlers.defaults(entity, player_index)
    -- clear old priorities
    for _ = 1, #entity.priority_targets do
      entity.set_priority_target(1)
    end
    -- set new filters manually, only fills as many as required
    for i, target in pairs(defaults.entity_settings.priorities) do
      entity.set_priority_target(i, target)
    end
  end,
  clear_entity_settings = function (entity)
    for _ = 1, #entity.priority_targets do
      entity.set_priority_target(1)
    end
  end,
  is_default = function (entity)
    return #entity.priority_targets == 0
  end
}
handlers["wall"] = {
  circuit_settings = {
    open_gate = true,
    circuit_condition = {comparator = "<", constant = 0},
    read_sensor = false,
    output_signal = {type = "virtual", name = "signal-G"}
  }
}

return handlers