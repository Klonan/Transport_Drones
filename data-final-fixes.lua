local fuel = settings.startup["fuel-fluid"].value
if not data.raw.fluid[fuel] then
  error("\n\n[font=heading-1]Bad fluid name for transport drones fuel: "..fuel.."\n\nFix your mod settings!\n\n[/font]")
end

require("data/make_request_recipes")

-- ruin rails

local rail_addition_mask = "layer-15"
local rail_collision_mask = {"floor-layer", "water-tile", "item-layer"}

for k, rail in pairs (data.raw["straight-rail"]) do
  if rail.collision_mask then
    util.remove_from_list(rail.collision_mask, "object-layer")
  else
    rail.collision_mask = rail_collision_mask
  end
  table.insert(rail.collision_mask, rail_addition_mask)
  rail.selection_priority = 45
end

for k, rail in pairs (data.raw["curved-rail"]) do
  if rail.collision_mask then
    util.remove_from_list(rail.collision_mask, "object-layer")
  else
    rail.collision_mask = rail_collision_mask
  end
  table.insert(rail.collision_mask, rail_addition_mask)
  rail.selection_priority = 45
end

-- ruin gates

local gate_collision_mask = {"item-layer", "player-layer", "train-layer", "water-tile"}
local opened_gate_collision_mask = {"item-layer", "water-tile", "floor-layer"}

for k, gate in pairs (data.raw.gate) do
  if gate.collision_mask then
    util.remove_from_list(gate.collision_mask, "object-layer")
  else
    gate.collision_mask = gate_collision_mask
  end
  if gate.opened_collision_mask then
    util.remove_from_list(gate.opened_collision_mask, "object-layer")
  else
    gate.opened_collision_mask = opened_gate_collision_mask
  end
end