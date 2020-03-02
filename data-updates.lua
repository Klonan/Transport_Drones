require("data/make_request_recipes")

-- ruin gates and rails

local rail_collision_mask = {"floor-layer", "water-tile", "item-layer"}
local gate_collision_mask = {"item-layer", "player-layer", "train-layer", "water-tile"}

for k, rail in pairs (data.raw["straight-rail"]) do
  rail.collision_mask = rail.collision_mask or rail_collision_mask
end

for k, rail in pairs (data.raw["curved-rail"]) do
  rail.collision_mask = rail.collision_mask or rail_collision_mask
end

for k, gate in pairs (data.raw.gate) do
  gate.collision_mask = gate.collision_mask or gate_collision_mask
end