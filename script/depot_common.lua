local transport_drone = require("script/transport_drone")
local road_network = require("script/road_network")
local transport_technologies = require("script/transport_technologies")

local depot_libs = {}

local required_interfaces =
{
  corpse_offsets = "table",
  metatable = "table",
  new = "function",
  on_removed = "function",
  update = "function"
}

local add_depot_lib = function(entity_name, lib)
  for name, value_type in pairs (required_interfaces) do
    if not lib[name] or type(lib[name]) ~= value_type then
      error("Trying to add lib without all required interfaces: "..serpent.block(
        {
          entity_name = entity_name,
          missing_value_key = name,
          value_type = type(lib[name]),
          expected_type = value_type
        }))
    end
  end
  depot_libs[entity_name] = lib
end

add_depot_lib("request-depot", require("script/depots/request_depot"))
add_depot_lib("supply-depot", require("script/depots/supply_depot"))
add_depot_lib("supply-depot-chest", require("script/depots/supply_depot"))
add_depot_lib("fuel-depot", require("script/depots/fuel_depot"))
add_depot_lib("mining-depot", require("script/depots/mining_depot"))
add_depot_lib("fluid-depot", require("script/depots/fluid_depot"))
add_depot_lib("buffer-depot", require("script/depots/buffer_depot"))

local match = "transport_drones_add_"
for name, setting in pairs (settings.startup) do
  if name:find(match) then
    local lib_name = name:sub(match:len() + 1)
    local path = setting.value
    add_depot_lib(lib_name, require(path))
  end
end

local script_data = 
{
  depots = {},
  update_buckets = {},
  reset_to_be_taken_again = true,
  refresh_techs = true,
  update_rate = 60
}

local get_depot_by_index = function(index)
  return script_data.depots[index]
end

local get_depot = function(entity)
  return get_depot_by_index(tostring(entity.unit_number))
end


local get_corpse_position = function(entity, corpse_offsets)

  local position = entity.position
  local direction = entity.direction
  local offset = corpse_offsets[direction]
  return {position.x + offset[1], position.y + offset[2]}

end

local attempt_to_place_node = function(entity, depot_lib, event)
  local corpse_position = get_corpse_position(entity, depot_lib.corpse_offsets)
  local surface = entity.surface
  
  local node_position = {math.floor(corpse_position[1]), math.floor(corpse_position[2])}

  if road_network.get_node(surface.index, node_position[1], node_position[2]) then
    --Already a node here, don't worry
    return true
  end

  if not surface.can_place_entity(
    {
      name = "road-tile-collision-proxy",
      position = corpse_position,
      build_check_type = defines.build_check_type.manual
    }) then
    surface.create_entity{name = "flying-text", text = "Road placement blocked", position = corpse_position}
    return
  end

  surface.set_hidden_tile(node_position, surface.get_tile(node_position).name)
  surface.set_tiles
  {
    {name = "transport-drone-road", position = node_position}
  }

  road_network.add_node(surface.index, node_position[1], node_position[2])
  return true
end

local refund_build = function(event, entity_prototype)

  local item = entity_prototype.items_to_place_this[1]
  if not item then return end

  if event.player_index then
    game.get_player(event.player_index).insert(item)
    return
  end

  if event.robot and event.robot.valid then
    event.robot.get_inventory(defines.inventory.robot_cargo).insert(item)
    return
  end
end

local add_depot_to_node = function(depot)
  local node = road_network.get_node(depot.entity.surface.index, depot.node_position[1], depot.node_position[2])
  node.depots = node.depots or {}
  node.depots[depot.index] = depot
end

local remove_depot_from_node = function(surface, x, y, depot_index)
  local node = road_network.get_node(surface, x, y)
  node.depots[depot_index] = nil
  road_network.check_clear_lonely_node(surface, x, y)
end

local big = math.huge
local insert = table.insert
local add_to_update_bucket = function(index)
  local best_bucket
  local best_count = big
  local buckets = script_data.update_buckets
  for k = 1, script_data.update_rate do
    local bucket_index = k % script_data.update_rate
    local bucket = buckets[bucket_index]
    if not bucket then
      bucket = {}
      buckets[bucket_index] = bucket
      best_bucket = bucket
      best_count = 0
      break
    end
    local size = #bucket
    if size < best_count then
      best_bucket = bucket
      best_count = size
    end
  end
  best_bucket[best_count + 1] = index
end

local on_created_entity = function(event)
  local entity = event.entity or event.created_entity
  if not (entity and entity.valid) then return end

  local depot_lib = depot_libs[entity.name]
  if not depot_lib then
    return
  end

  if not attempt_to_place_node(entity, depot_lib, event) then
    --refund
    refund_build(event, entity.prototype)
    entity.destroy({raise_destroy = true})
    return
  end
  
  local depot = depot_lib.new(entity)
  script_data.depots[depot.index] = depot
  add_depot_to_node(depot)
  depot:add_to_network()
  add_to_update_bucket(depot.index)

end


local on_entity_removed = function(event)
  local entity = event.entity

  if not (entity and entity.valid) then return end

  local depot = get_depot(entity)

  if depot then
    depot:remove_from_network()
    local surface = depot.entity.surface
    local index = depot.index
    local x, y = depot.node_position[1], depot.node_position[2]
    remove_depot_from_node(surface.index, x, y, index)
    script_data.depots[index] = nil
    depot:on_removed(event)
  end

end

local get_lib = function(depot)
  local name = depot.entity.name
  return depot_libs[name]
end

local load_depot = function(depot)
  local lib = get_lib(depot)
  if lib.metatable then
    setmetatable(depot, lib.metatable)
  end
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


  game.print("Transport drones 0.2.0 update:")
  game.print("I added fuel depots and fluid depots. The transport drones now need petroleum to work properly, sorry for any inconvenience.")
  game.print("Thanks for playing with my mod.")

end

local update_depots = function(tick)
  local bucket_index = tick % script_data.update_rate
  local update_list = script_data.update_buckets[bucket_index]
  if not update_list then return end

  local depots = script_data.depots

  local k = 1
  while true do
    local depot_index = update_list[k]
    if not depot_index then return end
    local depot = depots[depot_index]
    if not (depot and depot.entity.valid) then
      depots[depot_index] = nil
      local last = #update_list
      if k == last then
        update_list[k] = nil
      else
        update_list[k], update_list[last] = update_list[last], nil
      end
    else
      depot:update()
      k = k + 1
    end
  end

end

local on_tick = function(event)
  update_depots(event.tick)
end

local setup_lib_values = function()

  for k, lib in pairs (depot_libs) do
    lib.road_network = road_network
    lib.transport_drone = transport_drone
    lib.transport_technologies = transport_technologies
    lib.get_depot = get_depot_by_index
  end

end

local insert = table.insert
local refresh_update_buckets = function()
  local count = 1
  local interval = script_data.update_rate
  local buckets = {}
  for index, depot in pairs (script_data.depots) do
    local bucket_index = count % interval
    buckets[bucket_index] = buckets[bucket_index] or {}
    insert(buckets[bucket_index], index)
    count = count + 1
  end
  script_data.update_buckets = buckets
end

local refresh_update_rate = function()
  local update_rate = settings.global["transport-depot-update-interval"].value
  if script_data.update_rate == update_rate then return end
  script_data.update_rate = update_rate
  refresh_update_buckets()
  --game.print(script_data.update_rate)
end

local on_runtime_mod_setting_changed = function(event)
  refresh_update_rate()
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

  [defines.events.on_tick] = on_tick,
  [defines.events.on_runtime_mod_setting_changed] = on_runtime_mod_setting_changed,

}

lib.on_init = function()
  global.transport_depots = global.transport_depots or script_data
  setup_lib_values()
  refresh_update_rate()
end

lib.on_load = function()
  script_data = global.transport_depots or script_data
  setup_lib_values()
  for k, depot in pairs (script_data.depots) do
    if depot.entity.valid then
      --Not sure if I should remove it here, as it will cry "oh modifying global during on load wtf"
      load_depot(depot)
    end
  end
end

lib.on_configuration_changed = function()

  global.transport_depots = global.transport_depots or script_data

  if global.request_depots then
    migrate_depots()
  end

  for k, depot in pairs (script_data.depots) do
    if not depot.entity.valid then
      script_data.depots[k] = nil
    else
      if depot.on_config_changed then
        depot:on_config_changed()
      end
      add_depot_to_node(depot)
      depot:remove_from_network()
      depot:add_to_network()
    end
  end

  if not script_data.reset_to_be_taken_again then
    script_data.reset_to_be_taken_again = true
    for k, depot in pairs (script_data.depots) do
      if depot.to_be_taken then
        depot.to_be_taken = {}
      end
    end
  end

  if not script_data.refresh_techs then
    script_data.refresh_techs = true
    for k, force in pairs (game.forces) do
      force.reset_technology_effects()
    end
  end

  refresh_update_rate()

end

lib.get_depot = function(entity)
  return script_data.depots[tostring(entity.unit_number)]
end

lib.get_depot_by_index = get_depot_by_index

return lib