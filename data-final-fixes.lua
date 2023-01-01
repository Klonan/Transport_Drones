local shared = require("shared")
local collision_mask_util = require("collision-mask-util")

local road_collision_layer = collision_mask_util.get_first_unused_layer()
local tiles = data.raw.tile


local road_list = {}
local road_tile_list =
{
  type = "selection-tool",
  name = "road-tile-list",
  flags = {"hidden"},
  icon = "__Transport_Drones__/data/tf_util/empty-sprite.png",
  icon_size = 1,
  tile_filters = road_list,
  stack_size = 1,
  selection_color = {},
  alt_selection_color = {},
  selection_mode = {"any-tile"},
  alt_selection_mode = {"any-tile"},
  selection_cursor_box_type = "entity",
  alt_selection_cursor_box_type = "entity"
}
data:extend{road_tile_list}

local place_as_tile_condition = {"water-tile"}

if mods["space-exploration"] then
  table.insert(place_as_tile_condition, spaceship_collision_layer)
  table.insert(place_as_tile_condition, empty_space_collision_layer)
end

local process_road_item = function(item)

  local tile = tiles[item.place_as_tile.result]
  if not tile then return end
  local seen = {}
  while true do
    tile.collision_mask = {road_collision_layer}
    table.insert(road_list, tile.name)
    seen[tile.name] = true
    tile = tiles[tile.next_direction or ""]
    if not tile then break end
    if seen[tile.name] then break end
  end
  item.place_as_tile.condition = place_as_tile_condition
end


local process_non_road_item = function(item)
  local condition = item.place_as_tile.condition
  collision_mask_util.add_layer(condition, road_collision_layer)
end

for k, item in pairs (data.raw.item) do
  if item.place_as_tile then
    if item.is_road_tile then
      process_road_item(item)
    else
      process_non_road_item(item)
    end
  end
end

local all_used_tile_collision_masks = {}
for k, tile in pairs (tiles) do
  tile.check_collision_with_entities =  true
  for k, layer in pairs (tile.collision_mask or {}) do
    all_used_tile_collision_masks[layer] = true
  end
end

shared.drone_collision_mask = all_used_tile_collision_masks
shared.drone_collision_mask[road_collision_layer] = nil
shared.drone_collision_mask["colliding-with-tiles-only"] = true
shared.drone_collision_mask["consider-tile-transitions"] = true

for k, prototype in pairs (collision_mask_util.collect_prototypes_with_layer("player-layer")) do
  if prototype.type ~= "gate" and prototype.type ~= "tile" then
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

--error(serpent.block(road_list))

--So you don't place any tiles over road.

local util = require "__Transport_Drones__/data/tf_util/tf_util"
require("data/entities/transport_drone/transport_drone")
require("data/make_request_recipes")
