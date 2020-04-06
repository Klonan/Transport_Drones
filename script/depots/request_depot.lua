local fuel_amount_per_drone = shared.fuel_amount_per_drone
local drone_fluid_capacity = shared.drone_fluid_capacity

local request_spawn_timeout = 60

local request_depot = {}
request_depot.metatable = {__index = request_depot}

request_depot.corpse_offsets =
{
  [0] = {0, -2},
  [2] = {2, 0},
  [4] = {0, 2},
  [6] = {-2, 0},
}

local get_corpse_position = function(entity)

  local position = entity.position
  local direction = entity.direction
  local offset = request_depot.corpse_offsets[direction]
  return {position.x + offset[1], position.y + offset[2]}

end

local request_mode =
{
  item = 1,
  fluid = 2
}

function request_depot.new(entity)

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
    next_spawn_tick = 0,
    mode = request_mode.item,
    fuel_on_the_way = 0
  }
  setmetatable(depot, request_depot.metatable)

  depot:add_to_node()

  return depot

end


function request_depot:remove_fuel(amount)
  local box = self.entity.fluidbox[1]
  if not box then return end
  box.amount = box.amount - amount
  if box.amount <= 0 then
    self.entity.fluidbox[1] = nil
  else
    self.entity.fluidbox[1] = box
  end
end

function request_depot:check_drone_validity()
  local index, drone = next(self.drones)
  if not index then return end

  if not drone.entity.valid then
    drone:clear_drone_data()
    self:remove_drone(drone)
  end
end

function request_depot:minimum_fuel_amount()
  return (fuel_amount_per_drone * 2)
end

function request_depot:max_fuel_amount()
  return (self:get_drone_item_count() * fuel_amount_per_drone)
end


local icon_param = {type = "virtual", name = "fuel-signal"}
function request_depot:show_fuel_alert(message)
  for k, player in pairs (game.connected_players) do
    player.add_custom_alert(self.entity, icon_param, message, true)
  end
end

function request_depot:check_fuel_amount()

  if not self.item then return end

  local current_amount = self:get_fuel_amount()
  if current_amount >= self:minimum_fuel_amount() then
    return
  end

  local fuel_request_amount = (self:max_fuel_amount() - current_amount)
  if fuel_request_amount <= self.fuel_on_the_way then return end

  local fuel_depots = request_depot.road_network.get_fuel_depots(self.network_id)
  if not (fuel_depots and next(fuel_depots)) then
    self:show_fuel_alert("No fuel depots on network for request depot")
    return
  end

  for k, depot in pairs (fuel_depots) do
    depot:handle_fuel_request(self)
    if fuel_request_amount <= self.fuel_on_the_way then
      return
    end
  end

  self:show_fuel_alert("No fuel in network for request depot")

end

function request_depot:update()
  self:check_request_change()
  self:check_fuel_amount()
  self:check_drone_validity()
  self:update_sticker()
end

function request_depot:suicide_all_drones()
  for k, drone in pairs (self.drones) do
    drone:suicide()
  end
end

function request_depot:set_request_mode()
  local recipe = self.entity.get_recipe()
  if not recipe then return end

  local product_type = recipe.products[1].type
  if product_type == "item" then
    --self:say("Set to item")
    self.mode = request_mode.item
    return
  end
  
  if product_type == "fluid" then
    --self:say("Set to fluid")
    self.mode = request_mode.fluid
    return
  end
end


function request_depot:check_request_change()
  local requested_item = self:get_requested_item()
  if self.item == requested_item then return end

  self:set_request_mode()

  if self.item then
    self:remove_from_network()
    self:suicide_all_drones()
  end

  self.item = requested_item
  
  if not self.item then return end
  
  self:add_to_network()

end

function request_depot:get_requested_item()
  local recipe = self.entity.get_recipe()
  if not recipe then return end
  return recipe.products[1].name
end

function request_depot:get_stack_size()

  if self.mode == request_mode.item then
    return game.item_prototypes[self.item].stack_size
  end

  
  if self.mode == request_mode.fluid then
    return drone_fluid_capacity
  end

end

function request_depot:get_request_size()
  return self:get_stack_size() * (1 + request_depot.transport_technologies.get_transport_capacity_bonus(self.entity.force.index))
end

function request_depot:get_output_inventory()
  return self.entity.get_output_inventory()
end

function request_depot:get_drone_inventory()
  return self.entity.get_inventory(defines.inventory.assembling_machine_input)
end

function request_depot:get_active_drone_count()
  return table_size(self.drones)
end

function request_depot:get_fuel_amount()
  local box = self.entity.fluidbox[1]
  return (box and box.amount) or 0
end

function request_depot:can_spawn_drone()
  if game.tick < (self.next_spawn_tick or 0) then return end
  return self:get_drone_item_count() > self:get_active_drone_count()
end

function request_depot:get_drone_item_count()
  return self.entity.get_item_count("transport-drone")
end

function request_depot:get_minimum_request_size()
  return math.ceil(self:get_stack_size() / 2)
end

function request_depot:get_output_fluidbox()
  return self.entity.fluidbox[2]
end

function request_depot:set_output_fluidbox(box)
  self.entity.fluidbox[2] = box
end

function request_depot:get_current_amount()

  if self.mode == request_mode.item then
    return self:get_output_inventory().get_item_count(self.item)
  end

  if self.mode == request_mode.fluid then
    local box = self:get_output_fluidbox()
    return box and box.amount or 0
  end
end

function request_depot:should_order(plus_one)
  if self:get_fuel_amount() < fuel_amount_per_drone then
    return
  end
  local stack_size = self:get_request_size()
  local current_count = self:get_current_amount()
  local max_count = self:get_drone_item_count()
  local drone_spawn_count = max_count - math.floor(current_count / stack_size)
  return drone_spawn_count + (plus_one and 1 or 0) > self:get_active_drone_count()
end

function request_depot:handle_offer(supply_depot, name, count)

  if count < self:get_minimum_request_size() then return end

  if not self:can_spawn_drone() then return end

  if not self:should_order() then return end


  local needed_count = math.min(self:get_request_size(), count)

  local drone = request_depot.transport_drone.new(self)
  drone:pickup_from_supply(supply_depot, needed_count)
  self:remove_fuel(fuel_amount_per_drone)

  self.drones[drone.index] = drone

  self.next_spawn_tick = game.tick + request_spawn_timeout
  self:update_sticker()

end

function request_depot:take_item(name, count)
  if game.item_prototypes[name] then
    self.entity.get_output_inventory().insert({name = name, count = count})
    return
  end

  if game.fluid_prototypes[name] then
    local box = self:get_output_fluidbox()
    if not box then
      box = {name = name, amount = 0}
    end
    box.amount = box.amount + count
    self:set_output_fluidbox(box)
    return
  end

  

end

function request_depot:remove_drone(drone, remove_item)
  self.drones[drone.index] = nil
  if remove_item then
    self:get_drone_inventory().remove{name = "transport-drone", count = 1}
  end
  self:update_sticker()
end

function request_depot:update_sticker()
  
  if not self.item then
    if self.rendering and rendering.is_valid(self.rendering) then
      rendering.destroy(self.rendering)
      self.rendering = nil
    end
    return
  end

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
    scale = 1.5
  }

end


function request_depot:say(string)
  self.entity.surface.create_entity{name = "flying-text", position = self.entity.position, text = string}
end

function request_depot:add_to_node()
  local node = request_depot.road_network.get_node(self.entity.surface.index, self.node_position[1], self.node_position[2])
  node.depots = node.depots or {}
  node.depots[self.index] = self
end

function request_depot:remove_from_node()
  local surface = self.entity.surface.index
  local node = request_depot.road_network.get_node(surface, self.node_position[1], self.node_position[2])
  node.depots[self.index] = nil
  request_depot.road_network.check_clear_lonely_node(surface, self.node_position[1], self.node_position[2])
end

function request_depot:add_to_network()
  if not self.item then return end
  --self:say("Adding to network")
  self.network_id = request_depot.road_network.add_request_depot(self, self.item)
end

function request_depot:remove_from_network()
  if not self.item then return end
  local network = request_depot.road_network.get_network_by_id(self.network_id)
  
  if not network then return end

  local requesters = network.requesters
  requesters[self.item][self.index] = nil

  self.network_id = nil

end

function request_depot:on_removed()
  self:remove_from_network()
  self:remove_from_node()
  self:suicide_all_drones()
  self.corpse.destroy()
end

function request_depot:on_config_changed()
  self.mode = self.mode or request_mode.item
  self.fuel_on_the_way = self.fuel_on_the_way or 0
end

function request_depot:get_status_lines()
  if not self.item then
    return {
      {"requester-unconfigured"}
    }
  end

  return {
    {"request-item", self.item},
    {"drone-status", self:get_active_drone_count(), self:get_drone_item_count()},
    {"fuel-level", self:get_fuel_amount()},
    {"stack-size", self:get_stack_size()},
    {"minimum-stack-size", self:get_minimum_request_size()},
    {"road-network-id", self.network_id}
  }
end


return request_depot
