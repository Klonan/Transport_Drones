local request_depot = require("script/request_depot")
local supply_depot = require("script/supply_depot")
local road_network = require("script/road_network")

local depot_names = 
{
  ["request-depot"] = request_depot,
  ["supply-depot"] = supply_depot,
}

local get_depot = function(entity)
  return supply_depot.get_depot(entity) or request_depot.get_depot(entity)
end

local corpse_offsets = 
{
  [0] = {0, -2},
  [2] = {2, 0},
  [4] = {0, 2},
  [6] = {-2, 0},
}

local get_corpse_position = function(entity)

  local position = entity.position
  local direction = entity.direction
  local offset = corpse_offsets[direction]
  return {position.x + offset[1], position.y + offset[2]}

end

local attempt_to_place_node = function(entity)
  local corpse_position = get_corpse_position(entity)
  local surface = entity.surface

  if not surface.can_place_entity(
    {
      name = "road-tile-collision-proxy",
      position = corpse_position,
      build_check_type = defines.build_check_type.manual
    }) then
    surface.create_entity{name = "flying-text", text = "Road placement blocked", position = corpse_position}
    return
  end

  local node_position = {math.floor(corpse_position[1]), math.floor(corpse_position[2])}
  surface.set_tiles
  {
    {name = "transport-drone-road", position = node_position}
  }

  road_network.add_node(surface.index, node_position[1], node_position[2])
  return true
end

local refund_build = function(event, item_name)
  if event.player_index then
    game.get_player(event.player_index).insert{name = item_name, count = 1}
    return
  end

  if event.robot and event.robot.valid then
    event.robot.get_inventory(defines.inventory.robot_cargo).insert({name = item_name, count = 1})
    return
  end
end

local on_created_entity = function(event)
  local entity = event.entity or event.created_entity
  if not (entity and entity.valid) then return end

  local depot_lib = depot_names[entity.name]
  if not depot_lib then
    return
  end

  if not attempt_to_place_node(entity) then
    --refund
    refund_build(event, entity.name)
    entity.destroy()
    return
  end
  
  depot_lib.new(entity)
end

local on_entity_removed = function(event)
  local entity = event.entity

  if not (entity and entity.valid) then return end

  local depot = get_depot(entity)
  if depot then
    depot:on_removed()
  end

end

local lib = {}

lib.events = 
{
  [defines.events.on_built_entity] = on_created_entity,
  [defines.events.on_robot_built_entity] = on_created_entity,
  [defines.events.script_raised_built] = on_created_entity,
  [defines.events.script_raised_revive] = on_created_entity,

  [defines.events.on_entity_died] = on_entity_removed,
  [defines.events.on_robot_mined_entity] = on_entity_removed,
  [defines.events.script_raised_destroy] = on_entity_removed,
  [defines.events.on_player_mined_entity] = on_entity_removed,
}

return lib