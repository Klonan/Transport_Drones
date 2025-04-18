local mining_depot = {}
mining_depot.metatable = {__index = mining_depot}

mining_depot.corpse_offsets =
{
  [0] = {0, 4.5},
  [4] = {-4.5, 0},
  [8] = {0, -4.5},
  [12] = {4.5, 0},
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


  local depot =
  {
    entity = entity,
    index = tostring(entity.unit_number),
    to_be_taken = {},
    old_contents = {}
  }
  setmetatable(depot, mining_depot.metatable)
  depot:get_corpse()

  return depot

end

function mining_depot:get_corpse()
  if self.corpse and self.corpse.valid then
    return self.corpse
  end

  local corpse_position = get_corpse_position(self.entity)
  local corpse = self.entity.surface.create_entity{name = "invisible-transport-caution-corpse", position = corpse_position}
  corpse.corpse_expires = false
  self.corpse = corpse
  self.node_position = {math.floor(corpse_position[1]), math.floor(corpse_position[2])}
  return corpse
end

function mining_depot:get_to_be_taken(name)
  return self.to_be_taken[name] or 0
end

function mining_depot:update_contents()

  local supply = self.road_network.get_network_item_supply(self.network_id)

  local new_contents
  if (self.circuit_writer and self.circuit_writer.valid) then
    local behavior = self.circuit_writer.get_control_behavior()
    if behavior and behavior.disabled then
      new_contents = {}
    end
  end
  if not new_contents then
    new_contents = self.entity.get_output_inventory().get_contents()
  end

  for name, count in pairs (self.old_contents) do
    if not new_contents[name] then
      local item_supply = supply[name]
      if item_supply then
        item_supply[self.index] = nil
      end
    end
  end

  for name, count in pairs (new_contents) do
    local item_supply = supply[name]
    if not item_supply then
      item_supply = {}
      supply[name] = item_supply
    end
    local new_count = count - self:get_to_be_taken(name)
    if new_count > 0 then
      item_supply[self.index] = new_count
    else
      item_supply[self.index] = nil
    end
  end

  self.old_contents = new_contents

  if self.circuit_reader and self.circuit_reader.valid then
    local behavior = self.circuit_reader.get_or_create_control_behavior()
    local name, count = next(new_contents) or next(self.entity.get_output_inventory().get_contents())
    local signal
    if name and count and count > 0 then
      signal = {signal = {type = "item", name = name}, count = count}
    end
    behavior.set_signal(1, signal)
  end

end


function mining_depot:update()
  self:update_contents()
end

function mining_depot:say(string)
  self.entity.surface.create_entity{name = "tutorial-flying-text", position = self.entity.position, text = string}
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

function mining_depot:add_to_network()
  self.network_id = self.road_network.add_depot(self, "mining")
  self:update_contents()
end

function mining_depot:remove_from_network()
  self.road_network.remove_depot(self, "mining")
  self.network_id = nil
end

function mining_depot:on_removed()
  self.corpse.destroy()
end

function mining_depot:on_config_changed()
  self.old_contents = self.old_contents or {}
end

return mining_depot