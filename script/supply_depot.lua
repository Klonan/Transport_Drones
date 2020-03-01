local request_depot = require("script/request_depot")

local script_data = 
{
  supply_depots = {}
}

local corpse_offsets = 
{
  [0] = {0, -2},
  [2] = {2, 0},
  [4] = {0, 2},
  [6] = {-2, 0},
}

local supply_depot = {}
local depot_metatable = {__index = supply_depot}

function supply_depot.new(entity)
  local position = entity.position
  local direction = entity.direction
  local force = entity.force
  local surface = entity.surface
  local offset = corpse_offsets[direction]
  entity.destroy()
  local chest = surface.create_entity{name = "supply-depot-chest", position = position, force = force}
  local corpse = surface.create_entity{name = "caution-corpse", position = {position.x + offset[1], position.y + offset[2]}}
  corpse.corpse_expires = false

  local depot =
  {
    entity = chest,
    corpse = corpse,
    to_be_taken = {},
    index = tostring(chest.unit_number)
  }
  setmetatable(depot, depot_metatable)

  script_data.supply_depots[depot.index] = depot
end

function supply_depot:check_requests_for_item(name, count)

  local to_be_taken_count = self.to_be_taken[name] or 0
  local available = count - to_be_taken_count
  if available <= 0 then return end

  local request_depots = request_depot.get_depots_for_item(name)
  if not request_depots then return end
  if not next(request_depots) then return end

  for k, depot in pairs (request_depots) do
    local requested = depot:handle_offer(self, name, count)
    self.to_be_taken[name] = (self.to_be_taken[name] or 0) + requested
    count = count - requested
    if count <= 0 then return end
  end

end

function supply_depot:update()
  local items = self.entity.get_output_inventory().get_contents()
  for name, count in pairs(items) do
    self:check_requests_for_item(name, count)
  end
  --self:say("oh hi :)")
end

function supply_depot:say(string)
  self.entity.surface.create_entity{name = "flying-text", position = self.entity.position, text = string}
end

function supply_depot:give_item(requested_name, requested_count)
  self.to_be_taken[requested_name] = self.to_be_taken[requested_name] - requested_count
  local inventory = self.entity.get_output_inventory()
  local removed_count = inventory.remove({name = requested_name, count = requested_count})
  return removed_count
end

local on_created_entity = function(event)
  local entity = event.entity or event.created_entity
  if not (entity and entity.valid) then return end

  if entity.name ~= "supply-transport-depot" then return end

  supply_depot.new(entity)
end

local update_depots = function(event)
  for k, depot in pairs (script_data.supply_depots) do
    depot:update()
  end
end

local lib = {}

lib.events =
{
  [defines.events.on_built_entity] = on_created_entity
}

lib.on_nth_tick =
{
  [60] = update_depots
}

lib.on_init = function()
  global.supply_depots = global.supply_depots or script_data
end

lib.on_load = function()
  script_data = global.supply_depots or script_data
  for k, depot in pairs (script_data.supply_depots) do
    setmetatable(depot, depot_metatable)
  end
end

return lib