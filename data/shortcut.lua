data:extend(
{
  {
    type = 'shortcut',
    name = 'transport-drones-gui',
    localised_name = 'transport-drones-gui',
    order = "a[transport-drones]",
    action = 'lua',
    technology_to_unlock = shared.transport_system_technology,
    style = 'default',
    icon = {
      filename = util.path('data/shortcut/grid-x32-white.png'),
      priority = 'extra-high-no-scale',
      size = 32,
      scale = 1,
      flags = {'icon'},
    },
    small_icon = {
      filename = util.path('data/shortcut/grid-x24.png'),
      priority = 'extra-high-no-scale',
      size = 24,
      scale = 1,
      flags = {'icon'},
    },
    disabled_small_icon = {
      filename = util.path('data/shortcut/grid-x24-white.png'),
      priority = 'extra-high-no-scale',
      size = 24,
      scale = 1,
      flags = {'icon'},
    },
  },
})

