local request_depot = require("script/depots/request_depot")
local supply_depot = require("script/depots/supply_depot")
local fuel_depot = require("script/depots/fuel_depot")
local mining_depot = require("script/depots/mining_depot")
local road_network = require("script/road_network")

local depot_names = 
{
  ["request-depot"] = request_depot,
  ["supply-depot"] = supply_depot,
  ["supply-depot-chest"] = supply_depot,
  ["fuel-depot"] = fuel_depot,
  ["mining-depot"] = mining_depot,
}

local script_data = 
{
  depots = {},
  update_order = {},
  last_update_index = 0
}

local get_depot = function(entity)
  return script_data.depots[tostring(entity.unit_number)]
end

local corpse_offsets = 
{
  [0] = {0, -2},
  [2] = {2, 0},
  [4] = {0, 2},
  [6] = {-2, 0},
}

local get_corpse_position = function(entity, corpse_offsets)

  local position = entity.position
  local direction = entity.direction
  local offset = corpse_offsets[direction]
  return {position.x + offset[1], position.y + offset[2]}

end

local attempt_to_place_node = function(entity, depot_lib)
  local corpse_position = get_corpse_position(entity, depot_lib.corpse_offsets)
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

  if not attempt_to_place_node(entity, depot_lib) then
    --refund
    refund_build(event, entity.name)
    entity.destroy()
    return
  end
  
  local depot = depot_lib.new(entity)
  script_data.depots[depot.index] = depot
  script_data.update_order[#script_data.update_order + 1] = depot.index
end

local on_entity_removed = function(event)
  local entity = event.entity

  if not (entity and entity.valid) then return end

  local depot = get_depot(entity)
  if depot then
    depot:on_removed()
  end

end

local load_depot = function(depot)
  local name = depot.entity.name
  local depot_lib = depot_names[name]
  if not depot_lib then
    return
  end
  depot_lib.load(depot)
end

local migrate_depots = function()

  local depots = {}
  local update_order = {}

  local count = 1

  local request_depots = global.request_depots.request_depots
  for k, v in pairs (request_depots) do
    depots[k] = v
    update_order[count] = k
    count = count + 1
  end
  global.request_depots = nil
  
  local supply_depots = global.supply_depots.supply_depots
  for k, v in pairs (supply_depots) do
    depots[k] = v
    update_order[count] = k
    count = count + 1
  end
  global.supply_depots = nil
  
  script_data.depots = depots
  script_data.update_order = update_order

  
  for k, depot in pairs (script_data.depots) do
    load_depot(depot)
  end

end

local shuffle_table = util.shuffle_table
local update_next_depot = function()
  local index = script_data.last_update_index
  local depots = script_data.update_order
  
  local depot_index = depots[index]
  if not depot_index then
    shuffle_table(depots)
    script_data.last_update_index = 1
    return
  end

  local depot = script_data.depots[depot_index]
  if not depot then
    depots[index], depots[#depots] = depots[#depots], nil
    return
  end
  
  depot:update()
  --depot:say(index)
  script_data.last_update_index = index + 1
end

local on_tick = function(event)
  update_next_depot()
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

  [defines.events.on_tick] = on_tick
}

lib.on_init = function()
  global.transport_depots = global.transport_depots or script_data
end

lib.on_load = function()
  script_data = global.transport_depots or script_data
  for k, depot in pairs (script_data.depots) do
    load_depot(depot)
  end
end


lib.on_configuration_changed = function()
  if global.request_depots then
    migrate_depots()
  end
end

lib.get_depot = function(entity)
  return script_data.depots[tostring(entity.unit_number)]
end

return lib