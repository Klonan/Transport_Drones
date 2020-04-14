local setting =
  {
    type = "int-setting",
    name = "transport-depot-update-interval",
    localised_name = "Transport depot update interval",
    setting_type = "runtime-global",
    default_value = 60,
    minimum_value = 1,
    maximum_value = 80085
  }

data:extend{setting}