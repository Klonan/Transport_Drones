local tile = util.copy(data.raw.tile["stone-path"])

tile.name = "transport-drone-road"
tile.tint = {0.5, 0.5, 0.5}
tile.collision_mask = shared.tile_collision_mask

local proxy_tile = util.copy(data.raw.tile["stone-path"])

proxy_tile.name = "transport-drone-proxy-tile"
proxy_tile.tint = {0.5, 0.5, 0.5}

local proxy_entity = 
{
  type = "simple-entity",
  name = "road-tile-collision-proxy",
  icon = "__base__/graphics/icons/ship-wreck/small-ship-wreck.png",
  icon_size = 64, icon_mipmaps = 4,
  minable = {mining_time = 0.5, result = "iron-gear-wheel"},
  flags = {"placeable-neutral", "placeable-off-grid", "not-on-map"},
  subgroup = "wrecks",
  order = "d[remnants]-d[ship-wreck]-c[small]-a",
  max_health = 1,
  collision_box = {{-0.49, -0.49}, {0.49, 0.49}},
  pictures = util.empty_sprite(),
  render_layer = "object"
}

local item = 
{
  type = "item",
  name = "road",
  icon = "__base__/graphics/icons/concrete.png",
  icon_size = 64, icon_mipmaps = 4,
  subgroup = "terrain",
  order = "b[concrete]-a[plain]",
  stack_size = 100,
  place_as_tile =
  {
    result = "transport-drone-proxy-tile",
    condition_size = 1,
    condition = { "water-tile", "object-layer" }
  }
}

data:extend
{
  tile,
  proxy_tile,
  proxy_entity,
  item,
}