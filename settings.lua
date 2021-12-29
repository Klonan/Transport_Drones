local settings =
{
  {
    type = "int-setting",
    name = "transport-depot-update-interval",
    localised_name = "Transport depot update interval",
    setting_type = "runtime-global",
    default_value = 60,
    minimum_value = 1,
    maximum_value = 80085
  },

  {
    type = "string-setting",
    name = "fuel-fluid",
    localised_name = "Transport drone fuel",
    setting_type = "startup",
    allowed_values = {"petroleum-gas", "water", "crude-oil", "heavy-oil", "light-oil", "lubricant", "steam", "sulfuric-acid"},
    default_value = "petroleum-gas"
  },

  {
    type = "double-setting",
    name = "fuel-amount-per-drone",
    localised_name = "Transport drone fuel per drone",
    setting_type = "startup",
    default_value = 50,
    minimum_value = 0,
    maximum_value = 10000
  },

  {
    type = "double-setting",
    name = "drone-fluid-capacity",
    localised_name = "Transport drone fluid capacity",
    setting_type = "startup",
    default_value = 500,
    minimum_value = 1,
    maximum_value = 10000
  },

  {
    type = "double-setting",
    name = "fuel-consumption-per-meter",
    localised_name = "Fuel consumption per meter",
    setting_type = "startup",
    default_value = 0.025,
    minimum_value = 0
  },

  {
    type = "double-setting",
    name = "drone-pollution-per-second",
    localised_name = "Pollution per second",
    setting_type = "startup",
    default_value = 0.005,
    minimum_value = 0
  }
}

data:extend(settings)
