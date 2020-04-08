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
    id = id
  }
  --game.print("New network "..id)
  return id
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
recursive_connection_check = function(surface, x, y, target_node, checked)

  local node = get_node(surface, x, y)
  if not node then return end

  if checked[node] then return end
  checked[node] = true

  --game.surfaces[surface].create_entity{name = "flying-text", position = {x, y}, text = "?"}

  if node == target_node then
    return true
  end

  for k, offset in pairs (neighbor_offsets) do
    local nx, ny = x + offset[1], y + offset[2]
    if recursive_connection_check(surface, nx, ny, target_node, checked) then
      return true
    end
  end
end

local recursive_set_id
recursive_set_id = function(surface, x, y, id)
  
  local node = get_node(surface, x, y)
  if not node then return end
  if node.id == id then return end

  --game.surfaces[surface].create_entity{name = "flying-text", position = {x, y}, text = id}

  node.id = id

  if node.depots then
    for k, depot in pairs (node.depots) do
      depot:remove_from_network()
      depot:add_to_network()
    end
  end

  for k, offset in pairs (neighbor_offsets) do
    recursive_set_id(surface, x + offset[1], y + offset[2], id)
  end

end

local clear_network = function(id)
  local network = script_data.networks[id]

  for k, name in pairs ({"supply", "mining", "fuel"}) do
    local depots = network[name]
    if depots then
      for k, depot in pairs (depots) do
        depot:remove_from_network()
        depot:add_to_network()
      end
    end
  end

  if network.requesters then
    for name, depots in pairs (network.requesters) do
      for k, depot in pairs (depots) do
        depot:remove_from_network()
        depot:add_to_network()
      end
    end
  end
  
  if network.buffers then
    for name, depots in pairs (network.buffers) do
      for k, depot in pairs (depots) do
        depot:remove_from_network()
        depot:add_to_network()
      end
    end
  end

  script_data.networks[id] = nil
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
        local old_id = node.id
        if old_id ~= prospective_id then
          recursive_set_id(surface, nx, ny, prospective_id)
          script_data.networks[old_id] = nil
        end
      end
    end
  end

  --game.print(table_size(script_data.networks))

end

road_network.remove_node = function(surface, x, y)

  local node = get_node(surface, x, y)
  if not node then return end
  
  if node.depots and next(node.depots) then
    return true
  end

  script_data.node_map[surface][x][y] = nil

  local count = get_neighbor_count(surface, x, y)
  
  --game.surfaces[surface].create_entity{name = "flying-text", position = {x, y}, text = count}

  if count == 0 then
    -- No neighbors, clear the network.    
    clear_network(node.id)
    return
  end

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
        if not (recursive_connection_check(surface, fx, fy, neighbor, {})) then              
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

  local network = get_network_by_id(node.id)

  if not network.supply then network.supply = {} end
  network.supply[depot.index] = depot

  return network.id
end

road_network.add_fuel_depot = function(depot)
  local x, y = depot.node_position[1], depot.node_position[2]
  local surface = depot.entity.surface.index
  local node = get_node(surface, x, y)

  local network = get_network_by_id(node.id)
  
  if not network.fuel then network.fuel = {} end
  network.fuel[depot.index] = depot

  return network.id
end

road_network.add_mining_depot = function(depot)
  local x, y = depot.node_position[1], depot.node_position[2]
  local surface = depot.entity.surface.index
  local node = get_node(surface, x, y)

  local network = get_network_by_id(node.id)

  if not network.mining then network.mining = {} end
  network.mining[depot.index] = depot

  return network.id
end

road_network.add_request_depot = function(depot, item_name)
  local x, y = depot.node_position[1], depot.node_position[2]
  local surface = depot.entity.surface.index
  local node = get_node(surface, x, y)

  local network = get_network_by_id(node.id)

  if not network.requesters then network.requesters = {} end

  local item_map = network.requesters[item_name]
  if not item_map then
    item_map = {}
    network.requesters[item_name] = item_map
  end

  item_map[depot.index] = depot

  return network.id
end

local shuffle = util.shuffle_table
local distance_squared = function(a, b)
  local dx = a[1] - b[1]
  local dy = a[2] - b[2]
  return (dx * dx) + (dy * dy)
end
local sort = table.sort

road_network.get_request_depots = function(id, name, node_position)
  local sort_function = function(depot_a, depot_b)
    return distance_squared(depot_a.node_position, node_position) < distance_squared(depot_b.node_position, node_position)
  end
  --local profiler = game.create_profiler()
  local network = get_network_by_id(id)
  if not network.requesters then return end
  local depots = network.requesters[name]
  if not depots then return end
  
  local to_shuffle = {}
  local i = 1
  for k, v in pairs (depots) do
    to_shuffle[i] = v
    i = i + 1
  end
  --shuffle(to_shuffle)
  sort(to_shuffle, sort_function)  

  --profiler.stop()
  --game.print({"", "Got depots ", profiler})
  --log({"", "Got depots ", profiler})
  return to_shuffle
end

road_network.add_buffer_depot = function(depot, item_name)
  local x, y = depot.node_position[1], depot.node_position[2]
  local surface = depot.entity.surface.index
  local node = get_node(surface, x, y)

  local network = get_network_by_id(node.id)

  if not network.buffers then network.buffers = {} end

  local item_map = network.buffers[item_name]
  if not item_map then
    item_map = {}
    network.buffers[item_name] = item_map
  end

  item_map[depot.index] = depot

  return network.id
end

road_network.get_buffer_depots = function(id, name, node_position)
  local sort_function = function(depot_a, depot_b)
    return distance_squared(depot_a.node_position, node_position) < distance_squared(depot_b.node_position, node_position)
  end
  --local profiler = game.create_profiler()
  local network = get_network_by_id(id)
  if not network.buffers then return end
  local depots = network.buffers[name]
  if not depots then return end
  
  local to_shuffle = {}
  local i = 1
  for k, v in pairs (depots) do
    to_shuffle[i] = v
    i = i + 1
  end
  --shuffle(to_shuffle)
  sort(to_shuffle, sort_function)  

  --profiler.stop()
  --game.print({"", "Got depots ", profiler})
  --log({"", "Got depots ", profiler})
  return to_shuffle
end

road_network.get_fuel_depots = function(id, node_position)
  local sort_function = function(depot_a, depot_b)
    return distance_squared(depot_a.node_position, node_position) < distance_squared(depot_b.node_position, node_position)
  end
  local network = get_network_by_id(id)
  local depots = network.fuel
  if not depots then return end
  
  local to_shuffle = {}
  local i = 1
  for k, v in pairs (depots) do
    to_shuffle[i] = v
    i = i + 1
  end
  --shuffle(to_shuffle)
  sort(to_shuffle, sort_function)  
  return to_shuffle
end

road_network.check_clear_lonely_node = function(surface, x, y)
  if next(get_neighbors(surface, x, y)) then
    -- We have a neighbor, do nothing.
    return
  end

  if road_network.remove_node(surface, x, y) then
    --depot on it or something
    return
  end

  local surface = game.surfaces[surface]
  local position = {x, y}
  surface.set_tiles
  {
    {
      name = surface.get_hidden_tile(position),
      position = position
    }
  }

end

road_network.on_init = function()
  global.road_network = global.road_network or script_data
end

road_network.on_load = function()
  script_data = global.road_network or script_data
end

road_network.on_configuration_changed = function()

end

road_network.get_network_by_id = get_network_by_id
road_network.get_node = get_node

return road_network