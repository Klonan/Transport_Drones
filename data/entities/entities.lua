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
    {type = "item",name = "engine-unit",amount = 1},
    {type = "item",name = "steel-plate",amount = 5},
    {type = "item",name = "iron-gear-wheel", amount = 5},
  },
  energy_required = 2,
  results = {
    {type="item",name=name,amount=1}
  }
}

data:extend{item, recipe}
