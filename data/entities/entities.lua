local require = function(name) return require("data/entities/"..name) end

require("transport_depot/transport_depot")
require("transport_depot_circuits/transport_depot_circuits")



local name = "transport-drone"

local item =
{
  type = "item",
  name = name,
  localised_name = {name},
  icon = util.path("data/entities/transport_drone/transport-drone-icon.png"),
  icon_size = 112,
  flags = {},
  subgroup = "transport-drones",
  order = "e-"..name,
  stack_size = 10,
  --place_result = name
}

local recipe =
{
  type = "recipe",
  name = name,
  localised_name = {name},
  --category = "transport",
  enabled = false,
  ingredients =
  {
    {"engine-unit", 1},
    {"steel-plate", 5},
    {"iron-gear-wheel", 5},
  },
  energy_required = 2,
  result = name
}

data:extend{item, recipe}
