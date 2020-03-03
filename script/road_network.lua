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

local get_node = function(surface, x, y)

  local surface_map = script_data.node_map[surface]
  if not surface_map then return end

  local x_map = surface_map[x]
  if not x_map then return end

  return x_map[y]

end

local get_neighbors = function(surface, x, y)
  local neighbors = {}

  for k, offset in pairs (neighbor_offsets) do
    local node = get_node(surface, x + offset[1], y + offset[2])
    if node then
      neighbors[k] = node
    end
  end

  return neighbors

end

local get_neighbor_count = function(surface, x, y)
  local count = 0
  for k, offset in pairs (neighbor_offsets) do
    if get_node(surface, x + offset[1], y + offset[2]) then
      count = count + 1
    end
  end
  return count
end

local recursive_connection_check
recursive_connection_check = function(surface, x, y, tx, ty, checked, n)

  local node = get_node(surface, x, y)
  if not node then return end

  if checked[node] then return end

  checked[node] = true

  n = n + 1 
  
  --game.surfaces[surface].create_entity{name = "flying-text", position = {x, y}, text = n}

  if x == tx and y == ty then return true end

  for k, offset in pairs (neighbor_offsets) do
    local nx, ny = x + offset[1], y + offset[2]
    local result = recursive_connection_check(surface, nx, ny, tx, ty, checked, n)
    if result then return true end
  end
end

local recursive_set_id
recursive_set_id = function(surface, x, y, id)
  
  local node = get_node(surface, x, y)
  if not node then return end
  if node.id == id then return end

  game.surfaces[surface].create_entity{name = "flying-text", position = {x, y}, text = id}

  node.id = id

  if node.supply then
    for k, depot in pairs (node.supply) do
      depot:remove_from_network()
      depot:add_to_network()
    end
  end

  if node.requesters then
    for k, depot in pairs (node.requesters) do
      depot:remove_from_network()
      depot:add_to_network()
    end
  end
  
  for k, offset in pairs (neighbor_offsets) do
    recursive_set_id(surface, x + offset[1], y + offset[2], id)
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
    surface_map[x] = x_map
  end
  
  local node =
  {
    id = 0
  }
  x_map[y] = node

  
  local prospective_id
  local merge_networks = false
  local neighbors = get_neighbors(surface, x, y)
  for k, node in pairs (neighbors) do
    if not prospective_id then
      prospective_id = node.id
    elseif node.id ~= prospective_id then
      prospective_id = math.min(node.id, prospective_id)
      --will need to merge network
      merge_networks = true
    end
  end
  
  if not prospective_id then
    prospective_id = new_id()
  end

  node.id = prospective_id

  if merge_networks then
    for k, offset in pairs (neighbor_offsets) do
      local nx, ny = x + offset[1], y + offset[2]
      local node = get_node(surface, nx, ny)
      if node then
        if node.id ~= prospective_id then
          recursive_set_id(surface, nx, ny, prospective_id)
        end
      end
    end
  end

end

road_network.remove_node = function(surface, x, y)

  local node = get_node(surface, x, y)
  if not node then return end

  if node.supply and next(node.supply) then return true end
  if node.requesters and next(node.requesters) then return true end

  script_data.node_map[surface][x][y] = nil


  local count = get_neighbor_count(surface, x, y)
  if count == 1 then
    -- only 1 neighbor, no need to worry about anything.
    return
  end

  -- we could be splitting neighbors.
  local fx, fy
  for k, offset in pairs (neighbor_offsets) do
    local nx, ny = x + offset[1], y + offset[2]
    local neighbor = get_node(surface, nx, ny)
    if neighbor then
      if not fx then
        fx, fy = nx, ny 
      else
        if not (recursive_connection_check(surface, fx, fy, nx, ny, {}, 0)) then              
          recursive_set_id(surface, nx, ny, new_id()) 
        end
      end
    end
  end

end

road_network.get_network = function(surface, x, y)
  local node = get_node(surface, x, y)
  if not node then return end

  return get_network_by_id(node.id)
end


road_network.add_supply_depot = function(depot)
  local x, y = depot.node_position[1], depot.node_position[2]
  local surface = depot.entity.surface.index
  local node = get_node(surface, x, y)
  if not node then
    game.print("Oh no node for add supply??")
    return
  end

  
  
  node.supply = node.supply or {}
  node.supply[depot.index] = depot

  local network = get_network_by_id(node.id)
  network.supply[depot.index] = depot

  
  --game.print("Added supply to network "..network.id)

  return network.id
end

road_network.add_request_depot = function(depot, item_name)
  local x, y = depot.node_position[1], depot.node_position[2]
  local surface = depot.entity.surface.index
  local node = get_node(surface, x, y)
  if not node then
    game.print("Oh no node for add requester??")
    return
  end

  node.requesters = node.requesters or {}
  node.requesters[depot.index] = depot

  local network = get_network_by_id(node.id)

  local item_map = network.requesters[item_name]
  if not item_map then
    item_map = {}
    network.requesters[item_name] = item_map
  end

  item_map[depot.index] = depot

  --game.print("Added requester to network "..network.id)

  return network.id
end

road_network.get_request_depots = function(id, name)
  local network = get_network_by_id(id)
  return network.requesters[name]
end

road_network.on_init = function()
  global.road_network = global.road_network or script_data
end

road_network.on_load = function()
  script_data = global.road_network or script_data
end

road_network.get_network_by_id = get_network_by_id
road_network.get_node = get_node

return road_network