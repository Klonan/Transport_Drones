if true then return end

data:extend({
  {
    type = "bool-setting",
    name = "ignore_rocks",
    setting_type = "startup",
    localised_name = "Ignore rocks",
    default_value = false
  },
  {
    type = "bool-setting",
    name = "mute_drones",
    setting_type = "startup",
    localised_name = "Mute drone sounds",
    default_value = false
  },
})
