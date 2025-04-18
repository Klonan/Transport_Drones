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
-- add_depot_lib("mining-depot", require("script/depots/mining_depot"))
add_depot_lib("fluid-depot", require("script/depots/fluid_depot"))
add_depot_lib("buffer-depot", require("script/depots/buffer_depot"))
add_depot_lib("road-network-reader", require("script/depots/network_reader"))

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
  update_rate = 60,
  reset_fuel_on_the_way = true
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

local mineable_tiles
local is_tile_mineable = function(name)
  if not mineable_tiles then
    mineable_tiles = {}
    for _, tile in pairs (prototypes.tile) do
      if tile.mineable_properties and tile.mineable_properties.minable then
        mineable_tiles[tile.name] = true
      end
    end
  end
  return mineable_tiles[name]
end

local attempt_to_place_node = function(entity, depot_lib)
  local corpse_position = get_corpse_position(entity, depot_lib.corpse_offsets)
  local surface = entity.surface

  local node_position = {math.floor(corpse_position[1]), math.floor(corpse_position[2])}

  if road_network.get_node(surface.index, node_position[1], node_position[2]) then
    --Already a node here, don't worry
    return true
  end

  local hidden_tile = surface.get_tile(node_position).name
  if not is_tile_mineable(hidden_tile) then
    surface.set_hidden_tile(node_position, hidden_tile)
  end

  local tiles = { {name = "transport-drone-road", position = node_position} }
  surface.set_tiles(tiles, false, "abort_on_collision", false, true)

  if road_network.get_node(surface.index, node_position[1], node_position[2]) then
    return true
  end

  return false
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
  local node = road_network.get_node(depot.surface_index, depot.node_position[1], depot.node_position[2])

  if not node then
    depot:on_removed({})
    depot.entity.destroy()
    --log("Wtf, depot with no node... killing it"..serpent.line(depot))
    return true
  end
  node.depots = node.depots or {}
  node.depots[depot.index] = depot
end

local remove_depot_from_node = function(surface, x, y, depot_index)
  local node = road_network.get_node(surface, x, y)
  if not node then return end
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

local circuit_offsets =
{
  [0] = {0, 1},
  [4] = {-1, 0},
  [8] = {0, -1},
  [12] = {1, 0},
}

local circuit_writer_built = function(entity)
  local offset = circuit_offsets[entity.direction]
  if not offset then error("HEUK") end
  local search_position = entity.position
  search_position.x = search_position.x + offset[1]
  search_position.y = search_position.y + offset[2]
  entity.rotatable = false

  for k, found_entity in pairs (entity.surface.find_entities_filtered{position = search_position}) do
    local this_depot = get_depot(found_entity)
    if this_depot then

      if not (this_depot.circuit_writer and this_depot.circuit_writer.valid) then
        this_depot.circuit_writer = entity
        this_depot:say("Circuit writer attached")
        return
      end
    end
  end
end

local circuit_reader_built = function(entity)
  local offset = circuit_offsets[entity.direction]
  if not offset then error("HEUK") end
  local search_position = entity.position
  search_position.x = search_position.x + offset[1]
  search_position.y = search_position.y + offset[2]

  entity.rotatable = false

  local attached = false

  for k, found_entity in pairs (entity.surface.find_entities_filtered{position = search_position}) do
    local this_depot = get_depot(found_entity)
    if this_depot then
      if not (this_depot.circuit_reader and this_depot.circuit_reader.valid) then
        this_depot.circuit_reader = entity
        this_depot:say("Circuit reader attached")
        attached = true
        break
      end
    end
  end

  if attached then
    rendering.draw_sprite
    {
      sprite = "utility/fluid_indication_arrow",
      surface = entity.surface,
      only_in_alt_mode = true,
      target = entity,
      target_offset = {offset[1] / 2, offset[2] / 2},
      orientation_target = entity
    }
  end

end

local on_created_entity = function(event)
  local entity = event.entity or event.created_entity
  if not (entity and entity.valid) then return end

  local name = entity.name

  if name == "transport-depot-writer" then
    circuit_writer_built(entity)
    return
  end

  if name == "transport-depot-reader" then
    circuit_reader_built(entity)
    return
  end

  local depot_lib = depot_libs[name]
  if not depot_lib then
    return
  end

  if not attempt_to_place_node(entity, depot_lib) then
    --refund
    refund_build(event, entity.prototype)
    entity.destroy({raise_destroy = true})
    return
  end

  local depot = depot_lib.new(entity, event.tags)
  script.register_on_object_destroyed(entity)
  depot.surface_index = entity.surface.index
  script_data.depots[depot.index] = depot
  if add_depot_to_node(depot) then
    return
  end
  depot:add_to_network()
  add_to_update_bucket(depot.index)

  for k, entity in pairs (entity.surface.find_entities_filtered{name = "transport-depot-writer", radius = entity.get_radius() + 1, position = entity.position}) do
    circuit_writer_built(entity)
  end

  for k, entity in pairs (entity.surface.find_entities_filtered{name = "transport-depot-reader", radius = entity.get_radius() + 1, position = entity.position}) do
    circuit_reader_built(entity)
  end

end

local remove_depot = function(depot, event)
  depot:remove_from_network()
  local surface = depot.surface_index
  local index = depot.index
  local x, y = depot.node_position[1], depot.node_position[2]
  remove_depot_from_node(surface, x, y, index)
  -- log("Depot: " .. serpent.block(script_data.depots))
  -- log("type: " .. type(index) .. "index: " .. index)
  script_data.depots[index] = nil
  depot:on_removed(event)
end

local on_entity_removed = function(event)
  local entity = event.entity

  if not (entity and entity.valid) then return end

  local depot = get_depot(entity)
  if depot then
    remove_depot(depot, event)
  end

end

local on_entity_destroyed = function(event)
  local unit_number = event.unit_number
  if not unit_number then return end

  local depot = get_depot_by_index(tostring(unit_number))
  if depot then
    remove_depot(depot, event)
  end
end

local get_lib = function(depot)
  if not depot.entity.valid then
    return {}
  end
  local name = depot.entity.name
  return depot_libs[name]
end

local load_depot = function(depot)
  local lib = get_lib(depot)
  if lib.metatable then
    setmetatable(depot, lib.metatable)
  end
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
end

local on_runtime_mod_setting_changed = function(event)
  refresh_update_rate()
end

local picker_dolly_blacklist = function()

  if remote.interfaces["PickerDollies"] then
    for name, depot_lib in pairs (depot_libs) do
      remote.call("PickerDollies", "add_blacklist_name", name, true)
    end
  end

end

local get_tags = function(blueprint_entity, surface)
  local name = blueprint_entity.name
  local lib = depot_libs[name]
  if not lib then return end

  if name == "supply-depot" then
    name = "supply-depot-chest"
  end

  local entity = surface.find_entity(name, blueprint_entity.position)
  if not entity then return end

  local depot = get_depot(entity)
  if not depot then return end

  local saver = depot.save_to_blueprint_tags
  if not saver then return end

  return saver(depot)
end


local on_player_setup_blueprint = function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end

  local item = player.cursor_stack
  if not (item and item.valid_for_read) then
    item = player.blueprint_to_setup
    if not (item and item.valid_for_read) then return end
  end

  local entities = item.get_blueprint_entities()
  if not (entities and next(entities)) then return end

  local surface = player.surface

  for index, blueprint_entity in pairs(entities) do
    local tags = get_tags(blueprint_entity, surface)
    if tags then
      item.set_blueprint_entity_tag(index, "transport_depot_tags", tags)
    end
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
  [defines.events.on_object_destroyed] = on_entity_destroyed,

  [defines.events.on_player_setup_blueprint] = on_player_setup_blueprint,

  [defines.events.on_tick] = on_tick,
  [defines.events.on_runtime_mod_setting_changed] = on_runtime_mod_setting_changed
}

lib.on_init = function()
  storage.transport_depots = storage.transport_depots or script_data
  setup_lib_values()
  refresh_update_rate()
  picker_dolly_blacklist()
end

lib.on_load = function()
  script_data = storage.transport_depots or script_data
  setup_lib_values()
  for k, depot in pairs (script_data.depots) do
    load_depot(depot)
  end
end



lib.on_configuration_changed = function()

  storage.transport_depots = storage.transport_depots or script_data

  for k, depot in pairs (script_data.depots) do
    if not depot.entity.valid then
      script_data.depots[k] = nil
    else
      script.register_on_object_destroyed(depot.entity)
      depot.surface_index = depot.entity.surface.index
      if depot.on_config_changed then
        depot:on_config_changed()
      end
      if not add_depot_to_node(depot) then
        depot:remove_from_network()
        depot:add_to_network()
        if depot.to_be_taken then
          depot.to_be_taken = {}
        end
        if depot.fuel_on_the_way then
          depot.fuel_on_the_way = 0
        end
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

  picker_dolly_blacklist()
end

lib.get_depot = function(entity)
  return script_data.depots[tostring(entity.unit_number)]
end

lib.get_depot_by_index = get_depot_by_index

return lib
