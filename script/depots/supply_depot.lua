local supply_depot = {}

supply_depot.metatable = {__index = supply_depot}

supply_depot.corpse_offsets = 
{
  [0] = {0, -2},
  [2] = {2, 0},
  [4] = {0, 2},
  [6] = {-2, 0},
}

function supply_depot.new(entity)
  local position = entity.position
  local direction = entity.direction
  local force = entity.force
  local surface = entity.surface
  local offset = supply_depot.corpse_offsets[direction]
  entity.destructible = false
  entity.minable = false
  entity.rotatable = false  
  entity.active = false
  local chest = surface.create_entity{name = "supply-depot-chest", position = position, force = force, player = entity.last_user}
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
  setmetatable(depot, supply_depot.metatable)

  depot:add_to_network()
  depot:add_to_node()

  return depot
  
end

function supply_depot:get_to_be_taken(name)
  return self.to_be_taken[name] or 0
end

function supply_depot:check_requests_for_item(name, count)

  if count - self:get_to_be_taken(name) <= 0 then
    return
  end

  local buffer_depots = self.road_network.get_buffer_depots(self.network_id, name, self.node_position)
  if buffer_depots then
    local size = #buffer_depots
    if size > 0 then
      for k = 1, size do
        local depot = buffer_depots[k]
        local available = count - self:get_to_be_taken(name)
        if available <= 0 then return end
        depot:handle_offer(self, name, available)
      end
    end
  end

  local request_depots = self.road_network.get_request_depots(self.network_id, name, self.node_position)
  if request_depots then
    local size = #request_depots
    if size > 0 then
      for k = 1, size do
        local depot = request_depots[k]
        local available = count - self:get_to_be_taken(name)
        if available <= 0 then return end
        depot:handle_offer(self, name, available)
      end
    end
  end

end

function supply_depot:check_network()
  local network = self.road_network.get_network_by_id(self.network_id)
  if not network then
    self:add_to_network()
  end
  return true
end

function supply_depot:update()
  self:check_network()
  local items = self.entity.get_output_inventory().get_contents()
  for name, count in pairs(items) do
    self:check_requests_for_item(name, count)
  end
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

  local network = self.road_network.get_network_by_id(self.network_id)
  
  if not network then return end

  local supply = network.supply

  supply[self.index] = nil

  self.network_id = nil

end

function supply_depot:add_to_node()
  local node = self.road_network.get_node(self.entity.surface.index, self.node_position[1], self.node_position[2])
  node.depots = node.depots or {}
  node.depots[self.index] = self
end

function supply_depot:remove_from_node()
  local surface = self.entity.surface.index
  local node = self.road_network.get_node(surface, self.node_position[1], self.node_position[2])
  node.depots[self.index] = nil
  self.road_network.check_clear_lonely_node(surface, self.node_position[1], self.node_position[2])
end

function supply_depot:add_to_network()
  self.network_id = self.road_network.add_supply_depot(self)
end

function supply_depot:on_removed(event)

  self:remove_from_network()
  self:remove_from_node()
  self.corpse.destroy()
  self.assembler.destructible = true
  
  if event.name == defines.events.on_entity_died then
    self.entity.destroy()
    self.assembler.die()
  else
    self.assembler.destroy()    
  end
end

return supply_depot