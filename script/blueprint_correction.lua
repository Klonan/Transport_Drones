local supply_depot = require("script/supply_depot")
local request_depot = require("script/request_depot")

local script_data =
{
  blueprint_correction_data = {}
}

local get_depot = function(entity)
  return supply_depot.get_depot(entity) or request_depot.get_depot(entity)
end

local determine_direction = function(depot)

  local corpse_position = depot.corpse.position
  local self_position = depot.entity.position
  if corpse_position.x > self_position.x then
    return defines.direction.east
  end
  if corpse_position.x < self_position.x then
    return defines.direction.west
  end
  if corpse_position.y > self_position.y then
    return defines.direction.south
  end
  if corpse_position.y < self_position.y then
    return defines.direction.north
  end
  error("huh")
end

local correct_blueprint = function(stack, correction_data)
  if not correction_data then return end
  game.print("correcting blueprint")
  local entities = stack.get_blueprint_entities()
  if not entities then return end
  for k, correction in pairs (correction_data) do
    local entity = entities[k]
    entity.name = correction.name
    entity.direction = correction.direction
  end
  stack.set_blueprint_entities(entities)
end

local tile_correction = 
{
  ["transport-drone-road"] = "transport-drone-proxy-tile"
}

local correct_tiles = function(stack)
  game.print("correcting tiles")
  local tiles = stack.get_blueprint_tiles()
  if not tiles then return end

  for k, tile in pairs (tiles) do
    tile.name = tile_correction[tile.name] or tile.name
  end

  stack.set_blueprint_tiles(tiles)

end

local name_correction = 
{
  ["supply-depot-chest"] = "supply-transport-depot",
  ["request-depot-machine"] = "request-transport-depot",
}

local on_player_setup_blueprint = function(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  
  script_data.blueprint_correction_data[event.player_index] = nil

  local depots = script_data.supply_depots
  local blueprint_correction_data = {}
  for k, entity in pairs (event.mapping.get()) do
    local correct_name = name_correction[entity.name]
    if correct_name then
      local depot = get_depot(entity)
      if depot then
        blueprint_correction_data[k] = {name = correct_name, direction = determine_direction(depot)}
      end
    end
  end

  if not next(blueprint_correction_data) then
    blueprint_correction_data = nil
  end

  local stack = player.cursor_stack
  if stack.valid_for_read then
    correct_blueprint(stack, blueprint_correction_data)
    correct_tiles(stack)
    --He has a blueprint! Set the entities here.
    return
  end

  script_data.blueprint_correction_data[player.index] = blueprint_correction_data
  --Oh no, he doesn't have a blueprint, he will confirm it later. save the data to global.
  
end

local on_player_configured_blueprint = function(event)
  local player = game.get_player(event.player_index)
  local stack = player.cursor_stack
  if stack.valid_for_read and stack.is_blueprint then
    correct_blueprint(stack, script_data.blueprint_correction_data[event.player_index])
    correct_tiles(stack)
  end

end

local lib = {}

lib.events =
{
  [defines.events.on_player_setup_blueprint] = on_player_setup_blueprint,
  [defines.events.on_player_configured_blueprint] = on_player_configured_blueprint,
}

lib.on_init = function()
  global.blueprint_correction = global.blueprint_correction or script_data
end

lib.on_load = function()
  script_data = global.blueprint_correction or script_data
end

return lib