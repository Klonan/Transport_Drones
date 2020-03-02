--lets not wallop player things

local road_network = require("script/road_network")

local real_name = "transport-drone-road"

local on_built_tile = function(event)
  local tile = event.tile
  if tile.name ~= "transport-drone-proxy-tile" then return end

  
  local tiles = event.tiles
  local surface = game.get_surface(event.surface_index)
  local refund_count = 0
  local new_tiles = {}

  for k, tile in pairs (tiles) do
    local position = tile.position
    if surface.can_place_entity(
      {
        name = "road-tile-collision-proxy",
        position = {position.x + 0.5, position.y + 0.5},
        build_check_type = defines.build_check_type.manual
      }
    ) then
      new_tiles[k] = {name = real_name, position = position}
      road_network.add_node(event.surface_index, position.x, position.y)
    else
      new_tiles[k] = {name = tile.old_tile.name, position = position}
      refund_count = refund_count + 1
    end
  end

  surface.set_tiles(new_tiles)

  if event.item then

    if refund_count > 0 then
      if event.player then
        local player = game.get_player(event.player_index)
        if player then
          player.insert({name = event.item.name, count = refund_count})
        end
      end
      local robot = event.robot
      if robot then
        robot.get_inventory(defines.inventory.robot_cargo).insert({name = event.item.name, count = refund_count})
      end
    end

  end

end

local on_mined_tile = function(event)
  local tiles = event.tiles
  for k, tile in pairs (tiles) do
    if tile.old_tile.name == real_name then
      road_network.remove_node(event.surface_index, tile.position.x, tile.position.y)
    end
  end
end

local lib = {}

lib.events = 
{
  [defines.events.on_player_built_tile] = on_built_tile,
  [defines.events.on_robot_built_tile] = on_built_tile,

  [defines.events.on_player_mined_tile] = on_mined_tile,
}

return lib