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
  }
}

data.raw["gui-style"].default["ds_action_button"] = {
    type = "button_style",
    parent = "frame_button",
    size = 40
}