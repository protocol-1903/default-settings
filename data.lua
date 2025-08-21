data:extend{
  {
    type = "sprite",
    name = "ds-settings-save",
    filename = "__base__/graphics/icons/arrows/signal-input.png",
    size = 64
  },
  {
    type = "sprite",
    name = "ds-settings-load",
    filename = "__base__/graphics/icons/arrows/signal-output.png",
    size = 64
  },
  {
    type = "sprite",
    name = "ds-settings-delete",
    filename = "__base__/graphics/icons/signal/signal-trash-bin.png",
    size = 64
  },
  {
    type = "custom-input",
    name = "default-settings-build",
    linked_game_control = "build",
    key_sequence = ""
  },
  {
    type = "simple-entity-with-owner",
    name = "default-settings-trigger-entity",
    icon = util.empty_icon().icon
  },
  {
    type = "shortcut",
    name = "default-settings-show-gui",
    icon = "__default-settings__/icons/shortcut.png",
    icon_size = 32,
    small_icon = "__default-settings__/icons/shortcut.png",
    small_icon_size = 32,
    action = "lua",
    toggleable = true
  }
}

data.raw["gui-style"].default["ds_action_button"] = {
    type = "button_style",
    parent = "frame_button",
    size = 40
}