local shared = require("shared")
local collision_mask_util = require("collision-mask-util")

data:extend {
  {
    type = "collision-layer",
    name = "roadtd",
  }
}
local tiles = data.raw.tile


local road_list = {}
local road_tile_list =
{
  type = "selection-tool",
  name = "road-tile-list",
  hidden = true,
  icon = "__Transport_Drones_Meglinge_Fork__/data/tf_util/empty-sprite.png",
  icon_size = 1,
  tile_filters = {
    "transport-drone-road",
    "transport-drone-road-better"
  },
  stack_size = 1,
  select =
  {
    border_color = { 1, 1, 1 },
    mode = { "any-tile" },
    cursor_box_type = "entity",
  },
  alt_select =
  {
    border_color = { 0, 1, 0 },
    mode = { "any-tile" },
    cursor_box_type = "entity",
  }
}
data:extend { road_tile_list }

local place_as_tile_condition = { layers = { water_tile = true } }

if mods["space-exploration"] then
  table.insert(place_as_tile_condition, spaceship_collision_layer)
  table.insert(place_as_tile_condition, empty_space_collision_layer)
end

local process_road_item = function(item)
  local tile = tiles[item.place_as_tile.result]
  if not tile then return end
  local seen = {}
  while true do
    tile.collision_mask = { layers = { roadtd = true } }
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
  condition.layers["roadtd"] = true
end

for k, item in pairs(data.raw.item) do
  if item.place_as_tile then
    if item.is_road_tile then
      process_road_item(item)
    else
      process_non_road_item(item)
    end
  end
end

--temp
function split(str, delimiter)
  local result = {}
  local pattern = "([^" .. delimiter .. "]+)"
  for match in string.gmatch(str, pattern) do
    table.insert(result, match)
  end
  return result
end

local all_used_tile_collision_masks = {}
for k, tile in pairs(tiles) do
  tile.check_collision_with_entities = true
  for k, layer in pairs(tile.collision_mask or {}) do
    local layerTempStr = serpent.line(layer)
    layerTempStr = string.gsub(layerTempStr, "{", "")
    layerTempStr = string.gsub(layerTempStr, "}", "")
    layerTempStr = string.gsub(layerTempStr, " ", "")
    layerTempStr = string.gsub(layerTempStr, "=true", "")
    if #layerTempStr ~= 0 then
      local layerTempList = split(layerTempStr, ",")
      for k, layerTemp in pairs(layerTempList) do
        if layerTemp ~= "true" and layerTemp ~= nil then
          if not string.find(layerTemp,'%[') then
            all_used_tile_collision_masks[layerTemp] = true
          end
          all_used_tile_collision_masks["roadtd"] = nil
        end
      end
    end
  end
end

shared.drone_collision_mask = { layers = all_used_tile_collision_masks }
shared.drone_collision_mask["colliding_with_tiles_only"] = true
shared.drone_collision_mask["consider_tile_transitions"] = true
--temp

for k, prototype in pairs(collision_mask_util.collect_prototypes_with_layer("player")) do
  if prototype.type ~= "gate" and prototype.type ~= "tile" then
    local mask = collision_mask_util.get_mask(prototype)
    if mask.layers["item"] then
      mask.layers["roadtd"] = true
    end
    prototype.collision_mask = mask
  end
end

-- if data.raw["assembling-machine"]["mining-depot"] then
--   data.raw["assembling-machine"]["mining-depot"].collision_mask = { layers = { roadtd = true } }
-- end

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
local util = require "__Transport_Drones_Meglinge_Fork__/data/tf_util/tf_util"
require("data/entities/transport_drone/transport_drone")
require("data/make_request_recipes")
