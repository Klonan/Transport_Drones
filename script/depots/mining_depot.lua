local mining_depot = {}
mining_depot.metatable = {__index = mining_depot}

mining_depot.corpse_offsets = 
{
  [0] = {0, -3},
  [2] = {3, 0},
  [4] = {0, 3},
  [6] = {-3, 0},
}

local get_corpse_position = function(entity)

  local position = entity.position
  local direction = entity.direction
  local offset = mining_depot.corpse_offsets[direction]
  return {position.x + offset[1], position.y + offset[2]}

end

function mining_depot.new(entity)

  local force = entity.force
  local surface = entity.surface

  entity.active = false
  entity.rotatable = false

  local corpse_position = get_corpse_position(entity)
  local corpse = surface.create_entity{name = "invisible-transport-caution-corpse", position = corpse_position}
  corpse.corpse_expires = false
  
  local depot =
  {
    entity = entity,
    corpse = corpse,
    index = tostring(entity.unit_number),
    node_position = {math.floor(corpse_position[1]), math.floor(corpse_position[2])},
    to_be_taken = {},
  }
  setmetatable(depot, mining_depot.metatable)

  depot:add_to_node()
  depot:add_to_network()

  return depot

end

function mining_depot:get_to_be_taken(name)
  return self.to_be_taken[name] or 0
end


function mining_depot:check_requests_for_item(name, count)

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

function mining_depot:update()
  if not self.network_id then return end
  local items = self.entity.get_output_inventory().get_contents()
  for name, count in pairs(items) do
    self:check_requests_for_item(name, count)
  end
  --self:say("U")
end

function mining_depot:say(string)
  self.entity.surface.create_entity{name = "flying-text", position = self.entity.position, text = string}
end

function mining_depot:give_item(requested_name, requested_count)
  local inventory = self.entity.get_output_inventory()
  local removed_count = inventory.remove({name = requested_name, count = requested_count})
  return removed_count
end

function mining_depot:add_to_be_taken(name, count)
  --if not (name and count) then return end
  self.to_be_taken[name] = (self.to_be_taken[name] or 0) + count
  --self:say(self.to_be_taken[name])
end

function mining_depot:get_available_item_count(name)
  return self.entity.get_output_inventory().get_item_count(name) - self:get_to_be_taken(name)
end

function mining_depot:remove_from_network()

  local network = self.road_network.get_network_by_id(self.network_id)

  if not network then return end
  
  local mining = network.mining

  mining[self.index] = nil
  self.network_id = nil

end

function mining_depot:add_to_node()
  local node = self.road_network.get_node(self.entity.surface.index, self.node_position[1], self.node_position[2])
  node.depots = node.depots or {}
  node.depots[self.index] = self
end

function mining_depot:remove_from_node()
  local surface = self.entity.surface.index
  local node = self.road_network.get_node(surface, self.node_position[1], self.node_position[2])
  node.depots[self.index] = nil
  self.road_network.check_clear_lonely_node(surface, self.node_position[1], self.node_position[2])
end

function mining_depot:add_to_network()
  --self:say("Adding to network")
  self.network_id = self.road_network.add_mining_depot(self)
end

function mining_depot:on_removed()
  self:remove_from_network()
  self:remove_from_node()
  self.corpse.destroy()
end

return mining_depot