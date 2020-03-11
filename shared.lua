--Shared data interface between data and script, notably prototype names.

local data = {}

data.tile_collision_mask = {"object-layer", "layer-14"}
data.drone_collision_mask = {"ground-tile", "not-colliding-with-itself", "colliding-with-tiles-only"}
data.variation_count = 50
data.transport_speed_technology = "transport-drone-speed"
data.transport_capacity_technology = "transport-drone-capacity"

return data
