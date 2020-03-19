local transport_drone = require("script/transport_drone")
local road_network = require("script/road_network")

local fuel_depot = {}
local depot_metatable = {__index = fuel_depot}

local corpse_offsets = 
{
  [0] = {0, 3},
  [2] = {-3, 0},
  [4] = {0, -3},
  [6] = {3, 0},
}

local get_corpse_position = function(entity)

  local position = entity.position
  local direction = entity.direction
  local offset = corpse_offsets[direction]
  return {position.x + offset[1], position.y + offset[2]}

end

function fuel_depot.new(entity)

  local force = entity.force
  local surface = entity.surface

  entity.active = false
  entity.rotatable = false

  local corpse_position = get_corpse_position(entity)
  local corpse = surface.create_entity{name = "transport-caution-corpse", position = corpse_position}
  corpse.corpse_expires = false
  
  local depot =
  {
    entity = entity,
    corpse = corpse,
    index = tostring(entity.unit_number),
    node_position = {math.floor(corpse_position[1]), math.floor(corpse_position[2])},
    item = false,
    drones = {},
    next_spawn_tick = 0
  }
  setmetatable(depot, depot_metatable)

  depot:add_to_node()

  return depot

end

function fuel_depot:update()
  --game.print("AHOY!")
end


function fuel_depot:remove_from_network()

  local network = road_network.get_network_by_id(self.network_id)

  local supply = network.supply

  supply[self.index] = nil

  self.network_id = nil

end

function fuel_depot:add_to_node()
  local node = road_network.get_node(self.entity.surface.index, self.node_position[1], self.node_position[2])
  node.depots = node.depots or {}
  node.depots[self.index] = self
end

function fuel_depot:remove_from_node()
  local surface = self.entity.surface.index
  local node = road_network.get_node(surface, self.node_position[1], self.node_position[2])
  node.depots[self.index] = nil
  road_network.check_clear_lonely_node(surface, self.node_position[1], self.node_position[2])
end

function fuel_depot:add_to_network()
  --self:say("Adding to network") 
  self.network_id = road_network.add_fuel_depot(self)
end



local lib = {}

lib.load = function(depot)
  setmetatable(depot, depot_metatable)
end

lib.new = fuel_depot.new

lib.corpse_offsets = corpse_offsets

return lib