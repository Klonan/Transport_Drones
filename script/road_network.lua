local script_data =
{
  networks = {},
  id_number = 0,
  node_map = {}
}

local new_id = function()
  script_data.id_number = script_data.id_number + 1
  local id = script_data.id_number
  script_data.networks[id] =
  {
    requesters = {},
    supply = {},
    id = id
  }
  return id
end

local merge_network = function(source, target)
  for k, requester in pairs (target.requesters) do
    source.requesters[k] = requester
  end
  target.requesters = nil
  for k, supplier in pairs (target.supply) do
    source.supply[k] = supplier
  end
  target.supply = nil

  script_data.networks[target.id] = nil
end

local get_network_by_id = function(id)
  return script_data.networks[id]
end

local neighbor_offsets = 
{
  {-1, 0},
  {1, 0},
  {0, -1},
  {0, 1},
}

local get_node_id = function(surface, x, y)

  local surface_map = script_data.node_map[surface]
  if not surface_map then return end

  local x_map = surface_map[x]
  if not x_map then return end

  return x_map[y]

end

local set_node_id = function(surface, x, y, id)
  
  local surface_map = script_data.node_map[surface]
  if not surface_map then return end

  local x_map = surface_map[x]
  if not x_map then return end

  x_map[y] = id

  game.surfaces[surface].create_entity{name = "flying-text", position =  {x, y}, text = id or "nil"}

  return true

end

local get_neighbors = function(surface, x, y)
  local neighbors = {}

  for k, offset in pairs (neighbor_offsets) do
    local id = get_node_id(surface, x + offset[1], y + offset[2])
    if id then
      neighbors[k] = id
    end
  end

  return neighbors

end

local get_neighbor_count = function(surface, x, y)
  local count = 0
  for k, offset in pairs (neighbor_offsets) do
    if get_node_id(surface, x + offset[1], y + offset[2]) then
      count = count + 1
    end
  end
  return count
end

local recursive_connection_check
recursive_connection_check = function(surface, x, y, tx, ty, checked, n)

  n = n + 1 
  
  game.surfaces[surface].create_entity{name = "flying-text", position =  {x, y}, text = n}

  if checked[x] and checked[x][y] then return end

  checked[x] = checked[x] or {}
  checked[x][y] = true

  if x == tx and y == ty then return true end

  for k, offset in pairs (neighbor_offsets) do
    local nx, ny = x + offset[1], y + offset[2]
    local node_id = get_node_id(surface, nx, ny)
    if node_id then
      local result = recursive_connection_check(surface, nx, ny, tx, ty, checked, n)
      if result then return true end
    end
  end
end

local recursive_set_id
recursive_set_id = function(surface, x, y, id)
  
  
  set_node_id(surface, x, y, id)
  
  for k, offset in pairs (neighbor_offsets) do
    local node_id = get_node_id(surface, x + offset[1], y + offset[2])
    if node_id and node_id ~= id then
      recursive_set_id(surface, x + offset[1], y + offset[2], id)
    end
  end

end

local road_network = {}

road_network.add_node = function(surface, x, y)

  local surface_map = script_data.node_map[surface]
  if not surface_map then
    surface_map = {}
    script_data.node_map[surface] = surface_map
  end

  local x_map = surface_map[x]
  if not x_map then
    x_map = {}
    surface_map[x] = {}
  end

  local prospective_id
  local merge_networks = false
  local neighbors = get_neighbors(surface, x, y)
  for k, id in pairs (neighbors) do
    if not prospective_id then
      prospective_id = id
    elseif id ~= prospective_id then
      --will need to merge network
      merge_networks = true
    end
  end

  if not prospective_id then
    prospective_id = new_id()
  end

  set_node_id(surface, x, y, prospective_id)

  if merge_networks then
    local network = get_network_by_id(prospective_id)
    for k, neighbor_id in pairs (neighbors) do
      if neighbor_id ~= prospective_id then
        merge_network(network, get_network_by_id(neighbor_id))
      end
    end
    recursive_set_id(surface, x, y, prospective_id)
  end


end

road_network.remove_node = function(surface, x, y)
  set_node_id(surface, x, y, nil)
  local count = get_neighbor_count(surface, x, y)
  if count == 1 then
    -- only 1 neighbor, no need to worry about anything.
    return
  end

  -- we could be splitting neighbors.
  local fx, fy
  for k, offset in pairs (neighbor_offsets) do
    local nx, ny = x + offset[1], y + offset[2]
    local id = get_node_id(surface, nx, ny)
    if id then
      if not fx then
        fx, fy = nx, ny 
      else
        if not (recursive_connection_check(surface, fx, fy, nx, ny, {}, 0)) then
          game.print("Gonna split the networks bois.")
        end
      end
    end
  end

end

road_network.get_network = function(surface, x, y)
  local id = get_node_id(surface, x, y)
  if id then return get_network_by_id(id) end
end

road_network.on_init = function()
  global.road_network = global.road_network or script_data
end

road_network.on_load = function()
  script_data = global.road_network or script_data
end

return road_network