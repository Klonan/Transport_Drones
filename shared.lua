--Shared data interface between data and script, notably prototype names.

local data = {}

data.tile_collision_mask = {"object-layer", "layer-14"}
data.drone_collision_mask = {"ground-tile", "not-colliding-with-itself"}
data.variation_count = 50
data.transport_speed_technology = "transport-drone-speed"
data.transport_capacity_technology = "transport-drone-capacity"

data.drone_name = "mining-drone"
data.proxy_chest_name = "mining-drone-proxy-chest"
data.mining_damage = 5
data.mining_interval = math.floor(26 * 1.5) --dictated by character mining animation
data.attack_proxy_name = "mining-drone-attack-proxy-new"
data.mining_depot = "mining-depot"
data.mining_depot_chest_h = "mining-depot-chest-h"
data.mining_depot_chest_v = "mining-depot-chest-v"

data.mining_productivity_technology = "mining-drone-productivity"

return data
