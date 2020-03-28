local category = "transport-drone-request"
local util = require("tf_util/tf_util")
local shared = require("shared")

local recipes = data.raw.recipe

local get_subgroup = function(item)
  if item.subgroup then return item.subgroup end
  local recipe = recipes[item.name]
  if recipe then
    if recipe.subgroup then return recipe.subgroup end
  end
  return "other"
end

local make_recipe = function(item)
  if not item then return end
  if not item.name then
    return
  end
  if util.has_flag(item, "not-stackable") or util.has_flag(item, "hidden")  then return end
  local recipe = 
  {
    type = "recipe",
    name = "request-"..item.name,
    localised_name = {"request-item", item.localised_name or item.place_result and {"entity-name."..item.place_result} or {"item-name."..item.name}},
    icon = item.dark_background_icon or item.icon,
    icon_size = item.icon_size,
    icons = item.icons,
    ingredients =
    {
      {type = "item", name = "transport-drone", amount = 1},
      {type = "fluid", name = shared.fuel_fluid, amount = 5000}
    },
    results =
    {
      {type = "item", name = item.name, amount = 60000, show_details_in_recipe_tooltip = false},
      {type = "item", name = item.name, amount = 60000, show_details_in_recipe_tooltip = false},
      {type = "item", name = item.name, amount = 60000, show_details_in_recipe_tooltip = false},
    },
    category = category,
    order = item.order,
    subgroup = get_subgroup(item),
    overload_multiplier = math.min(200, 60000 / (item.stack_size or 1)),
    hide_from_player_crafting = true,
    main_product = "",
    allow_decomposition = false,
    allow_as_intermediate = false,
    allow_intermediates = true
  }
  data:extend{recipe}
end

for k, item_type in pairs(util.item_types()) do
  local items = data.raw[item_type]
  if items then
    for k, item in pairs (items) do
      make_recipe(item)
    end
  end
end

local make_fluid_depot_recipe = function(fluid)
  data:extend
  {
    {
      type = "recipe",
      name = "fluid-depot-"..fluid.name,
      --localised_name = {"", "Request ", item.localised_name or item.place_result and {"entity-name."..item.place_result} or {"item-name."..item.name}},
      icon = fluid.icon,
      icon_size = fluid.icon_size,
      icons = fluid.icons,
      ingredients =
      {
        {type = "fluid", name = fluid.name, amount = 0}
      },
      results =
      {
      },
      category = "transport-fluid-request",
      order = fluid.order,
      subgroup = fluid.subgroup or "fluid", --get_subgroup(item),
      overload_multiplier = 1,
      hide_from_player_crafting = true,
      main_product = "",
      allow_decomposition = false,
      allow_as_intermediate = false,
      allow_intermediates = true,
      enabled = true,
      energy_required = 2 ^ 50
    }
  }
end

local make_fluid_request_recipe = function(fluid)

  local recipe = 
  {
    type = "recipe",
    name = "request-"..fluid.name,
    localised_name = {"request-item", fluid.localised_name or {"fluid-name."..fluid.name}},
    icon = fluid.icon,
    icon_size = fluid.icon_size,
    icons = fluid.icons,
    ingredients =
    {
      {type = "item", name = "transport-drone", amount = 1},
      {type = "fluid", name = shared.fuel_fluid, amount = 5000}
    },
    results =
    {
      {type = "fluid", name = fluid.name, amount = 1000000, show_details_in_recipe_tooltip = false}
    },
    category = category,
    order = fluid.order,
    subgroup = fluid.subgroup or "fluid",
    overload_multiplier = 200,
    hide_from_player_crafting = true,
    main_product = "",
    allow_decomposition = false,
    allow_as_intermediate = false,
    allow_intermediates = true
  }
  data:extend{recipe}
end

for k, fluid in pairs (data.raw.fluid) do
  make_fluid_depot_recipe(fluid)
  make_fluid_request_recipe(fluid)
end
