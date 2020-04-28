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

local fuel_fluid = 
  {
      type = "string-setting",
      name = "fuel-fluid",
      localised_name = "Transport drone fuel",
      setting_type = "startup",
      default_value = "petroleum-gas"
  }

data:extend{fuel_fluid}

local fuel_amount_per_drone = 
  {
      type = "int-setting",
      name = "fuel-amount-per-drone",
      localised_name = "Transport drone fuel per drone",
      setting_type = "startup",
      default_value = 50,
      minimum_value = 1,
      maximum_value = 10000
  }

data:extend{fuel_amount_per_drone}

local drone_fluid_capacity = 
  {
      type = "int-setting",
      name = "drone-fluid-capacity",
      localised_name = "Transport drone fluid capacity",
      setting_type = "startup",
      default_value = 500,
      minimum_value = 1,
      maximum_value = 10000
  }

data:extend{drone_fluid_capacity}

local fuel_consumption_per_meter = 
  {
      type = "double-setting",
      name = "fuel-consumption-per-meter",
      localised_name = "Fuel consumption per meter",
      setting_type = "startup",
      default_value = 0.0181818,
      minimum_value = 0
  }

data:extend{fuel_consumption_per_meter}

local drone_pollution_per_second = 
  {
      type = "double-setting",
      name = "drone-pollution-per-second",
      localised_name = "Pollution per second",
      setting_type = "startup",
      default_value = 0.005,
      minimum_value = 0
  }

data:extend{drone_pollution_per_second}