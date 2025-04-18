--lets not wallop player things

local road_network = require("script/road_network")

local road_tile_list_name = "road-tile-list"
local road_tiles
local tile_filters = {
  "transport-drone-road",
  "transport-drone-road-better"
}
local get_road_tiles = function()
  if road_tiles then return road_tiles end
  road_tiles = {}
  for _, tile_name in pairs (tile_filters) do
    road_tiles[tile_name] = true
  end
  return road_tiles
end

local is_road_tile = function(name)
  return get_road_tiles()[name]
end

local raw_road_tile_built = function(event)

  for k, tile in pairs (event.tiles) do
    local position = tile.position
    road_network.add_node(event.surface_index, position.x, position.y)
  end

end

local non_road_tile_built = function(event)

  local tiles = event.tiles
  local new_tiles = {}
  local refund_count = 0
  for k, tile in pairs (tiles) do
    if road_network.remove_node(event.surface_index, tile.position.x, tile.position.y) then
      new_tiles[k] = {name = tile.old_tile.name, position = tile.position}
      refund_count = refund_count + 1
    end
  end

  if next(new_tiles) then
    local surface = game.get_surface(event.surface_index)
    surface.set_tiles(new_tiles)
  end


  if event.item then

    if refund_count > 0 then
      if event.player_index then
        local player = game.get_player(event.player_index)
        if player then
          player.insert({name = event.item.name, count = refund_count})
          player.remove_item({name = "road", count = refund_count})
        end
      end
      local robot = event.robot
      if robot then
        robot.get_inventory(defines.inventory.robot_cargo).insert({name = event.item.name, count = refund_count})
        robot.get_inventory(defines.inventory.robot_cargo).remove({name = "road", count = refund_count})
      end
    end

  end

end

local on_built_tile = function(event)
  if is_road_tile(event.tile.name) then
    raw_road_tile_built(event)
  else
    non_road_tile_built(event)
  end

end

local on_mined_tile = function(event)
  local tiles = event.tiles
  local new_tiles = {}
  local refund_count = 0
  for k, tile in pairs (tiles) do
    if is_road_tile(tile.old_tile.name) then
      if road_network.remove_node(event.surface_index, tile.position.x, tile.position.y) then
        --can't remove this tile, supply or requester is there.
        new_tiles[k] = {name = tile.old_tile.name, position = tile.position}
        refund_count = refund_count + 1
      end
    end
  end

  if next(new_tiles) then
    local surface = game.get_surface(event.surface_index)
    surface.set_tiles(new_tiles)
  end

  if refund_count > 0 then
    if event.player_index then
      local player = game.get_player(event.player_index)
      if player then
        player.remove_item({name = "road", count = refund_count})
      end
    end
    local robot = event.robot
    if robot then
      robot.get_inventory(defines.inventory.robot_cargo).remove({name = "road", count = refund_count})
    end
  end

end

local script_raised_set_tiles = function(event)
  if not event.tiles then return end
  local new_tiles = {}

  for k, tile in pairs (event.tiles) do
    if is_road_tile(tile.name) then
      road_network.add_node(event.surface_index, tile.position.x, tile.position.y)
    elseif road_network.remove_node(event.surface_index, tile.position.x, tile.position.y) then
      --can't remove this tile, depot is here.
      new_tiles[k] = {name = "transport-drone-road", position = tile.position}
    end
  end

  if next(new_tiles) then
    local surface = game.get_surface(event.surface_index)
    surface.set_tiles(new_tiles)
  end

end

local lib = {}

lib.events =
{
  [defines.events.on_player_built_tile] = on_built_tile,
  [defines.events.on_robot_built_tile] = on_built_tile,

  [defines.events.on_player_mined_tile] = on_mined_tile,
  [defines.events.on_robot_mined_tile] = on_mined_tile,

  [defines.events.script_raised_set_tiles] = script_raised_set_tiles

}

return lib