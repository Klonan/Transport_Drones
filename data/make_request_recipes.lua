local fuel = settings.startup["fuel-fluid"].value
if not data.raw.fluid[fuel] then
  log("Bad name for fuel fluid. reverting to something else...")

  fuel = "petroleum-gas"
  if not data.raw.fluid[fuel] then
    fuel = nil
    for k, fluid in pairs (data.raw.fluid) do
      if fluid.fuel_value then
        fuel = fluid.name
        break
      end
    end
  end

  if not fuel then
    local index, fluid = next(data.raw.fluid)
    if fluid then
      fuel = fluid.name
    end
  end
end

local category = "transport-drone-request"
local util = require("__Transport_Drones__/data/tf_util/tf_util")
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
  if util.has_flag(item, "hidden") then return end
  local max_stack = 65000
  if util.has_flag(item, "not-stackable") or item.type == "armor" then
    max_stack = 1
  end
  local recipe =
  {
    type = "recipe",
    name = "request-"..item.name,
    icon = item.dark_background_icon or item.icon,
    icon_size = item.icon_size,
    icons = item.icons,
    ingredients =
    {
      {type = "item", name = "transport-drone", amount = 1},
      {type = "fluid", name = fuel, amount = 5000}
    },
    results =
    {
      {type = "item", name = item.name, amount = max_stack, show_details_in_recipe_tooltip = false},
      {type = "item", name = item.name, amount = max_stack, show_details_in_recipe_tooltip = false},
      {type = "item", name = item.name, amount = max_stack, show_details_in_recipe_tooltip = false},
      {type = "item", name = item.name, amount = max_stack, show_details_in_recipe_tooltip = false},
      {type = "item", name = item.name, amount = max_stack, show_details_in_recipe_tooltip = false},
      {type = "item", name = item.name, amount = max_stack, show_details_in_recipe_tooltip = false},
      {type = "item", name = item.name, amount = max_stack, show_details_in_recipe_tooltip = false},
    },
    category = category,
    order = item.order,
    subgroup = get_subgroup(item),
    overload_multiplier = 100,
    hide_from_player_crafting = true,
    main_product = item.name,
    allow_decomposition = false,
    allow_as_intermediate = false,
    allow_intermediates = true,
    allow_inserter_overload = false,
    energy_required = 2 ^ 50
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
      allow_intermediates = false,
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
    icon = fluid.icon,
    icon_size = fluid.icon_size,
    icons = fluid.icons,
    ingredients =
    {
      {type = "item", name = "transport-drone", amount = 1},
      {type = "fluid", name = fuel, amount = 10000}
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
    main_product = fluid.name,
    allow_decomposition = false,
    allow_as_intermediate = false,
    allow_intermediates = false,
    energy_required = 2 ^ 50
  }
  data:extend{recipe}
end

for k, fluid in pairs (data.raw.fluid) do
  make_fluid_depot_recipe(fluid)
  make_fluid_request_recipe(fluid)
end

local fuel_recipe =
{
  type = "recipe",
  name = "fuel-depots",
  localised_name = {"fuel-depots"},
  flags = {"hidden"},
  icon = util.path("data/entities/transport_depot/fuel-recipe-icon.png"),
  icon_size = 64,
  --category = "transport",
  enabled = true,
  ingredients =
  {
    {type = "item", name = "transport-drone", amount = 100},
    {type = "fluid", name = fuel, amount = 5000}
  },
  overload_multipler = 50,
  energy_required = 5,
  results =
  {
    {type = "fluid", name = fuel, amount = 10}
  },
  subgroup = "other",
  category = "fuel-depot",
  hidden = true
}

data:extend{fuel_recipe}