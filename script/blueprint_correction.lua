
local tile_correction =
{
  ["transport-drone-road"] = "transport-drone-proxy-tile"
}

local placement_check =
{
  ["transport-drone-proxy-tile"] = "road-tile-collision-proxy"
}

local correct_tile_ghost = function(entity, correct_name)

  local position = entity.position
  local force = entity.force
  local surface = entity.surface
  entity.destroy()
  surface.create_entity{name = "tile-ghost", inner_name = correct_name, position = position, force = force, surface = surface, raise_built = true}

end

local do_placement_check = function(entity, placement_check)

  if entity.surface.can_place_entity
    {
      name = placement_check,
      position = entity.position,
      build_check_type = defines.build_check_type.manual
    }
   then
    -- Bob the builder we can build it
    return
  end

  if entity.surface.can_place_entity
    {
      name = placement_check,
      position = entity.position,
      build_check_type = defines.build_check_type.manual_ghost,
      forced = true
    }
   then
    --We can build if we mark something for deconstruction.
    local colliding = entity.surface.find_entities_filtered
    {
      collision_mask = game.entity_prototypes[placement_check].collision_mask,
      force = "neutral",
      position = entity.position,
      radius = 1
    }
    for k, collider in pairs (colliding) do
      collider.order_deconstruction(entity.force)
    end
    return
  end

  entity.destroy()

end

local on_built_entity = function(event)
  local entity = event.created_entity
  if not (entity and entity.valid) then return end

  if entity.name ~= "tile-ghost" then
    return
  end

  local correct_name = tile_correction[entity.ghost_name]
  if correct_name then
    correct_tile_ghost(entity, correct_name)
    return
  end

  local placement_check = placement_check[entity.ghost_name]
  if placement_check then
    do_placement_check(entity, placement_check)
    return
  end



end

local lib = {}

lib.events =
{
  [defines.events.on_built_entity] = on_built_entity
}

return lib