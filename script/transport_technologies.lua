local script_data =
{
  transport_speed = {},
  transport_capacity = {},
}

local technology_effects =
{
  [shared.transport_speed_technology] = function(technology)
    local force_index = technology.force.index
    script_data.transport_speed[force_index] = technology.level * 0.2
  end,
  [shared.transport_capacity_technology] = function(technology)
    local force_index = technology.force.index
    script_data.transport_capacity[force_index] = technology.level
  end,
}


local on_research_finished = function(event)
  local technology = event.research
  local name = technology.name

  for effect_name, effect in pairs (technology_effects) do
    if name:find(effect_name, 0, true) then
      effect(technology)
      break
    end
  end

end

local lib = {}

lib.get_transport_speed_bonus = function(force_index)
  return script_data.transport_speed[force_index] or 0
end

lib.get_transport_capacity_bonus = function(force_index)
  return script_data.transport_capacity[force_index] or 0
end

lib.on_load = function()
  script_data = storage.transport_technologies or script_data
end

lib.on_init = function()
  storage.transport_technologies = storage.transport_technologies or script_data
end

lib.events =
{
  [defines.events.on_research_finished] = on_research_finished
}

return lib