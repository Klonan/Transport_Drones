local tile = util.copy(data.raw.tile["stone-path"])

tile.name = "transport-drone-road"
tile.localised_name = {"road"}
tile.tint = {0.5, 0.5, 0.5}
tile.collision_mask = shared.tile_collision_mask
tile.minable.result = "road"
tile.layer = 150
tile.placeable_by = {{item   = "road", count = 1}}
tile.map_color={r=86/2, g=82/2, b=74/2}

local proxy_tile = util.copy(data.raw.tile["stone-path"])

proxy_tile.name = "transport-drone-proxy-tile"
proxy_tile.tint = {0.5, 0.5, 0.5}
proxy_tile.localised_name = {"road"}

local proxy_entity = 
{
  type = "simple-entity",
  name = "road-tile-collision-proxy",
  icon = "__base__/graphics/icons/ship-wreck/small-ship-wreck.png",
  icon_size = 64,
  flags = {"placeable-neutral", "placeable-off-grid", "not-on-map"},
  subgroup = "wrecks",
  order = "d[remnants]-d[ship-wreck]-c[small]-a",
  max_health = 1,
  collision_box = {{-0.5, -0.5}, {0.5, 0.5}},
  pictures = util.empty_sprite(),
  render_layer = "object",
  collision_mask = shared.tile_collision_mask
}

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
    result = "transport-drone-proxy-tile",
    condition_size = 1,
    condition = { "water-tile", "object-layer" }
  }
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
  proxy_tile,
  proxy_entity,
  item,
  recipe
}

if alien_biomes_priority_tiles then
  table.insert(alien_biomes_priority_tiles, "transport-drone-proxy-tile")
  table.insert(alien_biomes_priority_tiles, "transport-drone-road")
end