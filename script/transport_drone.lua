
local script_data =
{
  drones = {}
}

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
    drone:clear_things(index)
    return
  end

  return drone

end

local get_drone_mining_speed = function()
  return 0.5
end

local mining_times = {}
local get_mining_time = function(entity)

  local name = entity.name
  local time = mining_times[name]
  if time then return time end

  time = entity.prototype.mineable_properties.mining_time
  mining_times[name] = time
  return time

end

local interval = shared.mining_interval
local damage = shared.mining_damage
local ceil = math.ceil
local max = math.max
local min = math.min

local proxy_names = {}
local get_proxy_name = function(entity)

  local entity_name = entity.name
  local proxy_name = proxy_names[entity_name]
  if proxy_name then
    return proxy_name
  end

  if game.entity_prototypes[shared.attack_proxy_name..entity.name] then
    proxy_name = shared.attack_proxy_name..entity.name
  else
    local size = min(ceil((max(entity.get_radius() - 0.1, 0.25)) * 2), 10)
    proxy_name = shared.attack_proxy_name..size
  end

  proxy_names[entity_name] = proxy_name

  return proxy_name

end


local states =
{
  going_to_supply = 1,
  return_to_requester = 2
}

local random = math.random
local product_amount = function(product)

  if product.probability < 1 and random() >= product.probability then
    return 0
  end

  if product.amount then
    return product.amount
  end

  return random(product.amount_min, product.amount_max)

end


transport_drone.new = function(request_depot, supply_depot, requested_name)

  local entity = request_depot.entity.surface.create_entity{name = "transport-drone", position = request_depot.corpse.position, force = request_depot.entity.force}
  
  local drone =
  {
    entity = entity,
    request_depot = request_depot,
    supply_depot = supply_depot,
    index = tostring(entity.unit_number),
    state = states.going_to_supply
  }

  entity.surface.create_entity{name = "drone-slowdown-sticker", position = entity.position, target = entity, force = "neutral"}

  entity.ai_settings.path_resolution_modifier = 0
  entity.speed = entity.speed * 6 + (math.random() / 20)
  
  setmetatable(drone, transport_drone.metatable)

  add_drone(drone)

  entity.set_command
  {
    type = defines.command.go_to_location,
    destination_entity = supply_depot.corpse,
    distraction = defines.distraction.none,
    radius = 0.5,
    pathfind_flags = {prefer_straight_paths = false, use_cache = false}
  }

  return drone
end

function transport_drone:process_return_to_depot()

  local depot = self.depot

  if not (depot and depot.entity.valid) then
    --self:say("My depot isn't valid!")
    self:cancel_command()
    return
  end

  if distance(self.entity.position, depot:get_spawn_position()) > 1 then
    self:return_to_depot()
    return
  end

  if self.stack and (self.stack.count or 0) > 0 and self.stack.name == depot.item then
    depot:get_output_inventory().insert(self.stack)
    self.stack = nil
  end

  self:request_order()

end

function transport_drone:oof()
  local position = self.entity.surface.find_non_colliding_position(self.entity.name, self.entity.position, 0, 0.1, false)
  self.entity.teleport(position)
  --self:say("oof")
end

function transport_drone:process_failed_command()

  self:say("F")

  if self.state == states.going_to_supply then
    self:return_to_requester()
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

function transport_drone:process_pickup()
  if not self.request_depot.item then
    self:return_to_requester()
    return
  end

  self.supply_depot:remove_to_be_taken(self.request_depot.item, self.request_depot:get_stack_size())

  local given_count = self.supply_depot:give_item(self.request_depot.item, self.request_depot:get_stack_size())

  if given_count > 0 then
    self.held_item = self.request_depot.item
    self.held_count = given_count
    self:update_sticker()
  end

  self.entity.surface.create_entity{name = "drone-slowdown-sticker", position = self.entity.position, target = self.entity, force = "neutral"}
  self:return_to_requester()
  
end

function transport_drone:return_to_requester()
  self.state = states.return_to_requester

  if not self.request_depot.entity.valid then
    self.entity.die()
    return
  end

  self.entity.set_command
  {
    type = defines.command.go_to_location,
    destination_entity = self.request_depot.corpse,
    distraction = defines.distraction.none,
    radius = 0.5,
    pathfind_flags = {prefer_straight_paths = false, use_cache = false}
  }

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

  if not self.held_item then
    return
  end

  self.background_rendering = rendering.draw_sprite 
  {
    sprite = "utility/entity_info_dark_background",
    target = self.entity,
    surface = self.entity.surface,
    forces = {self.entity.force},
    only_in_alt_mode = true,
    --target_offset = {0, -0.5},
    x_scale = 0.6,
    y_scale = 0.6,
  }

  self.item_rendering = rendering.draw_sprite
  {
    sprite = "item/"..self.held_item,
    target = self.entity,
    surface = self.entity.surface,
    forces = {self.entity.force},
    only_in_alt_mode = true,
    --target_offset = {0, -0.5},
    x_scale = 0.6,
    y_scale = 0.6,
  }


end

function transport_drone:suicide()
  self:say("S")

  self:clear_drone_data()

  if self.request_depot.entity.valid then
    self.request_depot:remove_drone(self)
  end

  self.entity.die()
end

function transport_drone:process_return_to_requester()

  if not self.request_depot.entity.valid then
    self:suicide()
    return
  end

  if self.held_item then
    self.request_depot:take_item(self.held_item, self.held_count)
  end

  self.request_depot:remove_drone(self)
  self.entity.destroy()
  remove_drone(self)
end

function transport_drone:update(event)
  if not self.entity.valid then return end
  
  if event.result ~= defines.behavior_result.success then
    self:process_failed_command()
    return
  end

  if self.state == states.going_to_supply then
    self:process_pickup()
    return
  end

  if self.state == states.return_to_requester then
    self:process_return_to_requester()
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

function transport_drone:clear_drone_data()
  if self.state == states.going_to_supply then
    self.supply_depot:remove_to_be_taken(self.request_depot.item, self.request_depot:get_stack_size())
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

  drone:handle_drone_deletion()

end

local make_unselectable = function()
  if remote.interfaces["unit_control"] then
    remote.call("unit_control", "register_unit_unselectable", "transport-drone")
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
  make_unselectable()
end

transport_drone.on_configuration_changed = function()
  make_unselectable()
end

transport_drone.get_drone = get_drone

transport_drone.get_drone_count = function()
  return table_size(script_data.drones)
end

return transport_drone
