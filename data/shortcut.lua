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
      icon = util.path("data/entities/transport_drone/transport-drone-icon.png"),
      icon_size = 113,
      small_icon = util.path("data/entities/transport_drone/transport-drone-icon.png"),
      small_icon_size = 113
    }
  }
)