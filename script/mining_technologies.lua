local script_data =
{
  walking_speed = {},
  mining_speed = {},
  cargo_size = {},
  productivity_bonus = {}
}

local technology_effects =
{
  [shared.mining_speed_technology] = function(technology)
    local count = technology.level
    local force_index = technology.force.index
    script_data.mining_speed[force_index] = count * 0.2
    script_data.walking_speed[force_index] = count * 0.2
    script_data.cargo_size[force_index] = count * 1
  end,
  [shared.mining_productivity_technology] = function(technology)
    local count = technology.level
    local force_index = technology.force.index
    script_data.productivity_bonus[force_index] = count * 0.1
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

lib.get_walking_speed_bonus = function(force_index)
  return script_data.walking_speed[force_index] or 0
end

lib.get_mining_speed_bonus = function(force_index)
  return script_data.mining_speed[force_index] or 0
end

lib.get_cargo_size_bonus = function(force_index)
  return script_data.cargo_size[force_index] or 0
end

lib.get_productivity_bonus = function(force_index)
  return script_data.productivity_bonus[force_index] or 0
end

lib.on_load = function()
  script_data = global.mining_technologies or script_data
end

lib.on_init = function()
  global.mining_technologies = global.mining_technologies or script_data
end

lib.events =
{
  [defines.events.on_research_finished] = on_research_finished
}

return lib