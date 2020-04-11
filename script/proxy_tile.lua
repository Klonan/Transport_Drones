--lets not wallop player things

local road_network = require("script/road_network")

local real_name = "transport-drone-road"

local raw_road_tile_built = function(event)

  for k, tile in pairs (event.tiles) do
    local position = tile.position
    road_network.add_node(event.surface_index, position.x, position.y)
  end

end

local product_amount = util.product_amount
local road_tile_built = function(event)

  local tiles = event.tiles
  local surface = game.get_surface(event.surface_index)
  local refund_count = 0
  local new_tiles = {}
  local refund_product = {}

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
      if tile.old_tile.mineable_properties.minable then
        refund_product[tile.old_tile.name] = (refund_product[tile.old_tile.name] or 0) + 1
      end
    end
  end

  surface.set_tiles(new_tiles)
  
  if next(refund_product) then
    -- Remove first, so we make space in the inventory
    local remove_function = (event.player_index and game.get_player(event.player_index).remove_item) or (event.robot and event.robot.get_inventory(defines.inventory.robot_cargo).remove)
    if remove_function then
      local tile_prototypes = game.tile_prototypes
      for tile_name, count in pairs(refund_product) do
        local tile = tile_prototypes[tile_name]
        for k, product in pairs (tile.mineable_properties.products) do
          local count = product_amount(product) * count
          if count > 0 then
            remove_function({name = product.name, count = count})
          end
        end
      end
    end
  end

  if event.item and refund_count > 0 then
    local insert_function = (event.player_index and game.get_player(event.player_index).insert) or (event.robot and event.robot.get_inventory(defines.inventory.robot_cargo).insert)
    if insert_function then
      local inserted = insert_function({name = event.item.name, count = refund_count})
    end
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

  local surface = game.get_surface(event.surface_index)
  surface.set_tiles(new_tiles)

  
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

  if event.tile.name == "transport-drone-road" then
    raw_road_tile_built(event)
    return
  end
  if event.tile.name == "transport-drone-proxy-tile" then
    road_tile_built(event)
    return
  end

  non_road_tile_built(event)
  
end

local text = "You're playing with a naughty mod that isn't raising events properly. Surface index is missing from the tile mined event."
local broken_now = "The road network will probably be broken now if you were doing anything with road tiles."
local on_mined_tile = function(event)
  if not event.surface_index then
    if game.is_multiplayer() then
      game.print(text)
      game.print(broken_now)
    else
      game.show_message_dialog{text = text}
      game.show_message_dialog{text = broken_now}
    end
    return
  end
  local tiles = event.tiles
  local new_tiles = {}
  local refund_count = 0
  for k, tile in pairs (tiles) do
    if tile.old_tile.name == real_name then
      if road_network.remove_node(event.surface_index, tile.position.x, tile.position.y) then
        --can't remove this tile, supply or requester is there.
        new_tiles[k] = {name = tile.old_tile.name, position = tile.position}
        refund_count = refund_count + 1
      end
    end
  end
  local surface = game.get_surface(event.surface_index)
  surface.set_tiles(new_tiles)

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

local lib = {}

lib.events = 
{
  [defines.events.on_player_built_tile] = on_built_tile,
  [defines.events.on_robot_built_tile] = on_built_tile,

  [defines.events.on_player_mined_tile] = on_mined_tile,
  [defines.events.on_robot_mined_tile] = on_mined_tile,
}

return lib