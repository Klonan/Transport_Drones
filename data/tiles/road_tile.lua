local tile = util.copy(data.raw.tile["stone-path"])

tile.name = "transport-drone-road"
tile.tint = {0.5, 0.5, 0.5}
tile.collision_mask = shared.tile_collision_mask

data:extend{tile}