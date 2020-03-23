local transport_drone = require("script/transport_drone")
local road_network = require("script/road_network")
local transport_technologies = require("script/transport_technologies")


local fuel_amount_per_drone = shared.fuel_amount_per_drone
local drone_fluid_capacity = shared.drone_fluid_capacity
local request_spawn_timeout = 60

local fuel_depot = {}
local depot_metatable = {__index = fuel_depot}

local corpse_offsets = 
{
  [0] = {0, -3},
  [2] = {3, 0},
  [4] = {0, 3},
  [6] = {-3, 0},
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
  depot:add_to_network()

  return depot

end

function fuel_depot:update()
  self:update_sticker()
  --game.print("AHOY!")
end


function fuel_depot:remove_from_network()

  local network = road_network.get_network_by_id(self.network_id)

  local fuel = network.fuel

  fuel[self.index] = nil

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

function fuel_depot:get_fuel_amount()
  local box = self.entity.fluidbox[1]
  return (box and box.amount) or 0
end

function fuel_depot:minimum_request_size()
  return (fuel_amount_per_drone * 2)
end

function fuel_depot:remove_drone(drone, remove_item)
  self.drones[drone.index] = nil
  if remove_item then
    self:get_drone_inventory().remove{name = "transport-drone", count = 1}
  end
  self:update_sticker()
end

function fuel_depot:can_spawn_drone()
  if game.tick < (self.next_spawn_tick or 0) then return end
  return self:get_drone_item_count() > self:get_active_drone_count()
end

function fuel_depot:get_drone_fluid_capacity()
  return drone_fluid_capacity * (1 + transport_technologies.get_transport_capacity_bonus(self.entity.force.index))
end

function fuel_depot:handle_fuel_request(depot)
  if not self:can_spawn_drone() then return end
  local amount = self:get_fuel_amount()
  if amount < self:minimum_request_size() then return end

  amount = math.min((amount - fuel_amount_per_drone), self:get_drone_fluid_capacity())
  
  local drone = transport_drone.new(self)

  self:remove_fuel(amount)
  self:remove_fuel(fuel_amount_per_drone)

  drone:deliver_fuel(depot, amount)

  self.drones[drone.index] = drone
  
  self.next_spawn_tick = game.tick + request_spawn_timeout
  self:update_sticker()

end

function fuel_depot:say(string)
  self.entity.surface.create_entity{name = "flying-text", position = self.entity.position, text = string}
end


function fuel_depot:get_drone_item_count()
  return self.entity.get_item_count("transport-drone")
end

function fuel_depot:get_active_drone_count()
  return table_size(self.drones)
end

function fuel_depot:update_sticker()

  if self.rendering and rendering.is_valid(self.rendering) then
    rendering.set_text(self.rendering, self:get_active_drone_count().."/"..self:get_drone_item_count())
    return
  end

  self.rendering = rendering.draw_text
  {
    surface = self.entity.surface.index,
    target = self.entity,
    text = self:get_active_drone_count().."/"..self:get_drone_item_count(),
    only_in_alt_mode = true,
    forces = {self.entity.force},
    color = {r = 1, g = 1, b = 1},
    alignment = "center",
    scale = 2,
    target_offset = {0, 0.5}
  }

end


function fuel_depot:remove_fuel(amount)
  local box = self.entity.fluidbox[1]
  if not box then return end
  box.amount = box.amount - amount
  if box.amount <= 0 then
    self.entity.fluidbox[1] = nil
  else
    self.entity.fluidbox[1] = box
  end
end

function fuel_depot:on_removed()
  self:remove_from_network()
  self:remove_from_node()
  --self:suicide_all_drones()
  self.corpse.destroy()
end


local lib = {}

lib.load = function(depot)
  setmetatable(depot, depot_metatable)
end

lib.new = fuel_depot.new

lib.corpse_offsets = corpse_offsets

return lib