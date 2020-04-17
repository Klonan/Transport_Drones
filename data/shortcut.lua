data:extend(
  {
    {
      type = "shortcut",
      name = "transport-drones-gui",
      localised_name = {"controls.toggle-road-network-gui"},
      order = "a[transport-drones]",
      action = "lua",
      technology_to_unlock = shared.transport_system_technology,
      style = "default",
      icon = {
        filename = util.path("data/entities/transport_drone/transport-drone-icon.png"),
        priority = "extra-high-no-scale",
        size = 113,
        scale = 1,
        flags = {"icon"},
      },
      small_icon = {
        filename = util.path("data/entities/transport_drone/transport-drone-icon.png"),
        priority = "extra-high-no-scale",
        size = 113,
        scale = 1,
        flags = {"icon"},
      },
      disabled_small_icon = {
        filename = util.path("data/entities/transport_drone/transport-drone-icon.png"),
        priority = "extra-high-no-scale",
        size = 113,
        scale = 1,
        flags = {"icon"},
      },
    }
  }
)