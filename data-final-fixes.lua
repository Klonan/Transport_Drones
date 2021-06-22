local shared = require("shared")
local collision_mask_util = require("collision-mask-util")

local road_tile = data.raw.tile["transport-drone-road"]
local road_tile_proxy = data.raw.tile["transport-drone-proxy-tile"]
local road_proxy_entity = data.raw["simple-entity"]["road-tile-collision-proxy"]
local road_item = data.raw.item.road

local road_collision_layer = collision_mask_util.get_first_unused_layer()
road_tile.collision_mask = {road_collision_layer}
road_proxy_entity.collision_mask = {road_collision_layer}

road_tile_proxy.collision_mask = {"ground-tile"}

road_item.place_as_tile =
{
  result = road_tile_proxy.name,
  condition_size = 1,
  condition = {"water-tile", road_collision_layer}
}

for k, prototype in pairs (collision_mask_util.collect_prototypes_with_layer("player-layer")) do
  if prototype.type ~= "gate" then
    local mask = collision_mask_util.get_mask(prototype)
    if collision_mask_util.mask_contains_layer(mask, "item-layer") then
      collision_mask_util.add_layer(mask, road_collision_layer)
    end
    prototype.collision_mask = mask
  end
end

if data.raw["assembling-machine"]["mining-depot"] then
  collision_mask_util.add_layer(data.raw["assembling-machine"]["mining-depot"].collision_mask, road_collision_layer)
end

--Disable belts on roads
--[[
  for k, prototype in pairs (collision_mask_util.collect_prototypes_with_layer("transport-belt-layer")) do
    local mask = collision_mask_util.get_mask(prototype)
    collision_mask_util.add_layer(mask, road_collision_layer)
    prototype.collision_mask = mask
  end
]]

--So you don't landfill over road.
for k, item in pairs (data.raw.item) do
  if item.place_as_tile then
    local condition = item.place_as_tile.condition
    if condition then
      if collision_mask_util.mask_contains_layer(condition, "ground-tile") then
        collision_mask_util.add_layer(condition, road_collision_layer)
      end
    end
  end
end

local ignored_mask = { "not-colliding-with-itself", "resource-layer", "ghost-layer", "doodad-layer", "object-layer", "player-layer", "floor-layer", "item-layer" }

local drone_mask = {"ground-tile", "water-tile", "colliding-with-tiles-only", "consider-tile-transitions"}
for k, tile in pairs(data.raw.tile) do
    for _, layer in pairs(tile.collision_mask) do
      if not collision_mask_util.mask_contains_layer(ignored_mask, layer) then
        collision_mask_util.add_layer(drone_mask, layer)
      end
    end
end
collision_mask_util.remove_layer(drone_mask, road_collision_layer)
shared.drone_collision_mask = drone_mask

local util = require "__Transport_Drones__/data/tf_util/tf_util"
require("data/entities/transport_drone/transport_drone")
require("data/make_request_recipes")
