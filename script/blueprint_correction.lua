
local tile_correction = 
{
  ["transport-drone-road"] = "transport-drone-proxy-tile"
}

local on_built_entity = function(event)
  local entity = event.created_entity
  if not (entity and entity.valid) then return end

  if entity.name ~= "tile-ghost" then
    return
  end

  local correct_name = tile_correction[entity.ghost_name]

  if not correct_name then return end

  local position = entity.position
  local force = entity.force
  local surface = entity.surface
  
  entity.destroy()

  surface.create_entity{name = "tile-ghost", inner_name = correct_name, position = position, force = force, surface = surface}

end

local lib = {}

lib.events =
{
  [defines.events.on_built_entity] = on_built_entity
}

return lib