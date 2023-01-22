local fuel_amount_per_drone = shared.fuel_amount_per_drone
local drone_fluid_capacity = shared.drone_fluid_capacity

local request_spawn_timeout = 60

local buffer_depot = {}
buffer_depot.metatable = {__index = buffer_depot}

buffer_depot.corpse_offsets =
{
  [0] = {0, -2},
  [2] = {2, 0},
  [4] = {0, 2},
  [6] = {-2, 0},
}

buffer_depot.is_buffer_depot = true

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
  local offset = buffer_depot.corpse_offsets[direction]
  return {position.x + offset[1], position.y + offset[2]}

end

local request_mode =
{
  item = 1,
  fluid = 2
}

function buffer_depot.new(entity, tags)

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
    fuel_on_the_way = 0,
    to_be_taken = {},
    old_contents = {}
  }
  setmetatable(depot, buffer_depot.metatable)

  depot:read_tags(tags)

  return depot

end

function buffer_depot:read_tags(tags)
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

function buffer_depot:save_to_blueprint_tags()
  local count = self:get_drone_item_count()
  if count == 0 then return end
  return
  {
    drone_count = count
  }
end

function buffer_depot:remove_fuel(amount)
  self.entity.remove_fluid({name = get_fuel_fluid(), amount = amount})
end

function buffer_depot:check_drone_validity()
  for k, drone in pairs (self.drones) do
    if drone.entity.valid then
      return
    else
      drone:clear_drone_data()
      self:remove_drone(drone)
    end
  end
end

local max = math.max
function buffer_depot:minimum_fuel_amount()
  return max(fuel_amount_per_drone * 2, fuel_amount_per_drone * self:get_drone_item_count() * 0.2)
end

function buffer_depot:max_fuel_amount()
  return (self:get_drone_item_count() * fuel_amount_per_drone)
end


local icon_param = {type = "virtual", name = "fuel-signal"}
function buffer_depot:show_fuel_alert(message)
  for k, player in pairs (game.connected_players) do
    player.add_custom_alert(self.entity, icon_param, message, true)
  end
end

local icon_param = {type = "item", name = "transport-drone"}
function buffer_depot:show_drone_alert(message)
  for k, player in pairs (game.connected_players) do
    player.add_custom_alert(self.entity, icon_param, message, true)
  end
end

function buffer_depot:check_fuel_amount()

  if not self.item then return end

  local current_amount = self:get_fuel_amount()
  if current_amount >= self:minimum_fuel_amount() then
    return
  end

  local fuel_request_amount = (self:max_fuel_amount() - current_amount)
  if fuel_request_amount <= self.fuel_on_the_way then return end

  local fuel_depots = self.road_network.get_depots_by_distance(self.network_id, "fuel", self.node_position)
  if not (fuel_depots and fuel_depots[1]) then
    self:show_fuel_alert({"no-fuel-depot-on-network"})
    return
  end

  for k = 1, #fuel_depots do
    local depot = fuel_depots[k]
    depot:handle_fuel_request(self)
    if fuel_request_amount <= self.fuel_on_the_way then
      return
    end
  end

  self:show_fuel_alert({"no-fuel-in-network"})

end

function buffer_depot:check_drone_amount()

  if not self.item then return end

  local current_amount = self:get_drone_item_count()
  if current_amount > 0 then
    return
  end

  self:show_drone_alert({"no-drone-in-depot"})

end

function buffer_depot:offer_item()
  if not self.item then return end
  self:check_requests_for_item(self.item, self:get_current_amount())
end

function buffer_depot:update_contents()

  if not self.network_id then return end

  local supply = self.road_network.get_network_item_supply(self.network_id)

  local new_contents = {}

  local enabled = (self.circuit_limit ~= 0)

  if enabled and self.item then
    new_contents[self.item] = self:get_current_amount()
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
    local signal
    if self.item then
      signal = {signal = {type = self.mode == request_mode.item and "item" or "fluid", name = self.item}, count = self:get_current_amount()}
    end
    behavior.set_signal(1, signal)
  end

end

local min = math.min
function buffer_depot:dispatch_drone(depot, count)

  local drone = self.transport_drone.new(self, self.item)
  drone:pickup_from_supply(depot, self.item, count)
  self:remove_fuel(fuel_amount_per_drone)

  self.drones[drone.index] = drone

  self:update_sticker()
end


local distance = function(a, b)
  local dx = a[1] - b[1]
  local dy = a[2] - b[2]
  return ((dx * dx) + (dy * dy)) ^ 0.5
end

local big = math.huge
local min = math.min
local item_heuristic_bonus = 50
function buffer_depot:make_request()

  local name = self.item
  if not name then return end

  if not self:can_spawn_drone() then return end
  if not self:should_order() then return end

  local supply_depots = self.road_network.get_supply_depots(self.network_id, name)
  if not supply_depots then return end

  local request_size = self:get_request_size()
  local minimum_size = self:get_minimum_request_size()
  local stack_size = self:get_stack_size()

  local node_position = self.node_position
  local heuristic = function(depot, count)
    if depot.is_buffer_depot then return big end
    local amount = min(count, request_size)
    if amount < minimum_size then
      return big
    end
    return distance(depot.node_position, node_position) - ((amount / request_size) * item_heuristic_bonus)
  end

  local best_buffer
  local best_index
  local lowest_score = big
  local get_depot = self.get_depot

  for depot_index, count in pairs (supply_depots) do
    local depot = get_depot(depot_index)
    if depot then
      local score = heuristic(depot, count)
      if score < lowest_score then
        best_buffer = depot
        lowest_score = score
        best_index = depot_index
      end
    end
  end

  if not best_buffer then return end

  local count = supply_depots[best_index]
  if request_size >= count then
    supply_depots[best_index] = nil
    self:dispatch_drone(best_buffer, count)
  else
    supply_depots[best_index] = count - request_size
    self:dispatch_drone(best_buffer, request_size)
  end

end


function buffer_depot:update()
  self:check_request_change()
  self:update_contents()
  self:check_fuel_amount()
  self:check_drone_validity()
  self:check_drone_amount()
  self:update_circuit_writer()
  self:make_request()
  self:update_sticker()
end

function buffer_depot:suicide_all_drones()
  for k, drone in pairs (self.drones) do
    drone:suicide()
  end
end

function buffer_depot:set_request_mode()
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


function buffer_depot:check_request_change()
  local requested_item = self:get_requested_item()
  if self.item == requested_item then return end

  self:set_request_mode()

  if self.item then
    self:suicide_all_drones()
  end

  self.item = requested_item

end

function buffer_depot:get_requested_item()
  local recipe = self.entity.get_recipe()
  if not recipe then return end
  return recipe.products[1].name
end

local stack_cache = {}
local get_stack_size = function(item)
  local size = stack_cache[item]
  if not size then
    size = game.item_prototypes[item].stack_size
    stack_cache[item] = size
  end
  return size
end

function buffer_depot:get_stack_size()

  if self.mode == request_mode.item then
    return get_stack_size(self.item)
  end


  if self.mode == request_mode.fluid then
    return drone_fluid_capacity
  end

end

function buffer_depot:get_request_size()
  return self:get_stack_size() * (1 + buffer_depot.transport_technologies.get_transport_capacity_bonus(self.entity.force.index))
end

function buffer_depot:get_output_inventory()
  return self.entity.get_output_inventory()
end

function buffer_depot:get_drone_inventory()
  return self.entity.get_inventory(defines.inventory.assembling_machine_input)
end

function buffer_depot:get_active_drone_count()
  return table_size(self.drones)
end

function buffer_depot:get_fuel_amount()
  return self.entity.get_fluid_count(get_fuel_fluid())
end

function buffer_depot:can_spawn_drone()
  return self:get_drone_item_count() > self:get_active_drone_count()
end

function buffer_depot:get_drone_item_count()
  return self:get_drone_inventory().get_item_count("transport-drone")
end

function buffer_depot:get_output_fluidbox()
  return self.entity.fluidbox[2]
end

function buffer_depot:set_output_fluidbox(box)
  self.entity.fluidbox[2] = box
end

function buffer_depot:get_temperature()
  if #self.entity.fluidbox == 2 then
    local box = self:get_output_fluidbox()
    return box and box.temperature
  end
end

function buffer_depot:get_current_amount()

  if not self.item then return 0 end

  if self.mode == request_mode.item then
    return self:get_output_inventory().get_item_count(self.item)
  end

  if self.mode == request_mode.fluid then
    local box = self:get_output_fluidbox()
    return box and box.amount or 0
  end
end

function buffer_depot:get_available_stack_amount()
  if not self.item then return 0 end
  return self:get_available_item_count(self.item) / self:get_stack_size()
end

function buffer_depot:get_minimum_request_size()

  local stack_size = self:get_stack_size()

  local current_amount = self:get_current_amount()
  if current_amount < stack_size and self:get_active_drone_count() == 0 then
    return 1
  end

  local request_size = self:get_request_size()
  if current_amount < request_size then
    return stack_size
  end

  return request_size
end

function buffer_depot:get_storage_size()
  return self:get_drone_item_count() * self:get_request_size()
end

function buffer_depot:should_order()
  if self:get_fuel_amount() < fuel_amount_per_drone then
    return
  end

  if self.circuit_limit == 0 then return end

  local size = self.circuit_limit or self:get_storage_size()
  local missing = size - self:get_current_amount()

  local should_send_drone_count = math.ceil(missing / self:get_request_size())
  return self:get_active_drone_count() < should_send_drone_count

end

local min = math.min
function buffer_depot:give_item(requested_name, requested_count)

  if game.item_prototypes[requested_name] then
    local inventory = self.entity.get_output_inventory()
    local removed_count = inventory.remove({name = requested_name, count = requested_count})
    return removed_count
  end

  if game.fluid_prototypes[requested_name] then
    local box = self:get_output_fluidbox()
    if not box then
      return 0
    end

    if box.name ~= requested_name then
      return 0
    end

    if requested_count >= box.amount then
      self:set_output_fluidbox(nil)
      return box.amount
    end

    box.amount = box.amount - requested_count
    self:set_output_fluidbox(box)
    return requested_count
  end
end

local valid_item_cache = {}
local is_valid_item = function(item_name)
  local bool = valid_item_cache[item_name]
  if bool ~= nil then
    return bool
  end
  valid_item_cache[item_name] = game.item_prototypes[item_name] ~= nil
  return valid_item_cache[item_name]
end

local valid_fluid_cache = {}
local is_valid_fluid = function(fluid_name)
  local bool = valid_fluid_cache[fluid_name]
  if bool ~= nil then
    return bool
  end
  valid_fluid_cache[fluid_name] = game.fluid_prototypes[fluid_name] ~= nil
  return valid_fluid_cache[fluid_name]
end

function buffer_depot:take_item(name, count, temperature)
  if not count then error("NO COUMT?") end

  if self.mode == request_mode.item and is_valid_item(name) then
    self.entity.get_output_inventory().insert({name = name, count = count})
    return
  end

  if self.mode == request_mode.fluid and is_valid_fluid(name) then
    local box = self:get_output_fluidbox()
    if not box then
      box = {name = name, amount = 0}
    end
    box.amount = box.amount + count
    if temperature then
      box.temperature = temperature
    end
    self:set_output_fluidbox(box)
    return
  end

end

function buffer_depot:get_to_be_taken(name)
  return self.to_be_taken[name] or 0
end

function buffer_depot:add_to_be_taken(name, count)
  --if not (name and count) then return end
  self.to_be_taken[name] = (self.to_be_taken[name] or 0) + count
  --self:say(self.to_be_taken[name])
end

function buffer_depot:get_available_item_count(name)
  return self:get_current_amount() - self:get_to_be_taken(name)
end

function buffer_depot:remove_drone(drone, remove_item)
  self.drones[drone.index] = nil
  if remove_item then
    self:get_drone_inventory().remove{name = "transport-drone", count = 1}
  end
  self:update_sticker()
end

function buffer_depot:update_sticker()

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

function buffer_depot:update_circuit_writer()
  if not self.circuit_writer then return end

  if not self.circuit_writer.valid then
    self.circuit_writer = nil
    self.circuit_limit = nil
    return
  end

  local behavior = self.circuit_writer.get_control_behavior()
  if not behavior then
    self.circuit_limit = 0
    --self:say("Depot disabled")
    return
  end

  local circuit_condition = behavior.connect_to_logistic_network and behavior.logistic_condition or behavior.circuit_condition
  if circuit_condition then
    local condition = circuit_condition.condition
    if condition.comparator == "=" then
      local first_signal = condition.first_signal
      if first_signal then
        if first_signal.name == self.item then
          local count
          if condition.second_signal and condition.second_signal.name then
            count = self.circuit_writer.get_merged_signal(condition.second_signal)
          else
            count = condition.constant or 0
          end
          self.circuit_limit = count
          --self:say("Set limit "..count)
          return
        end
      end
    end
    if circuit_condition.fulfilled then
      self.circuit_limit = nil
      --self:say("Depot enabled")
      return
    end
  end

  --If there is a writer with no conditions, we just disable the depot.
  self.circuit_limit = 0
  --self:say("Depot disabled")

end

function buffer_depot:say(string)
  self.entity.surface.create_entity{name = "tutorial-flying-text", position = self.entity.position, text = string}
end

function buffer_depot:add_to_network()
  self.network_id = self.road_network.add_depot(self, "buffer")
  self:update_contents()
end

function buffer_depot:remove_from_network()
  self.road_network.remove_depot(self, "buffer")
  self.network_id = nil
end

function buffer_depot:on_removed()
  self:suicide_all_drones()
  self.corpse.destroy()
end

function buffer_depot:on_config_changed()
  self:set_request_mode()
  self.to_be_taken = self.to_be_taken or {}
  self.old_contents = self.old_contents or {}
end

return buffer_depot