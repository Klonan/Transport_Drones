local shared = require("shared")
local transport_technologies = require("script/transport_technologies")

local fuel_amount_per_drone = shared.fuel_amount_per_drone
local fuel_consumption_per_meter = shared.fuel_consumption_per_meter
local drone_pollution_per_second = shared.drone_pollution_per_second

local script_data =
{
  drones = {},
  riding_players = {},
  reset_to_be_taken_again = true
}

local fuel_fluid
local get_fuel_fluid = function()
  if fuel_fluid then
    return fuel_fluid
  end
  fuel_fluid = game.recipe_prototypes["fuel-depots"].products[1].name
  return fuel_fluid
end

local transport_drone = {}

transport_drone.metatable = {__index = transport_drone}

local add_drone = function(drone)
  script_data.drones[drone.index] = drone
end

local remove_drone = function(drone)
  script_data.drones[drone.index] = nil
end

local get_drone = function(index)

  local drone = script_data.drones[index]
  
  if not drone then
    return
  end

  if not drone.entity.valid then
    drone:clear_drone_data()
    return
  end

  return drone

end


local states =
{
  going_to_supply = 1,
  return_to_requester = 2,
  waiting_for_reorder = 3,
  delivering_fuel = 4
}

local get_drone_speed = function(force_index)
  return (0.10 * (1 + transport_technologies.get_transport_speed_bonus(force_index))) + (math.random() / 32)
end

local variation_count = shared.variation_count

local random = math.random
local get_drone_name = function()
  return "transport-drone-"..random(variation_count)
end


local player_leave_drone = function(player)

  local drone = script_data.riding_players[player.index]
  if not drone then return end

  script_data.riding_players[player.index] = nil
  drone.riding_player = nil
  drone:update_speed()

end

local player_enter_drone = function(player, drone)

  script_data.riding_players[player.index] = drone
  drone.riding_player = player.index
  drone:update_speed()

end


transport_drone.new = function(request_depot)

  local entity = request_depot.entity.surface.create_entity{name = get_drone_name(), position = request_depot.corpse.position, force = request_depot.entity.force}
  
  local drone =
  {
    entity = entity,
    request_depot = request_depot,
    index = tostring(entity.unit_number),
    state = 0,
    requested_count = 0,
    tick_created = game.tick
  }
  setmetatable(drone, transport_drone.metatable)
  add_drone(drone)

  entity.ai_settings.path_resolution_modifier = -1
  
  return drone
end

function transport_drone:update_speed()
  local speed = get_drone_speed(self.entity.force.index)
  if self.riding_player then
    speed = speed * 1.5
  end
  self.entity.speed = speed
end

function transport_drone:add_slow_sticker()
  self.entity.surface.create_entity{name = "drone-slowdown-sticker", position = self.entity.position, target = self.entity, force = "neutral"}
end

function transport_drone:pickup_from_supply(supply, count)
  self.supply_depot = supply
  self.requested_count = count
  self.supply_depot:add_to_be_taken(self.request_depot.item, count)

  self:add_slow_sticker()
  self:update_speed()
  self.state = states.going_to_supply

  self:go_to_depot(self.supply_depot)

end

function transport_drone:deliver_fuel(depot, amount)

  self.target_depot = depot
  self.fuel_amount = amount
  self.state = states.delivering_fuel
  self.target_depot.fuel_on_the_way = (self.target_depot.fuel_on_the_way or 0) + amount

  self:add_slow_sticker()
  self:update_speed()
  self:update_sticker()

  self:go_to_depot(self.target_depot)

end

function transport_drone:retry_command()

  local distance = 1.5
  if self.entity.ai_settings.path_resolution_modifier == -1 then
    self.entity.ai_settings.path_resolution_modifier = 0
    distance = 0.5
  end

  if self.state == states.going_to_supply then
    if self.supply_depot.entity.valid then
      self:go_to_depot(self.supply_depot, distance)
    else
      self:return_to_requester()
    end
    return
  end

  if self.state == states.delivering_fuel then
    if self.target_depot.entity.valid then
      self:go_to_depot(self.target_depot, distance)
    else
      self:return_to_requester()
    end
    return
  end
  
  if self.state == states.waiting_for_reorder then
    self:say("Forgive me master")
    self:suicide()
    return
  end

  if self.state == states.return_to_requester then
    if self.request_depot.entity.valid then
      self:go_to_depot(self.request_depot, distance)
    else
      self:suicide()
    end
    return
  end

end

function transport_drone:process_failed_command()

  if (self.failed_command_count or 0) < 2 then
    self.failed_command_count = (self.failed_command_count or 0) + 1
    self:retry_command()
    return
  end

  self:say("F")

  if self.state == states.going_to_supply then
    self:return_to_requester()
    return
  end

  if self.state == states.delivering_fuel then
    self:return_to_requester()
    return
  end

  if self.state == states.waiting_for_reorder then
    self:say("Forgive me master")
    self:suicide()
    return
  end

  if self.state == states.return_to_requester then
    self:suicide()
    return
  end

end

local distance = util.distance
function transport_drone:distance(position)
  return distance(self.entity.position, position)
end

local min = math.min
function transport_drone:process_pickup()

  if not self.request_depot.item then
    self:return_to_requester()
    return
  end
  
  local available_count = self.requested_count + self.supply_depot:get_available_item_count(self.request_depot.item)

  local to_take = min(available_count, self.request_depot:get_request_size())

  if to_take > 0 then

    local given_count = self.supply_depot:give_item(self.request_depot.item, to_take)

    if given_count > 0 then
      self.held_item = self.request_depot.item
      self.held_count = given_count
      self:update_sticker()
    end

  end

  self:add_slow_sticker()
  self:update_speed()
  self:return_to_requester()
  
end

function transport_drone:process_deliver_fuel()

  self.target_depot.entity.insert_fluid({name = get_fuel_fluid(), amount = self.fuel_amount})

  self:add_slow_sticker()
  self:update_speed()
  self:return_to_requester()
  
end

function transport_drone:return_to_requester()

  if self.state == states.going_to_supply then
    if self.supply_depot and self.request_depot.item then
      self.supply_depot:add_to_be_taken(self.request_depot.item, -self.requested_count)
    end
  end

  if self.state == states.delivering_fuel then
    if self.target_depot then
      self.target_depot.fuel_on_the_way = self.target_depot.fuel_on_the_way - self.fuel_amount
      self.fuel_amount = nil
    end
  end
  
  if not self.request_depot.entity.valid then
    self:suicide()
    return
  end

  self:update_sticker()

  self.state = states.return_to_requester
  

  self:go_to_depot(self.request_depot)

end

function transport_drone:update_sticker()


  if self.background_rendering then
    rendering.destroy(self.background_rendering)
    self.background_rendering = nil
  end

  if self.item_rendering then
    rendering.destroy(self.item_rendering)
    self.item_rendering = nil
  end

  if self.held_item then

    local sprite
    if game.item_prototypes[self.held_item] then
      sprite = "item/"..self.held_item
    elseif game.fluid_prototypes[self.held_item] then
      sprite = "fluid/"..self.held_item
    end
    
    self.background_rendering = rendering.draw_sprite 
    {
      sprite = "utility/entity_info_dark_background",
      target = self.entity,
      target_offset = self.entity.prototype.sticker_box.left_top,
      surface = self.entity.surface,
      forces = {self.entity.force},
      only_in_alt_mode = true,
      --target_offset = {0, -0.5},
      x_scale = 0.6,
      y_scale = 0.6,
    }
    
    self.item_rendering = rendering.draw_sprite
    {
      sprite = sprite,
      target = self.entity,
      target_offset = self.entity.prototype.sticker_box.left_top,
      surface = self.entity.surface,
      forces = {self.entity.force},
      only_in_alt_mode = true,
      --target_offset = {0, -0.5},
      x_scale = 0.6,
      y_scale = 0.6,
    }
  
  end

  if self.fuel_amount then

    self.background_rendering = rendering.draw_sprite 
    {
      sprite = "utility/entity_info_dark_background",
      target = self.entity,
      target_offset = self.entity.prototype.sticker_box.left_top,
      surface = self.entity.surface,
      forces = {self.entity.force},
      only_in_alt_mode = true,
      --target_offset = {0, -0.5},
      x_scale = 0.6,
      y_scale = 0.6,
    }
    
    self.item_rendering = rendering.draw_sprite
    {
      sprite = "fluid/"..get_fuel_fluid(),
      target = self.entity,
      target_offset = self.entity.prototype.sticker_box.left_top,
      surface = self.entity.surface,
      forces = {self.entity.force},
      only_in_alt_mode = true,
      --target_offset = {0, -0.5},
      x_scale = 0.6,
      y_scale = 0.6,
    }
    
  end

end

function transport_drone:suicide()
  self:say("S")

  self:clear_drone_data()

  if self.request_depot.entity.valid then
    self.request_depot:remove_drone(self)
  end
  self.entity.force = "neutral"
  self.entity.die()
end

function transport_drone:process_return_to_requester()

  if not self.request_depot.entity.valid then
    self:suicide()
    return
  end

  if self.held_item then
    local temperature = self.supply_depot and self.supply_depot.entity.valid and self.supply_depot.get_temperature and self.supply_depot:get_temperature()
    self.request_depot:take_item(self.held_item, self.held_count, temperature)
    self.held_item = nil
  end

  self:update_sticker()
  self:refund_fuel()

  if self.supply_depot then
    self:wait_for_reorder()
    return
  end

  self:remove_from_depot()

end

local random = math.random
function transport_drone:wait_for_reorder()
  self.state = states.waiting_for_reorder
  self.entity.set_command
  {
    type = defines.command.stop,
    ticks_to_wait = random(20, 30),
    distraction = defines.distraction.none
  }
end

function transport_drone:refund_fuel()
  local age = game.tick - (self.tick_created or game.tick - 1)
  local consumption = age * self.entity.speed * fuel_consumption_per_meter
  
  local pollution = (age / 60) * drone_pollution_per_second
  game.pollution_statistics.on_flow("transport-drone-1", pollution)
  
  --self:say(consumption)
  self.entity.force.fluid_production_statistics.on_flow(get_fuel_fluid(), -consumption)
  local fuel_refund = fuel_amount_per_drone - consumption
  --self:say(fuel_refund)

  if fuel_refund > 0 then
  self.request_depot.entity.insert_fluid({name = get_fuel_fluid(), amount = fuel_refund})
  elseif fuel_refund < 0 then
    self.request_depot.entity.remove_fluid({name = get_fuel_fluid(), amount = -fuel_refund})
  end

end

function transport_drone:remove_from_depot()

  self.request_depot:remove_drone(self)
  self:clear_drone_data()
  self.entity.destroy()

end

local min = math.min
function transport_drone:process_reorder()

  if not self.supply_depot.entity.valid then
    self:remove_from_depot()
    return
  end

  if not self.request_depot.entity.valid then
    self:suicide()
    return
  end

  if not self.request_depot:should_order(true) then
    self:remove_from_depot()
    return
  end

  local item_count = min(self.request_depot:get_request_size(), self.supply_depot:get_available_item_count(self.request_depot.item))
  if item_count <= self.request_depot:get_minimum_request_size() then 
    self:remove_from_depot()
    return
  end
  
  self.request_depot:remove_fuel(fuel_amount_per_drone)
  self.tick_created = game.tick
  self:pickup_from_supply(self.supply_depot, item_count)

end

function transport_drone:update(event)
  if not self.entity.valid then return end
  
  if event.result ~= defines.behavior_result.success then
    self:process_failed_command()
    return
  end

  if self.failed_command_count then
    self.failed_command_count = nil
  end

  if self.state == states.going_to_supply then
    self:process_pickup()
    return
  end

  if self.state == states.delivering_fuel then
    self:process_deliver_fuel()
    return
  end

  if self.state == states.return_to_requester then
    self:process_return_to_requester()
    return
  end

  if self.state == states.waiting_for_reorder then
    self:process_reorder()
    return
  end
end

function transport_drone:say(text)
  self.entity.surface.create_entity{name = "flying-text", position = self.entity.position, text = text}
end

function transport_drone:go_to_position(position, radius)
  self.entity.set_command
  {
    type = defines.command.go_to_location,
    destination = position,
    radius = radius or 1,
    distraction = defines.distraction.none,
    pathfind_flags = {prefer_straight_paths = false, use_cache = false},
  }
end

function transport_drone:go_to_entity(entity, radius)
  self.entity.set_command
  {
    type = defines.command.go_to_location,
    destination_entity = entity,
    radius = radius or 1,
    distraction = defines.distraction.none,
    pathfind_flags = {prefer_straight_paths = false, use_cache = false}
  }
end

local random = math.random
function transport_drone:go_to_depot(depot, radius)
  self.entity.set_command
  {
    type = defines.command.go_to_location,
    destination_entity = depot.corpse,
    distraction = defines.distraction.none,
    radius = radius or 0.5,
    pathfind_flags = {prefer_straight_paths = (random() > 0.5), use_cache = false, no_break = false}
  }
end

function transport_drone:clear_drone_data()
  if self.state == states.going_to_supply then
    self.supply_depot:add_to_be_taken(self.request_depot.item, -self.requested_count)
  end

  if self.state == states.delivering_fuel then
    if self.target_depot and self.fuel_amount then
      self.target_depot.fuel_on_the_way = self.target_depot.fuel_on_the_way - self.fuel_amount
      self.fuel_amount = nil
    end
  end

  if self.riding_player then
    local player = game.get_player(self.riding_player)
    if player then player_leave_drone(player) end
  end
  
  remove_drone(self)
end

function transport_drone:handle_drone_deletion()
  if self.entity.valid then
    self:say("D")
  end

  self:clear_drone_data()

  if self.request_depot.entity.valid then
    self.request_depot:remove_drone(self, true)
  end
  
end

local on_ai_command_completed = function(event)
  local drone = get_drone(tostring(event.unit_number))
  if not drone then return end
  drone:update(event)
end

local on_entity_removed = function(event)
  local entity = event.entity
  if not (entity and entity.valid) then return end

  local unit_number = entity.unit_number
  if not unit_number then return end

  local drone = get_drone(tostring(unit_number))
  if not drone then return end

  if event.force then
    entity.force.kill_count_statistics.on_flow("transport-drone-1", 1)
    event.force.kill_count_statistics.on_flow("transport-drone-1", -1)
  end

  drone:handle_drone_deletion()


end

local follow_drone_hotkey = function(event)
  local player = game.get_player(event.player_index)

  if script_data.riding_players[player.index] then
    player_leave_drone(player)
    return
  end

  if player.vehicle then
    --He is getting out of a vehicle.
    return
  end

  local radius = player.character and player.character.prototype.enter_vehicle_distance or 5

  if player.surface.count_entities_filtered{type = "car", force = player.force, position = player.position, radius = radius, limit = 1} > 0 then
    --There is a vehicle nearby, let him get into that.
    return
  end

  local units = player.surface.find_entities_filtered{type = "unit", force = player.force, position = player.position, radius = radius}

  for k, unit in pairs (units) do
    local drone = get_drone(tostring(unit.unit_number))
    if not drone then
      units[k] = nil
    elseif drone.riding_player then 
      units[k] = nil
    end
  end

  if not next(units) then return end

  local closest = player.surface.get_closest(player.position, units)
  if not closest then return end

  local drone = get_drone(tostring(closest.unit_number))
  player_enter_drone(player, drone)

end

local floor = math.floor
local to_direction = function(orientation)
  local direction = floor(8 * (orientation + (1 / 16)))
  if direction >= 8 then direction = 0 end
  return direction
end


local get_orientation = function(source_position, target_position)

  -- Angle in rads
  local angle = util.angle(target_position, source_position)

  -- Convert to orientation
  local orientation =  (angle / (2 * math.pi)) - 0.25
  if orientation < 0 then orientation = orientation + 1 end

  return orientation

end

local smoothing = 0.1

local on_tick = function(event)
  if not next(script_data.riding_players) then return end
  local players = game.players
  for player_index, drone in pairs (script_data.riding_players) do
    local player = players[player_index]
    if player and player.valid then
      if drone.entity and drone.entity.valid then
        
        local player_position = player.position
        local position = drone.entity.position
        local shift = drone.entity.prototype.sticker_box.left_top
        local target_position = {x = position.x + shift.x, y = position.y + shift.y}
        local dx, dy = (target_position.x - player_position.x) * smoothing, (target_position.y - player_position.y) * smoothing

        local final_position = {player_position.x + dx, player_position.y + dy}
        player.teleport(final_position)
        if player.character then
          --player.character.walking_state = {walking = false, direction = to_direction(drone.entity.orientation)}
          player.character.direction = to_direction(get_orientation(player_position, final_position))
        end
      end
    end
  end
end

transport_drone.events =
{
  --[defines.events.on_built_entity] = on_built_entity,
  --[defines.events.on_robot_built_entity] = on_built_entity,
  --[defines.events.script_raised_revive] = on_built_entity,
  --[defines.events.script_raised_built] = on_built_entity,

  [defines.events.on_player_mined_entity] = on_entity_removed,
  [defines.events.on_robot_mined_entity] = on_entity_removed,

  [defines.events.on_entity_died] = on_entity_removed,
  [defines.events.script_raised_destroy] = on_entity_removed,

  [defines.events.on_ai_command_completed] = on_ai_command_completed,
  
  ["follow-drone"] = follow_drone_hotkey,
  [defines.events.on_tick] = on_tick,
}

transport_drone.on_load = function()
  script_data = global.transport_drone or script_data
  for unit_number, drone in pairs (script_data.drones) do
    setmetatable(drone, transport_drone.metatable)
  end
end

transport_drone.on_init = function()
  global.transport_drone = global.transport_drone or script_data
  game.map_settings.path_finder.use_path_cache = false
end

transport_drone.on_configuration_changed = function()
  script_data.riding_players = script_data.riding_players or {}

  if not script_data.reset_to_be_taken_again then
    script_data.reset_to_be_taken_again = true
    for k, drone in pairs (script_data.drones) do
      if drone.state == states.going_to_supply then
        local count = math.min(tonumber(drone.requested_count) or 0, drone.request_depot:get_request_size())
        if count ~= count then count = drone.request_depot:get_request_size() end
        drone:pickup_from_supply(drone.supply_depot, count)
      end
    end
  end

end

transport_drone.get_drone = get_drone

transport_drone.get_drone_count = function()
  return table_size(script_data.drones)
end

return transport_drone
