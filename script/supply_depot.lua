local request_depot = require("script/request_depot")
local road_network = require("script/road_network")

local script_data = 
{
  supply_depots = {},
  blueprint_correction_data = {}
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
  entity.destructible = false
  entity.minable = false
  entity.rotatable = false  
  local chest = surface.create_entity{name = "supply-depot-chest", position = position, force = force}
  local corpse_position = {position.x + offset[1], position.y + offset[2]}
  local corpse = surface.create_entity{name = "transport-caution-corpse", position = corpse_position}
  corpse.corpse_expires = false

  local depot =
  {
    entity = chest,
    assembler = entity,
    corpse = corpse,
    to_be_taken = {},
    node_position = {math.floor(corpse_position[1]), math.floor(corpse_position[2])},
    index = tostring(chest.unit_number)
  }
  setmetatable(depot, depot_metatable)

  
  script_data.supply_depots[depot.index] = depot
  depot:add_to_network()
  depot:add_to_node()

end

function supply_depot:get_to_be_taken(name)
  return self.to_be_taken[name] or 0
end

function supply_depot:check_requests_for_item(name, count)

  if count - self:get_to_be_taken(name) <= 0 then return end

  local request_depots = road_network.get_request_depots(self.network_id, name)
  if not request_depots then return end
  if not next(request_depots) then return end

  for k, depot in pairs (request_depots) do
    local available = count - self:get_to_be_taken(name)
    if available <= 0 then return end
    depot:handle_offer(self, name, available)
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
  local inventory = self.entity.get_output_inventory()
  local removed_count = inventory.remove({name = requested_name, count = requested_count})
  return removed_count
end

function supply_depot:add_to_be_taken(name, count)
  --if not (name and count) then return end
  self.to_be_taken[name] = (self.to_be_taken[name] or 0) + count
  --self:say(self.to_be_taken[name])
end

function supply_depot:get_available_item_count(name)
  return self.entity.get_output_inventory().get_item_count(name) - self:get_to_be_taken(name)
end

function supply_depot:remove_from_network()

  local network = road_network.get_network_by_id(self.network_id)

  local supply = network.supply

  supply[self.index] = nil

  self.network_id = nil

end

function supply_depot:add_to_node()
  local node = road_network.get_node(self.entity.surface.index, self.node_position[1], self.node_position[2])
  node.depots = node.depots or {}
  node.depots[self.index] = self
end

function supply_depot:remove_from_node()
  local surface = self.entity.surface.index
  local node = road_network.get_node(surface, self.node_position[1], self.node_position[2])
  node.depots[self.index] = nil
  road_network.check_clear_lonely_node(surface, self.node_position[1], self.node_position[2])
end

function supply_depot:add_to_network()
  --self:say("Adding to network") 
  self.network_id = road_network.add_supply_depot(self)
end

function supply_depot:on_removed()
  self:remove_from_node()
  self:remove_from_network()
  self.corpse.destroy()
  self.assembler.destructible = true
  self.assembler.destroy()
  script_data.supply_depots[self.index] = nil
end

local update_next_depot = function()
  local index = script_data.last_update_index
  local depots = script_data.supply_depots
  if index and not depots[index] then
    index = nil
  end
  local update_depot
  index, update_depot = next(depots, index)
  script_data.last_update_index = index
  if not index then
    return
  end
  update_depot:update()
  --update_depot:say("U")
end

local on_tick = function(event)
  --for k = 1, 20 do
    update_next_depot()
  --end
end

local lib = {}

lib.events =
{ 
  [defines.events.on_tick] = on_tick,  
}

lib.on_nth_tick =
{
  --[1] = update_depots
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

lib.get_depot = function(entity)
  return script_data.supply_depots[tostring(entity.unit_number)]
end

lib.new = supply_depot.new

return lib