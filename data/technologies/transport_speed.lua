local shared = require("shared")
local name = shared.transport_speed_technology

local levels =
{
  [1] =
  {
    {"automation-science-pack", 1},
    {"logistic-science-pack", 1},
  },
  [2] =
  {
    {"automation-science-pack", 1},
    {"logistic-science-pack", 1},
    {"chemical-science-pack", 1},
  },
  [3] =
  {
    {"automation-science-pack", 1},
    {"logistic-science-pack", 1},
    {"chemical-science-pack", 1},
    {"production-science-pack", 1},
  },
  [4] =
  {
    {"automation-science-pack", 1},
    {"logistic-science-pack", 1},
    {"chemical-science-pack", 1},
    {"production-science-pack", 1},
    {"utility-science-pack", 1},
  }
}

for k, ingredients in pairs (levels) do

  local technology =
  {
    name = name.."-"..k,
    localised_name = {name},
    type = "technology",
    icon = util.path("data/technologies/transport-speed-icon.png"),
    icon_size = 128,
    upgrade = true,
    effects =
    {
      {
        type = "nothing",
        effect_description = {"effect-description."..name}
      }
    },
    prerequisites = k > 1 and {name.."-"..k - 1} or {"transport-system"},
    unit =
    {
      count = k * 200,
      ingredients = ingredients,
      time = 30
    },
    order = name
  }
  data:extend{technology}
end


local k = #levels + 1

local infinite =
{
  name = name.."-"..k,
  localised_name = {name},
  type = "technology",
  icon = util.path("data/technologies/transport-speed-icon.png"),
  icon_size = 128,
  upgrade = true,
  effects =
  {
    {
      type = "nothing",
      effect_description = {"effect-description."..name}
    }
  },
  prerequisites = k > 1 and {name.."-"..k - 1} or {},
  unit =
  {
    count_formula = "(2^(L-5))*500",
    ingredients =
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"space-science-pack", 1},
    },
    time = 60
  },
  order = name,
  max_level = "infinite"
}
data:extend{infinite}