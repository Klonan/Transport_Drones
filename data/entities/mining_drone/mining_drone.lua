local path = util.path("data/units/smg_guy/")
local name = names.drone_name


local make_drone = require("data/entities/mining_drone/mining_drone_entity")

make_drone(name, {r = 1, g = 1, b = 1, a = 0.5}, "base")

local base = util.copy(data.raw.character.character)

local item = {
  type = "item",
  name = name,
  localised_name = {name},
  icon = base.icon,
  icon_size = base.icon_size,
  flags = {},
  subgroup = "extraction-machine",
  order = "zb"..name,
  stack_size = 20,
  --place_result = name
}

local recipe = {
  type = "recipe",
  name = name,
  localised_name = {name},
  --category = ,
  enabled = true,
  ingredients =
  {
    {"iron-plate", 10},
    {"iron-gear-wheel", 5},
    {"iron-stick", 10}
  },
  energy_required = 2,
  result = name
}

data:extend
{
  item,
  recipe
}
