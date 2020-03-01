local transport_drone = require("script/transport_drone")

local script_data = 
{
  request_depots = {},
  item_map = {}
}

local request_depot = {}
local depot_metatable = {__index = request_depot}

local corpse_offsets = 
{
  [0] = {0, -2},
  [2] = {2, 0},
  [4] = {0, 2},
  [6] = {-2, 0},
}

function request_depot.new(entity)

  local position = entity.position
  local direction = entity.direction
  local force = entity.force
  local surface = entity.surface
  local offset = corpse_offsets[direction]

  entity.destroy()

  local machine = surface.create_entity{name = "request-depot-machine", position = position, force = force}
  machine.active = false
  local corpse = surface.create_entity{name = "caution-corpse", position = {position.x + offset[1], position.y + offset[2]}}
  corpse.corpse_expires = false
  
  local depot =
  {
    entity = machine,
    corpse = corpse,
    index = tostring(machine.unit_number),
    on_the_way = 0
  }
  setmetatable(depot, depot_metatable)

  script_data.request_depots[depot.index] = depot

  return depot

end

function request_depot:check_request_change()
  local requested_item = self:get_requested_item()
  if self.item == requested_item then return end

  if self.item then
    script_data.item_map[self.item][self.index] = nil
    --cancel shit...
  end

  self.item = requested_item

  if not self.item then return end

  if not script_data.item_map[self.item] then
    script_data.item_map[self.item] = {}
  end

  script_data.item_map[self.item][self.index] = self

end

function request_depot:get_requested_item()
  local recipe = self.entity.get_recipe()
  if not recipe then return end
  return recipe.products[1].name
end

function request_depot:get_stack_size()
  return game.item_prototypes[self.item].stack_size
end

function request_depot:get_needed_item_count()
  local stack_size = self:get_stack_size()
  local needed = 100 * stack_size
  needed = needed - self.on_the_way
  return needed
end

function request_depot:handle_offer(supply_depot, name, count)
  local needed_count = self:get_needed_item_count()
  needed_count = math.min(needed_count, self:get_stack_size(), count)

  if math.random() < 0.5 then return 0 end

  self.on_the_way = self.on_the_way + needed_count

  local drone = transport_drone.new(self, supply_depot, name, needed_count)

  return needed_count
end

function request_depot:take_item(name, count)
  self.on_the_way = self.on_the_way - count
  self.entity.get_output_inventory().insert({name = name, count = count})
end

local on_created_entity = function(event)
  local entity = event.entity or event.created_entity
  if not (entity and entity.valid) then return end

  if entity.name ~= "request-transport-depot" then return end

  request_depot.new(entity)

end

local check_request_change = function(event)
  for k, request_depot in pairs (script_data.request_depots) do
    request_depot:check_request_change()
  end
end

local lib = {}

lib.events =
{
  [defines.events.on_built_entity] = on_created_entity
}

lib.on_nth_tick =
{
  [237] = check_request_change
}


lib.on_init = function()
  global.request_depots = global.request_depots or script_data
end

lib.on_load = function()
  script_data = global.request_depots or script_data
  for k, depot in pairs (script_data.request_depots) do
    setmetatable(depot, depot_metatable)
  end
end

lib.get_depots_for_item = function(item)
  return script_data.item_map[item]
end

return lib