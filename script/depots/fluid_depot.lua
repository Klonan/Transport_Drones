local request_depot = require("script/depots/request_depot")
local road_network = require("script/road_network")

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


local fluid_depot = {}
local depot_metatable = {__index = fluid_depot}

function fluid_depot.new(entity)
  
  local force = entity.force
  local surface = entity.surface

  --entity.active = false
  entity.rotatable = false

  local corpse_position = get_corpse_position(entity)
  local corpse = surface.create_entity{name = "transport-caution-corpse", position = corpse_position}
  corpse.corpse_expires = false
  
  local depot =
  {
    entity = entity,
    corpse = corpse,
    to_be_taken = {},
    node_position = {math.floor(corpse_position[1]), math.floor(corpse_position[2])},
    index = tostring(entity.unit_number)
  }
  setmetatable(depot, depot_metatable)

  --depot:add_to_network()
  depot:add_to_node()

  return depot
  
end

function fluid_depot:get_to_be_taken(name)
  return self.to_be_taken[name] or 0
end

function fluid_depot:check_requests_for_item(name, count)

  if count - self:get_to_be_taken(name) <= 0 then return end

  local request_depots = road_network.get_request_depots(self.network_id, name)
  if not request_depots then return end
  if not next(request_depots) then return end

  for k, depot in pairs (request_depots) do
    local available = count - self:get_to_be_taken(name)
    if available <= 0 then return end
    depot:handle_offer(self, name, available)
    --depot:say(k)
  end

end

function fluid_depot:update()
  if not self.network_id then return end
  local items = self.entity.get_output_inventory().get_contents()
  for name, count in pairs(items) do
    self:check_requests_for_item(name, count)
  end
end

function fluid_depot:say(string)
  self.entity.surface.create_entity{name = "flying-text", position = self.entity.position, text = string}
end

function fluid_depot:give_item(requested_name, requested_count)
  local inventory = self.entity.get_output_inventory()
  local removed_count = inventory.remove({name = requested_name, count = requested_count})
  return removed_count
end

function fluid_depot:add_to_be_taken(name, count)
  --if not (name and count) then return end
  self.to_be_taken[name] = (self.to_be_taken[name] or 0) + count
  --self:say(self.to_be_taken[name])
end

function fluid_depot:get_available_item_count(name)
  return self.entity.get_output_inventory().get_item_count(name) - self:get_to_be_taken(name)
end

function fluid_depot:remove_from_network()

  local network = road_network.get_network_by_id(self.network_id)

  local supply = network.supply

  supply[self.index] = nil

  self.network_id = nil

end

function fluid_depot:add_to_node()
  local node = road_network.get_node(self.entity.surface.index, self.node_position[1], self.node_position[2])
  node.depots = node.depots or {}
  node.depots[self.index] = self
end

function fluid_depot:remove_from_node()
  local surface = self.entity.surface.index
  local node = road_network.get_node(surface, self.node_position[1], self.node_position[2])
  node.depots[self.index] = nil
  road_network.check_clear_lonely_node(surface, self.node_position[1], self.node_position[2])
end

function fluid_depot:add_to_network()
  --self:say("Adding to network") 
  self.network_id = road_network.add_fluid_depot(self)
end

function fluid_depot:on_removed()
  self:remove_from_network()
  self:remove_from_node()
  self.corpse.destroy()
  self.assembler.destructible = true
  self.assembler.destroy()
end


local lib = {}

lib.load = function(depot)
  setmetatable(depot, depot_metatable)
end

lib.new = fluid_depot.new

lib.corpse_offsets = corpse_offsets

return lib