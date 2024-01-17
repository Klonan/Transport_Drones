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

  local depot =
  {
    entity = entity,
    to_be_taken = {},
    index = tostring(entity.unit_number),
    old_contents = {}
  }
  setmetatable(depot, fluid_depot.metatable)
  depot:get_corpse()

  return depot

end

function fluid_depot:get_corpse()
  if self.corpse and self.corpse.valid then
    return self.corpse
  end

  local corpse_position = get_corpse_position(self.entity)
  local corpse = self.entity.surface.create_entity{name = "transport-caution-corpse", position = corpse_position}
  corpse.corpse_expires = false
  self.corpse = corpse
  self.node_position = {math.floor(corpse_position[1]), math.floor(corpse_position[2])}
  return corpse
end

function fluid_depot:get_to_be_taken(name)
  return self.to_be_taken[name] or 0
end

function fluid_depot:get_output_fluidbox()
  return self.entity.fluidbox[1]
end

function fluid_depot:get_temperature()
  local box = self:get_output_fluidbox()
  return box and box.temperature
end

function fluid_depot:set_output_fluidbox(box)
  self.entity.fluidbox[1] = box
end


function fluid_depot:update_contents()

  local supply = self.road_network.get_network_item_supply(self.network_id)

  local new_contents = {}


  local enabled = true
  if (self.circuit_writer and self.circuit_writer.valid) then
    local behavior = self.circuit_writer.get_control_behavior()
    if behavior and behavior.disabled then
      enabled = false
    end
  end

  if enabled then
    local box = self:get_output_fluidbox()
    if box then
      new_contents[box.name] = box.amount
    end
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
    local name, count = next(new_contents)
    if not name then
      local box = self:get_output_fluidbox()
      if box then
        name = box.name
        count = box.amount
      end
    end
    local signal
    if name and count and count > 0 then
      signal = {signal = {type = "fluid", name = name}, count = count}
    end
    behavior.set_signal(1, signal)
  end

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

  self:update_contents()
  --self:say("U")

end

function fluid_depot:say(string)
  self.entity.surface.create_entity{name = "tutorial-flying-text", position = self.entity.position, text = string}
end

function fluid_depot:give_item(requested_name, requested_count)
  return self.entity.remove_fluid{name = requested_name, amount = requested_count}
end

function fluid_depot:add_to_be_taken(name, count)
  --if not (name and count) then return end
  self.to_be_taken[name] = (self.to_be_taken[name] or 0) + count
  --self:say(self.to_be_taken[name])
end

function fluid_depot:get_available_item_count(name)
  return self.entity.get_fluid_count(name) - self:get_to_be_taken(name)
end

function fluid_depot:add_to_network()
  self.network_id = self.road_network.add_depot(self, "fluid")
  self:update_contents()
end

function fluid_depot:remove_from_network()
  self.road_network.remove_depot(self, "fluid")
  self.network_id = nil
end

function fluid_depot:on_removed()
  self.corpse.destroy()
end

function fluid_depot:on_config_changed()
  self.old_contents = self.old_contents or {}
end

function fluid_depot:get_road_network_priority()
  if not (self.circuit_writer and self.circuit_writer.valid) then
    return 0
  end

  local merged_signals = self.circuit_writer.get_merged_signals()
  local road_network_priority = 0

  if merged_signals then
    for _, signal_data in pairs(merged_signals) do
      if signal_data.signal.name == "signal-0" then
        road_network_priority = signal_data.count
      end
    end
  end

  return road_network_priority
end

return fluid_depot