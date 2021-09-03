local network_reader = {}

network_reader.metatable = {__index = network_reader}
network_reader.corpse_offsets = 
{
  [0] = {0, 1},
  [2] = {-1, 0},
  [4] = {0, -1},
  [6] = {1, 0},
}

local get_corpse_position = function(entity)

  local position = entity.position
  local direction = entity.direction
  local offset = network_reader.corpse_offsets[direction]
  return {position.x + offset[1], position.y + offset[2]}

end

function network_reader.new(entity)
  
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
    node_position = {math.floor(corpse_position[1]), math.floor(corpse_position[2])},
    index = tostring(entity.unit_number)
  }
  setmetatable(depot, network_reader.metatable)

  local offset = network_reader.corpse_offsets[entity.direction]
  rendering.draw_sprite
  {
    sprite = "utility/fluid_indication_arrow",
    surface = entity.surface,
    only_in_alt_mode = true,
    target = entity,
    target_offset = {offset[1] / 2, offset[2] / 2},
    orientation_target = entity
  }

  return depot
  
end


function network_reader:say(string)
  self.entity.surface.create_entity{name = "tutorial-flying-text", position = self.entity.position, text = string}
end

function network_reader:update()
  local behavior = self.entity.get_control_behavior()
  if not behavior then return end
  
  for i = 1, behavior.signals_count do
    behavior.set_signal(i, nil)
  end
  local network = self.road_network.get_network_by_id(self.network_id)
  if not network.stats then return end
  local i = 1
  local order = {}
  for name, s in pairs(network.stats.by_item) do
    if s.count ~= 0 then
      table.insert(order, {name=name, item_type=s.item_type, count=s.count})
    end
  end  
  table.sort(order, function(a, b) return a.count > b.count end)
  for _, n in pairs(order) do
    local name, item_type, count = n.name, n.item_type, n.count
    local signal = {
      signal = {
        type = item_type,
        name = name,
      },
      count = count
    }
    behavior.set_signal(i, signal)
    i = i + 1

    -- combinator maximum
    if i > 1000 then
      return
    end
  end
end

function network_reader:add_to_network()
  self.network_id = self.road_network.get_node(self.entity.surface.index, self.node_position[1], self.node_position[2]).id
end

function network_reader:remove_from_network()
  self.network_id = nil
end

function network_reader:on_removed()
  self.corpse.destroy()
end

return network_reader