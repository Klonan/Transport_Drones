local fuel_amount_per_drone = shared.fuel_amount_per_drone
local drone_fluid_capacity = shared.drone_fluid_capacity

local request_depot = {}
request_depot.metatable = {__index = request_depot}

request_depot.corpse_offsets =
{
  [0] = {0, -2},
  [4] = {2, 0},
  [8] = {0, 2},
  [12] = {-2, 0},
}

local fuel_fluid
local get_fuel_fluid = function()
  if not fuel_fluid then
    fuel_fluid = prototypes.recipe["fuel-depots"].products[1].name
  end
  return fuel_fluid
end

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

function request_depot.new(entity, tags)

  local force = entity.force
  local surface = entity.surface

  entity.active = false
  entity.rotatable = false

  local depot =
  {
    entity = entity,
    index = tostring(entity.unit_number),
    item = false,
    drones = {},
    mode = request_mode.item,
    fuel_on_the_way = 0
  }
  setmetatable(depot, request_depot.metatable)

  depot:get_corpse()
  depot:read_tags(tags)

  return depot

end

function request_depot:get_corpse()
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

function request_depot:read_tags(tags)
  if tags then
    if tags.transport_depot_tags then
      local drone_count = tags.transport_depot_tags.drone_count
      local drone_quality = tags.transport_depot_tags.drone_quality
      
      if drone_count and drone_count > 0 then
        self.entity.surface.create_entity
        {
          name = "item-request-proxy",
          position = self.entity.position,
          force = self.entity.force,
          target = self.entity,
          modules = {{id = {name = "transport-drone",quality = drone_quality},items = {in_inventory = {{inventory = defines.inventory.assembling_machine_input,stack = 0,count =drone_count }}}}},
        }
      end
    end
  end
end

function request_depot:save_to_blueprint_tags()
  local count = self:get_drone_item_count()
  if count == 0 then return end
  return
  {
    drone_count = count,
    drone_quality = self.quality
  }
end

function request_depot:remove_fuel(amount)
  self.entity.remove_fluid({name = get_fuel_fluid(), amount = amount})
end

function request_depot:check_drone_validity()
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
function request_depot:minimum_fuel_amount()
  return max(fuel_amount_per_drone * 2, fuel_amount_per_drone * self:get_drone_item_count() * 0.2)
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

local icon_param = {type = "item", name = "transport-drone"}
function request_depot:show_drone_alert(message)
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

function request_depot:check_drone_amount()

  if not self.item then return end

  local current_amount = self:get_drone_item_count()
  if current_amount > 0 then
    return
  end

  self:show_drone_alert({"no-drone-in-depot"})

end

function request_depot:get_minimum_request_size()

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


local distance = function(a, b)
  local dx = a[1] - b[1]
  local dy = a[2] - b[2]
  return ((dx * dx) + (dy * dy)) ^ 0.5
end

local big = math.huge
local min = math.min
local item_heuristic_bonus = 50
function request_depot:make_request()
  local name = self.item
  local quality = self.type == "fluid" and "" or self.quality
  if not name then return end
  if not quality then return end
  
  if not self:can_spawn_drone() then return end
  if not self:should_order() then return end
  local supply_depots = self.road_network.get_supply_depots(self.network_id, name ,quality)
  -- game.print("supply_depots: "..serpent.block(supply_depots))
  if not supply_depots then return end
  local request_size = self:get_request_size()
  local minimum_size = self:get_minimum_request_size()
  local stack_size = self:get_stack_size()
  if self.circuit_limit then
    local missing = self.circuit_limit - self:get_current_amount()
    request_size = math.min(missing, request_size)
    minimum_size = 1
  end

  local node_position = self.node_position
  local heuristic = function(depot, count)
    local amount = min(count, request_size)
    return distance(depot.node_position, node_position) - ((amount / request_size) * item_heuristic_bonus)
  end

  local best_buffer
  local best_index
  local lowest_score = big
  local get_depot = self.get_depot

  for depot_index, count in pairs (supply_depots) do
    if count >= minimum_size then
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

function request_depot:update_circuit_reader()
  if self.circuit_reader and self.circuit_reader.valid then
    local behavior = self.circuit_reader.get_or_create_control_behavior()

    if (behavior.sections_count == 0) then behavior.add_section() end
    local section = behavior.get_section(1)
    if self.item then
      section.set_slot(1, { value = {type = self.mode == request_mode.item and "item" or "fluid", name = self.item,quality  = self.quality}, min = self:get_current_amount(),max = self:get_current_amount()})
      section.set_slot(2, { value = {type = "virtual", name = "signal-D",quality  = "normal"},min = self:get_drone_item_count(),max = self:get_drone_item_count()})
    end



    -- local signal
    -- if self.item then
    --   signal = {signal = {type = self.mode == request_mode.item and "item" or "fluid", name = self.item}, count = self:get_current_amount()}
    -- end
    -- behavior.set_signal(1, signal)
    -- local drone_signal
    -- if self.item then
    --   drone_signal = {signal = {type = "virtual", name = "signal-D"}, count = self:get_drone_item_count()}
    -- end
    -- behavior.set_signal(2, drone_signal)
  end
end

function request_depot:update()
  self:check_request_change()
  self:check_fuel_amount()
  self:check_drone_validity()
  self:check_drone_amount()
  self:update_circuit_writer()
  self:make_request()
  self:update_sticker()
  self:update_circuit_reader()
  self:push_fluid_hack()
end

function request_depot:suicide_all_drones()
  for k, drone in pairs (self.drones) do
    if drone.entity.valid then
      drone:suicide()
    else
      drone:clear_drone_data()
      self:remove_drone(drone)
    end
  end
end

function request_depot:set_request_mode()
  self.mode = nil
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
  if not requested_item then
    self.item = nil
    self.quality = nil
    self.type = nil
    return
  end
  if self.item == requested_item.name and self.quality == requested_item.quality then
    return
  end

  self:set_request_mode()

  if self.item then
    self:remove_from_network()
    self:suicide_all_drones()
  end

  self.item = requested_item.name
  self.quality = requested_item.quality
  self.type = requested_item.type

  if not self.item then return end

  self:add_to_network()

end

function request_depot:get_requested_item()
  local recipe,quality = self.entity.get_recipe()
  if not recipe or not recipe.products or not recipe.products[1] then return end
  return {name = recipe.products[1].name,quality = quality.name,type = recipe.products[1].type}
end

local stack_cache = {}
local get_stack_size = function(item)
  local size = stack_cache[item]
  if not size then
    local prototype = prototypes.item[item]
    if not prototype then error("what? "..item) end
    size = prototype.stack_size
    stack_cache[item] = size
  end
  return size
end

function request_depot:get_stack_size()

  if self.mode == request_mode.item then
    return get_stack_size(self.item)
  end


  if self.mode == request_mode.fluid then
    return drone_fluid_capacity
  end

end

function request_depot:get_request_size()
  return self:get_stack_size() * (1 + request_depot.transport_technologies.get_transport_capacity_bonus(self.entity.force.index))
end

function request_depot:get_output_inventory()
  --return self.entity.get_output_inventory()
  if not self.output_inventory then
    self.output_inventory = self.entity.get_output_inventory()
  end
  return self.output_inventory
end

function request_depot:get_drone_inventory()
  if not self.drone_inventory then
    self.drone_inventory = self.entity.get_inventory(defines.inventory.assembling_machine_input)
                    end
  return self.drone_inventory
  --return self.entity.get_inventory(defines.inventory.assembling_machine_input)
end

function request_depot:get_active_drone_count()
  return table_size(self.drones)
end

function request_depot:get_fuel_amount()
  return self.entity.get_fluid_count(get_fuel_fluid())
end

function request_depot:can_spawn_drone()
  return self:get_drone_item_count() > self:get_active_drone_count()
end

function request_depot:get_drone_item_count()
  return self:get_drone_inventory().get_item_count({name = "transport-drone",quality = self.quality})
end

function request_depot:get_output_fluidbox()
  return self.entity.fluidbox[2]
end

function request_depot:set_output_fluidbox(box)
  self.entity.fluidbox[2] = box
end

function request_depot:get_current_amount()
  if self.mode == request_mode.item then
    return self:get_output_inventory().get_item_count({name = self.item, quality = self.quality})
  end

  if self.mode == request_mode.fluid then
    local box = self:get_output_fluidbox()
    return (box and box.amount or 0)
  end
end

function request_depot:push_fluid_hack()
  if self.mode == request_mode.fluid then
    local box = self:get_output_fluidbox()
    local connected_pipelines = self.entity.fluidbox.get_connections(2)
	for i, next_box in ipairs(connected_pipelines) do
	  for j = 1, #next_box do
		local next_fluid = next_box[j]
		if (box and next_fluid and next_fluid.name == box.name) or not next_fluid then
		  local old_amount = next_fluid and next_fluid.amount or 0
		  local old_temperature = next_fluid and next_fluid.temperature or 0
		  local space = next_box.get_capacity(j) - old_amount
		  local push_amount = math.min(space, box and box.amount or 0)
		  if push_amount > 0 then
			next_box[j] = { name = box.name, amount = old_amount + push_amount, temperature = ((old_amount * old_temperature) + (push_amount * box.temperature)) / (old_amount + push_amount) }
			local new_next_fluid = next_box[j]
			local new_amount = new_next_fluid and new_next_fluid.amount or 0
			local pushed_amount = math.max(new_amount - old_amount, 0)
			box.amount = box.amount - pushed_amount
			if box.amount <= 0 then box = nil end
			self:set_output_fluidbox(box)
			box = self:get_output_fluidbox()
		  end
		end
	  end
	end	
  end
end


function request_depot:get_storage_size()
  return self:get_drone_item_count() * self:get_request_size()
end

function request_depot:should_order()
  if self:get_fuel_amount() < fuel_amount_per_drone then
    return
  end

  if self.circuit_limit == 0 then return end

  local size = self.circuit_limit or self:get_storage_size()
  local missing = size - self:get_current_amount()

  local should_send_drone_count = math.ceil(missing / self:get_request_size())
  return self:get_active_drone_count() < should_send_drone_count

end

function request_depot:update_circuit_writer()
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
    local condition = circuit_condition
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

local min = math.min
function request_depot:dispatch_drone(depot, count)

  local drone = self.transport_drone.new(self, self.item)
  drone:pickup_from_supply(depot, self.item,self.quality, count)
  self:remove_fuel(fuel_amount_per_drone)

  self.drones[drone.index] = drone

  self:update_sticker()
end

local valid_item_cache = {}
local is_valid_item = function(item_name)
  local bool = valid_item_cache[item_name]
  if bool ~= nil then
    return bool
  end
  valid_item_cache[item_name] = prototypes.item[item_name] ~= nil
  return valid_item_cache[item_name]
end

local valid_fluid_cache = {}
local is_valid_fluid = function(fluid_name)
  local bool = valid_fluid_cache[fluid_name]
  if bool ~= nil then
    return bool
  end
  valid_fluid_cache[fluid_name] = prototypes.fluid[fluid_name] ~= nil
  return valid_fluid_cache[fluid_name]
end

function request_depot:take_item(name,quality, count, temperature)
  if not count then error("NO COUMT?") end
  if self.mode == request_mode.item and is_valid_item(name) then
    self.entity.get_output_inventory().insert({name = name,quality = quality, count = count})
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

function request_depot:remove_drone(drone, remove_item)
  self.drones[drone.index] = nil
  if remove_item then
    self:get_drone_inventory().remove{name = "transport-drone", count = 1}
  end
  self:update_sticker()
end

function request_depot:update_sticker()

  if not self.item then
    -- if self.rendering and rendering.is_valid(self.rendering) then
    if self.rendering~= nil then
      self.rendering.destroy()
      self.rendering = nil
    end
    return
  end

  if self.rendering ~= nil then
    self.rendering.text = self:get_active_drone_count().."/"..self:get_drone_item_count()
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
  -- self.entity.surface.create_entity{name = "tutorial-flying-text", position = self.entity.position, text = string}
end

function request_depot:add_to_network()
  self.network_id = self.road_network.add_depot(self, "request")
end

function request_depot:remove_from_network()
  self.road_network.remove_depot(self, "request")
  self.network_id = nil
end

function request_depot:on_removed()
  self:suicide_all_drones()
  self.corpse.destroy()
end

function request_depot:on_config_changed()
  self:set_request_mode()
  self.fuel_on_the_way = self.fuel_on_the_way or 0
end

return request_depot