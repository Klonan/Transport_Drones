local tile = util.copy(data.raw.tile["stone-path"])

tile.name = "transport-drone-road"
tile.localised_name = {"road"}
tile.tint = {0.5, 0.5, 0.5}
tile.collision_mask = {"ooga wooga error"}
tile.minable.result = "road"
tile.layer = 250
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
  order = "b[concrete]-a[plain]",
  stack_size = 100,
  place_as_tile =
  {
    result = "transport-drone-road",
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
    {"stone-brick", 10},
    {"coal", 10},
  },
  energy_required = 1,
  result = "road",
  result_count = 10
}

data:extend
{
  tile,
  item,
  recipe
}

if alien_biomes_priority_tiles then
  table.insert(alien_biomes_priority_tiles, "transport-drone-road")
end