local network_reader = {}

network_reader.metatable = {
  __index = network_reader
}
network_reader.corpse_offsets = {
  [0] = { 0, 1 },
  [4] = { -1, 0 },
  [8] = { 0, -1 },
  [12] = { 1, 0 }
}

local get_corpse_position = function(entity)
  local position = entity.position
  local direction = entity.direction
  local offset = network_reader.corpse_offsets[direction]
  return { position.x + offset[1], position.y + offset[2] }
end

function network_reader.new(entity)
  local force = entity.force
  local surface = entity.surface

  -- entity.active = false
  entity.rotatable = false

  local depot = {
    entity = entity,
    index = tostring(entity.unit_number)
  }
  setmetatable(depot, network_reader.metatable)
  depot:get_corpse()

  local offset = network_reader.corpse_offsets[entity.direction]
  rendering.draw_sprite {
    sprite = "utility/fluid_indication_arrow",
    surface = entity.surface,
    only_in_alt_mode = true,
    target = entity,
    target_offset = { offset[1] / 2, offset[2] / 2 },
    orientation_target = entity
  }

  return depot
end

function network_reader:get_corpse()
  if self.corpse and self.corpse.valid then
    return self.corpse
  end

  local corpse_position = get_corpse_position(self.entity)
  local corpse = self.entity.surface.create_entity {
    name = "transport-caution-corpse",
    position = corpse_position
  }
  corpse.corpse_expires = false
  self.corpse = corpse
  self.node_position = { math.floor(corpse_position[1]), math.floor(corpse_position[2]) }
  return corpse
end

function network_reader:say(string)
  self.entity.surface.create_entity {
    name = "tutorial-flying-text",
    position = self.entity.position,
    text = string
  }
end

function network_reader:update()
  local behavior = self.entity.get_control_behavior()
  if not behavior then
    return
  end
  for index, section in ipairs(behavior.sections) do
    for i = 1, 10 do
      local signal = section.get_slot(i)
      if not signal.value then goto continue end
      local name = signal.value.name
      local quality = signal.value.quality
      local type = signal.value.type
      if not name then goto continue end
      if not quality then goto continue end
      if not type then goto continue end
      local supply = self.road_network.get_network_item_supply(self.network_id)
      if not supply then goto continue end
      local sum = 0
      local counts = type == "fluid" and supply[name] or supply[name .. quality]
      if counts then
        for depot, count in pairs(counts) do
          sum = sum + count
        end
      end
      signal.min = sum
      signal.max = sum
      section.set_slot(i, signal)
      ::continue::
    end
  end
end

function network_reader:add_to_network()
  self.network_id = self.road_network
      .get_node(self.entity.surface.index, self.node_position[1], self.node_position[2]).id
end

function network_reader:remove_from_network()
  self.network_id = nil
end

function network_reader:on_removed()
  self.corpse.destroy()
end

return network_reader
