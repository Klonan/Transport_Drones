local supply_depot = {}

supply_depot.metatable = {__index = supply_depot}

supply_depot.corpse_offsets =
{
  [0] = {0, -2},
  [4] = {2, 0},
  [8] = {0, 2},
  [12] = {-2, 0},
}

local get_corpse_position = function(entity)

  local position = entity.position
  local direction = entity.direction
  local offset = supply_depot.corpse_offsets[direction]
  return {position.x + offset[1], position.y + offset[2]}

end

function supply_depot.new(entity, tags)
  local position = entity.position
  local force = entity.force
  local surface = entity.surface
  entity.destructible = false
  entity.minable = false
  entity.rotatable = false
  entity.active = false
  local chest = surface.create_entity{name = "supply-depot-chest", position = position, force = force, player = entity.last_user}

  local depot =
  {
    entity = chest,
    assembler = entity,
    to_be_taken = {},
    index = tostring(chest.unit_number),
    old_contents = {}
  }
  setmetatable(depot, supply_depot.metatable)

  depot:get_corpse()
  depot:read_tags(tags)

  return depot

end

function supply_depot:get_corpse()
  if self.corpse and self.corpse.valid then
    return self.corpse
  end

  local corpse_position = get_corpse_position(self.assembler)
  local corpse = self.entity.surface.create_entity{name = "transport-caution-corpse", position = corpse_position}
  corpse.corpse_expires = false
  self.corpse = corpse
  self.node_position = {math.floor(corpse_position[1]), math.floor(corpse_position[2])}
  return corpse
end

function supply_depot:read_tags(tags)
  if tags then
    if tags.transport_depot_tags then
      local bar = tags.transport_depot_tags.bar
      if bar then
        self.entity.get_output_inventory().set_bar(bar)
      end
    end
  end
end

function supply_depot:save_to_blueprint_tags()
  return
  {
    bar = self.entity.get_output_inventory().get_bar()
  }
end

function supply_depot:get_to_be_taken(name,quality)
  return self.to_be_taken[name..quality] or 0
end

function supply_depot:update_contents()
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

  for _,content in pairs (self.old_contents) do
    if not new_contents[{name = content.name,quality = content.quality}] then
      local item_supply = supply[content.name..content.quality]
      if item_supply then
        item_supply[self.index] = nil
      end
    end
  end

  for _,content in pairs (new_contents) do
    local item_supply = supply[content.name..content.quality]
    if not item_supply then
      item_supply = {}
      supply[content.name..content.quality] = item_supply
    end
    local new_count = content.count - self:get_to_be_taken(content.name,content.quality)
    if new_count > 0 then
      item_supply[self.index] = new_count
    else
      item_supply[self.index] = nil
    end
  end

  self.old_contents = new_contents

end

--[[

had iron 10
now iron 5
]]

function supply_depot:update()
  self:update_contents()

end

function supply_depot:say(string)
  -- self.entity.surface.create_entity{name = "tutorial-flying-text", position = self.entity.position, text = string}
end

function supply_depot:give_item(requested_name,requested_quality, requested_count)
  local inventory = self.entity.get_output_inventory()
  local removed_count = inventory.remove({name = requested_name,quality = requested_quality, count = requested_count})
  return removed_count
end

function supply_depot:add_to_be_taken(name,quality, count)
  --if not (name and count) then return end
  self.to_be_taken[name..quality] = (self.to_be_taken[name..quality] or 0) + count
  --self:say(name.." - "..self.to_be_taken[name]..": "..count)
end

function supply_depot:get_available_item_count(name, quality)
  return self.entity.get_output_inventory().get_item_count({name = name,quality = quality}) - self:get_to_be_taken(name,quality)
end

function supply_depot:add_to_network()
  self.network_id = self.road_network.add_depot(self, "supply")
  self:update_contents()
end

function supply_depot:remove_from_network()
  self.road_network.remove_depot(self, "supply")
  self.network_id = nil
end

function supply_depot:on_removed(event)

  self.corpse.destroy()

  if self.assembler.valid then
    self.assembler.destructible = true
    if event.name == defines.events.on_entity_died then
      self.assembler.die()
    else
      self.assembler.destroy()
    end
  end

  if self.entity.valid then
    self.entity.destroy()
  end
end

function supply_depot:on_config_changed()
  self.old_contents = self.old_contents or {}
end

return supply_depot