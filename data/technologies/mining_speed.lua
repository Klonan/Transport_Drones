local name = shared.mining_speed_technology

local levels =
{
  [1] =
  {
    {"automation-science-pack", 1},
  },
  [2] =
  {
    {"automation-science-pack", 1},
    {"logistic-science-pack", 1},
  },
  [3] =
  {
    {"automation-science-pack", 1},
    {"logistic-science-pack", 1},
    {"chemical-science-pack", 1},
  },
  [4] =
  {
    {"automation-science-pack", 1},
    {"logistic-science-pack", 1},
    {"chemical-science-pack", 1},
    {"production-science-pack", 1},
  },
  [5] =
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
    icon = util.path("data/technologies/mining-speed-icon.png"),
    icon_size = 216,
    upgrade = true,
    effects =
    {
      {
        type = "nothing",
        effect_description = "Mining drone mining speed: +20%"--repair-turret-power-description"}
      },
      {
        type = "nothing",
        effect_description = "Mining drone walking speed: +20%"--repair-turret-power-description"}
      },
      {
        type = "nothing",
        effect_description = "Mining drone cargo bonus: +1"--repair-turret-power-description"}
      },
    },
    prerequisites = k > 1 and {name.."-"..k - 1} or {},
    unit =
    {
      count = k * 100,
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
  icon = util.path("data/technologies/mining-speed-icon.png"),
  icon_size = 216,
  upgrade = true,
  effects =
  {
    {
      type = "nothing",
      effect_description = "Mining drone mining speed: +20%"
    },
    {
      type = "nothing",
      effect_description = "Mining drone walking speed: +20%"
    },
    {
      type = "nothing",
      effect_description = "Mining drone cargo bonus: +1"
    },
  },
  prerequisites = k > 1 and {name.."-"..k - 1} or {},
  unit =
  {
    count_formula = "(2^(L-6))*500",
    ingredients =
    {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
      {"chemical-science-pack", 1},
      {"production-science-pack", 1},
      {"utility-science-pack", 1},
      {"space-science-pack", 1},
    },
    time = 30
  },
  order = name,
  max_level = "infinite"
}
data:extend{infinite}