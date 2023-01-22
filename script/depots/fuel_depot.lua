local fuel_amount_per_drone = shared.fuel_amount_per_drone
local drone_fluid_capacity = shared.drone_fluid_capacity
local request_spawn_timeout = 60

local fuel_depot = {}
fuel_depot.metatable = {__index = fuel_depot}

fuel_depot.corpse_offsets =
{
  [0] = {0, -3},
  [2] = {3, 0},
  [4] = {0, 3},
  [6] = {-3, 0},
}

local fuel_fluid
local get_fuel_fluid = function()
  if fuel_fluid then
    return fuel_fluid
  end
  fuel_fluid = game.recipe_prototypes["fuel-depots"].products[1].name
  return fuel_fluid
end

local get_corpse_position = function(entity)

  local position = entity.position
  local direction = entity.direction
  local offset = fuel_depot.corpse_offsets[direction]
  return {position.x + offset[1], position.y + offset[2]}

end

function fuel_depot.new(entity, tags)

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
  setmetatable(depot, fuel_depot.metatable)

  depot:read_tags(tags)

  return depot

end

function fuel_depot:read_tags(tags)
  if tags then
    if tags.transport_depot_tags then
      local drone_count = tags.transport_depot_tags.drone_count
      if drone_count and drone_count > 0 then
        self.entity.surface.create_entity
        {
          name = "item-request-proxy",
          position = self.entity.position,
          force = self.entity.force,
          target = self.entity,
          modules = {["transport-drone"] = drone_count}
        }
      end
    end
  end
end

function fuel_depot:save_to_blueprint_tags()
  local count = self:get_drone_item_count()
  if count == 0 then return end
  return
  {
    drone_count = count
  }
end

function fuel_depot:update_circuit_reader()
  if self.circuit_reader and self.circuit_reader.valid then
    local behavior = self.circuit_reader.get_or_create_control_behavior()
    local signal = {signal = {type = "fluid", name = get_fuel_fluid()}, count = self:get_fuel_amount()}
    behavior.set_signal(1, signal)
  end
end

function fuel_depot:update()
  self:check_drone_validity()
  self:update_circuit_reader()
  self:update_sticker()
  --game.print("AHOY!")
end

function fuel_depot:add_to_network()
  self.network_id = self.road_network.add_depot(self, "fuel")
end

function fuel_depot:remove_from_network()
  self.road_network.remove_depot(self, "fuel")
  self.network_id = nil
end

function fuel_depot:get_fuel_amount()
  return self.entity.get_fluid_count(get_fuel_fluid())
end

function fuel_depot:minimum_request_size()
  return (fuel_amount_per_drone * 2)
end

function fuel_depot:get_drone_inventory()
  return self.entity.get_inventory(defines.inventory.assembling_machine_input)
end

function fuel_depot:remove_drone(drone, remove_item)
  self.drones[drone.index] = nil
  if remove_item then
    self:get_drone_inventory().remove{name = "transport-drone", count = 1}
  end
  self:update_sticker()
end

function fuel_depot:check_drone_validity()
  for k, drone in pairs (self.drones) do
    if drone.entity.valid then
      return
    else
      drone:clear_drone_data()
      self:remove_drone(drone)
    end
  end
end

function fuel_depot:can_spawn_drone()
  return self:get_drone_item_count() > self:get_active_drone_count()
end

function fuel_depot:get_drone_fluid_capacity()
  return drone_fluid_capacity * (1 + fuel_depot.transport_technologies.get_transport_capacity_bonus(self.entity.force.index))
end

function fuel_depot:handle_fuel_request(depot)
  if not self:can_spawn_drone() then return end

  if (self.circuit_writer and self.circuit_writer.valid) then
    local behavior = self.circuit_writer.get_control_behavior()
    if behavior and behavior.disabled then
      return
    end
  end

  local amount = self:get_fuel_amount()
  if amount < self:minimum_request_size() then return end

  amount = math.min((amount - fuel_amount_per_drone), self:get_drone_fluid_capacity())

  local drone = fuel_depot.transport_drone.new(self, "fuel-truck")
  if not drone then return end

  self:remove_fuel(amount)
  self:remove_fuel(fuel_amount_per_drone)

  drone:deliver_fuel(depot, amount)

  self.drones[drone.index] = drone

  self.next_spawn_tick = game.tick + request_spawn_timeout
  self:update_sticker()

end

function fuel_depot:say(string)
  self.entity.surface.create_entity{name = "tutorial-flying-text", position = self.entity.position, text = string}
end


function fuel_depot:get_drone_item_count()
  return self:get_drone_inventory().get_item_count("transport-drone")
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
  self.entity.remove_fluid({name = get_fuel_fluid(), amount = amount})
end

function fuel_depot:on_removed()
  self.corpse.destroy()
end

return fuel_depot
