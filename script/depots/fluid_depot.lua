local fluid_depot = {}

fluid_depot.metatable = {__index = fluid_depot}
fluid_depot.corpse_offsets = 
{
  [0] = {0, -2},
  [2] = {2, 0},
  [4] = {0, 2},
  [6] = {-2, 0},
}

local get_corpse_position = function(entity)

  local position = entity.position
  local direction = entity.direction
  local offset = fluid_depot.corpse_offsets[direction]
  return {position.x + offset[1], position.y + offset[2]}

end

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
  setmetatable(depot, fluid_depot.metatable)

  depot:add_to_network()
  depot:add_to_node()

  return depot
  
end

function fluid_depot:get_to_be_taken(name)
  return self.to_be_taken[name] or 0
end

function fluid_depot:check_requests_for_item(name, count)

  if count - self:get_to_be_taken(name) <= 0 then return end

  local request_depots = fluid_depot.road_network.get_request_depots(self.network_id, name)
  if not request_depots then return end
  if not next(request_depots) then return end

  for k, depot in pairs (request_depots) do
    local available = count - self:get_to_be_taken(name)
    if available <= 0 then return end
    depot:handle_offer(self, name, available)
    --depot:say(k)
  end

end

function fluid_depot:get_output_fluidbox()
  return self.entity.fluidbox[1]
end

function fluid_depot:set_output_fluidbox(box)
  self.entity.fluidbox[1] = box
end

function fluid_depot:update()
  if not self.network_id then return end

  local box = self:get_output_fluidbox()
  if not box then
    if not self.entity.active then
      self.entity.active = true
      self.entity.crafting_progress = 0
    end
    return
  end

  if self.entity.active then
    self.entity.active = false
  end

  self:check_requests_for_item(box.name, box.amount)
  --self:say("U")

end

function fluid_depot:say(string)
  self.entity.surface.create_entity{name = "flying-text", position = self.entity.position, text = string}
end

function fluid_depot:give_item(requested_name, requested_count)
  local box = self:get_output_fluidbox()
  
  if not box then return 0 end
  if box.name ~= requested_name then return 0 end

  if box.amount <= requested_count then
    self:set_output_fluidbox(nil)
    return box.amount
  end

  box.amount = box.amount - requested_count
  self:set_output_fluidbox(box)

  return requested_count
end

function fluid_depot:add_to_be_taken(name, count)
  --if not (name and count) then return end
  self.to_be_taken[name] = (self.to_be_taken[name] or 0) + count
  --self:say(self.to_be_taken[name])
end

function fluid_depot:get_available_item_count(name)
  local box = self:get_output_fluidbox()
  local amount = (box and box.name and box.name == name and box.amount) or 0
  return amount - self:get_to_be_taken(name)
end

function fluid_depot:remove_from_network()

  local network = fluid_depot.road_network.get_network_by_id(self.network_id)

  if not network then return end

  local supply = network.supply

  supply[self.index] = nil

  self.network_id = nil

end

function fluid_depot:add_to_node()
  local node = fluid_depot.road_network.get_node(self.entity.surface.index, self.node_position[1], self.node_position[2])
  node.depots = node.depots or {}
  node.depots[self.index] = self
end

function fluid_depot:remove_from_node()
  local surface = self.entity.surface.index
  local node = fluid_depot.road_network.get_node(surface, self.node_position[1], self.node_position[2])
  node.depots[self.index] = nil
  fluid_depot.road_network.check_clear_lonely_node(surface, self.node_position[1], self.node_position[2])
end

function fluid_depot:add_to_network()
  --self:say("Adding to network") 
  self.network_id = fluid_depot.road_network.add_supply_depot(self)
end

function fluid_depot:on_removed()
  self:remove_from_network()
  self:remove_from_node()
  self.corpse.destroy()
end

function fluid_depot:get_status_lines()
  return {
    {"supplying", serpent.line(self.to_be_taken)},
    {"road-network-id", self.network_id}
  }
end

return fluid_depot
