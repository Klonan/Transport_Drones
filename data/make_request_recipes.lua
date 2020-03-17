local category = "transport-drone-request"
local util = require("tf_util/tf_util")

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
    localised_name = {"", "Request ", item.localised_name or item.place_result and {"entity-name."..item.place_result} or {"item-name."..item.name}},
    icon = item.icon,
    icon_size = item.icon_size,
    icons = item.icons,
    ingredients =
    {
      {type = "item", name = "transport-drone", amount = 1}
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
