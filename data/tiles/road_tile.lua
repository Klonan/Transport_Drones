local tile = util.copy(data.raw.tile["stone-path"])

tile.name = "transport-drone-road"
tile.localised_name = {"road"}
tile.tint = {0.5, 0.5, 0.5}
tile.collision_mask = {layers={
  ground_tile=true
}}
tile.minable.result = "road"
tile.layer = 61
tile.placeable_by = {{item = "road", count = 1}}
tile.map_color={r=86/2, g=82/2, b=74/2}
tile.walking_speed_modifier = 1.5
tile.vehicle_friction_modifier = 0.9


local item =
{
  type = "item",
  name = "road",
  localised_name = {"road"},
  icons =
  {
    {
      icon = "__base__/graphics/icons/concrete.png",
      icon_size = 64,
      tint = {0.5, 0.5, 0.5}
    }
  },
  subgroup = "transport-drones",
  order = "b[concrete]-za[plain]",
  stack_size = 100,
  place_as_tile =
  {
    result = "transport-drone-road",
    condition_size = 1,
    condition = {"ooga wooga error me"}
  },
  is_road_tile = true
}

local better_tile = util.copy(data.raw.tile["refined-concrete"])

better_tile.name = "transport-drone-road-better"
better_tile.localised_name = {"fast-road"}
better_tile.tint = {0.5, 0.5, 0.5}
better_tile.collision_mask = {layers={
  ground_tile=true
}}
better_tile.minable.result = "fast-road"
better_tile.layer = 62
better_tile.placeable_by = {{item = "fast-road", count = 1}}
better_tile.map_color={r=86/2, g=82/2, b=74/2}
better_tile.walking_speed_modifier = 2
better_tile.vehicle_friction_modifier = 0.8

local better_item =
{
  type = "item",
  name = "fast-road",
  localised_name = {"fast-road"},
  icons =
  {
    {
      icon = "__base__/graphics/icons/refined-concrete.png",
      icon_size = 64,
      tint = {0.5, 0.5, 0.5}
    }
  },
  subgroup = "transport-drones",
  order = "b[concrete]-zb[plain]",
  stack_size = 200,
  place_as_tile =
  {
    result = "transport-drone-road-better",
    condition_size = 1,
    condition = {"ooga wooga error me"}
  },
  is_road_tile = true
}

local recipe =
{
  type = "recipe",
  name = "road",
  localised_name = {"road"},
  icon = item.icon,
  icon_size = item.icon_size,
  --category = "transport",
  enabled = false,
  ingredients =
  {
    {type = "item",name = "stone-brick",amount = 10},
    {type = "item",name = "coal",amount = 10},
  },
  energy_required = 1,
  results = {
    {type="item",name="road",amount=10}
  }
}

local fast_recipe =
{
  type = "recipe",
  name = "fast-road",
  localised_name = {"fast-road"},
  icon = better_item.icon,
  icon_size = better_item.icon_size,
  category = "crafting-with-fluid",
  enabled = false,
  ingredients =
  {
    {type = "item",name = "concrete",amount =10},
    {type = "fluid", name = "crude-oil", amount = 50},
  },
  energy_required = 1,
  results = {
    {type="item",name="fast-road",amount=10}
  }
}

data:extend
{
  tile,
  item,
  recipe,
  fast_recipe,
  better_tile,
  better_item
}

if alien_biomes_priority_tiles then
  table.insert(alien_biomes_priority_tiles, "transport-drone-road")
  table.insert(alien_biomes_priority_tiles, "transport-drone-road-better")
end