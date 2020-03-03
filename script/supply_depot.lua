local request_depot = require("script/request_depot")
local road_network = require("script/road_network")

local script_data = 
{
  supply_depots = {}
}

local corpse_offsets = 
{
  [0] = {0, -2},
  [2] = {2, 0},
  [4] = {0, 2},
  [6] = {-2, 0},
}

local supply_depot = {}
local depot_metatable = {__index = supply_depot}

function supply_depot.new(entity)
  local position = entity.position
  local direction = entity.direction
  local force = entity.force
  local surface = entity.surface
  local offset = corpse_offsets[direction]
  entity.destroy()
  local chest = surface.create_entity{name = "supply-depot-chest", position = position, force = force}
  local corpse_position = {position.x + offset[1], position.y + offset[2]}
  local corpse = surface.create_entity{name = "caution-corpse", position = corpse_position}
  corpse.corpse_expires = false

  local depot =
  {
    entity = chest,
    corpse = corpse,
    to_be_taken = {},
    node_position = {math.floor(corpse_position[1]), math.floor(corpse_position[2])},
    index = tostring(chest.unit_number)
  }
  setmetatable(depot, depot_metatable)

  
  script_data.supply_depots[depot.index] = depot
  depot:add_to_network()

end

function supply_depot:check_requests_for_item(name, count)

  local to_be_taken_count = self.to_be_taken[name] or 0
  local available = count - to_be_taken_count
  if available <= 0 then return end

  local request_depots = road_network.get_request_depots(self.network_id, name)
  if not request_depots then return end
  if not next(request_depots) then return end

  for k, depot in pairs (request_depots) do
    local requested = depot:handle_offer(self, name, count)
    self.to_be_taken[name] = (self.to_be_taken[name] or 0) + requested
    count = count - requested
    if count <= 0 then return end
  end

end

function supply_depot:update()
  if not self.network_id then return end
  local items = self.entity.get_output_inventory().get_contents()
  for name, count in pairs(items) do
    self:check_requests_for_item(name, count)
  end
  --self:say("oh hi :)")
end

function supply_depot:say(string)
  self.entity.surface.create_entity{name = "flying-text", position = self.entity.position, text = string}
end

function supply_depot:give_item(requested_name, requested_count)
  self.to_be_taken[requested_name] = self.to_be_taken[requested_name] - requested_count
  local inventory = self.entity.get_output_inventory()
  local removed_count = inventory.remove({name = requested_name, count = requested_count})
  return removed_count
end

function supply_depot:remove_from_network()

  
  local node = road_network.get_node(self.entity.surface.index, self.node_position[1], self.node_position[2])
  node.supply[self.index] = nil

  local network = road_network.get_network_by_id(self.network_id)

  local supply = network.supply

  supply[self.index] = nil

  self.network_id = nil

end

function supply_depot:add_to_network()
  self.network_id = road_network.add_supply_depot(self)
end

function supply_depot:on_removed()
  self:remove_from_network()
  self.corpse.destroy()
  script_data.supply_depots[self.index] = nil
  game.print("ded")
end

local on_created_entity = function(event)
  local entity = event.entity or event.created_entity
  if not (entity and entity.valid) then return end

  if entity.name ~= "supply-transport-depot" then return end

  supply_depot.new(entity)
end

local update_depots = function(event)
  for k, depot in pairs (script_data.supply_depots) do
    depot:update()
  end
end

local on_entity_removed = function(event)
  local entity = event.entity
  game.print("heya")

  if not (entity and entity.valid) then return end

  if entity.name ~= "supply-depot-chest" then return end

  local index = tostring(entity.unit_number)
  local depot = script_data.supply_depots[index]
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
  [defines.events.on_player_mined_entity] = on_entity_removed

}

lib.on_nth_tick =
{
  [60] = update_depots
}

lib.on_init = function()
  global.supply_depots = global.supply_depots or script_data
end

lib.on_load = function()
  script_data = global.supply_depots or script_data
  for k, depot in pairs (script_data.supply_depots) do
    setmetatable(depot, depot_metatable)
  end
end

return lib