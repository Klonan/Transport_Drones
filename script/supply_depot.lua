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

local supply_depot_built = function(entity)
  local position = entity.position
  local direction = entity.direction
  local force = entity.force
  local surface = entity.surface
  local offset = corpse_offsets[direction]
  entity.destroy()
  local chest = surface.create_entity{name = "supply-depot-chest", position = position, force = force}
  local corpse = surface.create_entity{name = "caution-corpse", position = {position.x + offset[1], position.y + offset[2]}}
  corpse.corpse_expires = false
  script_data.supply_depots[chest.unit_number] = {chest = chest, corpse = corpse}
end


local on_created_entity = function(event)
  local entity = event.entity or event.created_entity
  if not (entity and entity.valid) then return end

  if entity.name ~= "supply-transport-depot" then return end

  supply_depot_built(entity)
end

local lib = {}

lib.events =
{
  [defines.events.on_built_entity] = on_created_entity
}

lib.on_init = function()
  global.supply_depots = global.supply_depots or script_data
end

lib.on_load = function()
  script_data = global.supply_depots or script_data
end

return lib