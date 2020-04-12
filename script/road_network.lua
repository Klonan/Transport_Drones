local script_data =
{
  networks = {},
  id_number = 0,
  node_map = {}
}

local print = function(string)
  log(string)
  game.print(string)
end

local new_id = function()
  script_data.id_number = script_data.id_number + 1
  local id = script_data.id_number
  script_data.networks[id] =
  {
    id = id
  }
  --print("New network "..id)
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


local accumulate_nodes = function(surface, x, y)

  local nodes = {}
  local new_nodes = {}

  local root_node = get_node(surface, x, y)
  nodes[root_node] = true
  new_nodes[root_node] = {x, y}

  local neighbor_offsets = neighbor_offsets
  local get_node = get_node
  local next = next
  local pairs = pairs
  
  while true do
    local node, node_position = next(new_nodes)
    if not node then break end
    new_nodes[node] = nil
    for k, offset in pairs (neighbor_offsets) do
      local nx, ny = node_position[1] + offset[1], node_position[2] + offset[2]
      local neighbor = get_node(surface, nx, ny)
      if neighbor then
        if not nodes[neighbor] then
          nodes[neighbor] = true
          new_nodes[neighbor] = {nx, ny}
        end
      end
    end
  end

  return nodes

end

local symmetric_connection_check = function(surface, x1, y1, x2, y2)
  --Because most often, 1 road network is significantly smaller, so this will reduce search time.

  local nodes_1 = {}
  local new_nodes_1 = {}
  
  local root_node_1 = get_node(surface, x1, y1)
  nodes_1[root_node_1] = true
  new_nodes_1[root_node_1] = {x1, y1}
  
  local nodes_2 = {}
  local new_nodes_2 = {}
  
  local root_node_2 = get_node(surface, x2, y2)
  nodes_2[root_node_2] = true
  new_nodes_2[root_node_2] = {x2, y2}
  

  local neighbor_offsets = neighbor_offsets
  local get_node = get_node
  local next = next
  local pairs = pairs

  while true do

    local node, node_position = next(new_nodes_1)
    if not node then break end
    --game.surfaces[surface].create_entity{name = "flying-text", position = {node_position[1], node_position[2]}, text = "A"}
    new_nodes_1[node] = nil
    for k, offset in pairs (neighbor_offsets) do
      local nx, ny = node_position[1] + offset[1], node_position[2] + offset[2]
      local neighbor = get_node(surface, nx, ny)
      if neighbor then

        if nodes_2[neighbor] then return true end

        if not nodes_1[neighbor] then
          nodes_1[neighbor] = true
          new_nodes_1[neighbor] = {nx, ny}
        end
      end
    end
    
    local node, node_position = next(new_nodes_2)
    if not node then break end
    --game.surfaces[surface].create_entity{name = "flying-text", position = {node_position[1], node_position[2]}, text = "B"}
    new_nodes_2[node] = nil
    for k, offset in pairs (neighbor_offsets) do
      local nx, ny = node_position[1] + offset[1], node_position[2] + offset[2]
      local neighbor = get_node(surface, nx, ny)
      if neighbor then

        if nodes_1[neighbor] then return true end

        if not nodes_2[neighbor] then
          nodes_2[neighbor] = true
          new_nodes_2[neighbor] = {nx, ny}
        end
      end
    end

  end

  return false 
  
end

local accumulate_smaller_node = function(surface, x1, y1, x2, y2)

  --returns the smaller of the 2 node groups.
  
  local nodes_1 = {}
  local new_nodes_1 = {}
  
  local root_node_1 = get_node(surface, x1, y1)
  nodes_1[root_node_1] = true
  new_nodes_1[root_node_1] = {x1, y1}
  
  local nodes_2 = {}
  local new_nodes_2 = {}
  
  local root_node_2 = get_node(surface, x2, y2)
  nodes_2[root_node_2] = true
  new_nodes_2[root_node_2] = {x2, y2}
  

  local neighbor_offsets = neighbor_offsets
  local get_node = get_node
  local next = next
  local pairs = pairs

  while true do

    local node, node_position = next(new_nodes_1)
    if not node then return nodes_1 end
    --game.surfaces[surface].create_entity{name = "flying-text", position = {node_position[1], node_position[2]}, text = "A"}
    new_nodes_1[node] = nil
    for k, offset in pairs (neighbor_offsets) do
      local nx, ny = node_position[1] + offset[1], node_position[2] + offset[2]
      local neighbor = get_node(surface, nx, ny)
      if neighbor then
        if not nodes_1[neighbor] then
          nodes_1[neighbor] = true
          new_nodes_1[neighbor] = {nx, ny}
        end
      end
    end
    
    local node, node_position = next(new_nodes_2)
    if not node then return nodes_2 end
    --game.surfaces[surface].create_entity{name = "flying-text", position = {node_position[1], node_position[2]}, text = "B"}
    new_nodes_2[node] = nil
    for k, offset in pairs (neighbor_offsets) do
      local nx, ny = node_position[1] + offset[1], node_position[2] + offset[2]
      local neighbor = get_node(surface, nx, ny)
      if neighbor then
        if not nodes_2[neighbor] then
          nodes_2[neighbor] = true
          new_nodes_2[neighbor] = {nx, ny}
        end
      end
    end

  end

end

local debug_get_node_postion = function(node)
  for surface, v in pairs (script_data.node_map) do
    for x, y in pairs (v) do
      for y, j in pairs (y) do
        if j == node then
          return {surface = surface, x = x, y = y}
        end
      end
    end
  end
  return {1, 1, 1}
end

local set_node_ids = function(nodes, id)

  --print("Setting nodes "..id)

  for node, bool in pairs (nodes) do
    node.id = id
    --local node_position = debug_get_node_postion(node)
    --game.surfaces[node_position.surface].create_entity{name = "flying-text", position = {node_position.x, node_position.y}, text = id}

    if node.depots then
      for k, depot in pairs (node.depots) do
        depot:remove_from_network()
        depot:add_to_network()
      end
    end
  end

end



local clear_network = function(id)
  --print("Clearing "..id)
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

  local node = get_node(surface, x, y)
  if node then
    --Eh... maybe I should error?
    return
  end

  local new_node_id
  local checked = {}
  for k, offset in pairs(neighbor_offsets) do

    checked[k] = true
    
    local fx, fy = x + offset[1], y + offset[2]
    local neighbor = get_node(surface, fx, fy)
    
    if neighbor then

      if not new_node_id then new_node_id = neighbor.id end

      for j, offset in pairs(neighbor_offsets) do
        if not checked[j] then

          local nx, ny = x + offset[1], y + offset[2]
          local other_neighbor = get_node(surface, nx, ny)

          if other_neighbor then
            if neighbor.id ~= other_neighbor.id then
              local smaller_node_set = accumulate_smaller_node(surface, fx, fy, nx, ny)
              local smaller_id = next(smaller_node_set).id
              local larger_id = smaller_id == neighbor.id and other_neighbor.id or neighbor.id
              set_node_ids(smaller_node_set, larger_id) 
              new_node_id = larger_id
            end
          end

        end
      end
    end
  end  

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
  
  if not new_node_id then
    new_node_id = new_id()
  end
  
  x_map[y] = 
  {
    id = new_node_id
  }

end

road_network.remove_node = function(surface, x, y)

  
  local node = get_node(surface, x, y)
  if not node then return end
  
  --print("Removing node "..serpent.line({node.id, x, y}))

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
  -- Check every neighbor against every other neighbor
  local checked = {}
  for k, offset in pairs(neighbor_offsets) do

    checked[k] = true
    
    local fx, fy = x + offset[1], y + offset[2]
    local neighbor = get_node(surface, fx, fy)
    
    if neighbor then
      for j, offset in pairs(neighbor_offsets) do
        if not checked[j] then
          local nx, ny = x + offset[1], y + offset[2]
          local other_neighbor = get_node(surface, nx, ny)
          if other_neighbor then
            if not symmetric_connection_check(surface, fx, fy, nx, ny) then
              local smaller_node_set = accumulate_smaller_node(surface, fx, fy, nx, ny)
              set_node_ids(smaller_node_set, new_id()) 
            end
          end
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
local distance = function(a, b)
  local dx = a[1] - b[1]
  local dy = a[2] - b[2]
  return ((dx * dx) + (dy * dy)) ^ 0.5
end
local rect_distance = function(a, b)
  local dx = a[1] - b[1]
  local dy = a[2] - b[2]
  return dx + dy
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
    return distance(depot_a.node_position, node_position) < distance(depot_b.node_position, node_position)
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

road_network.get_buffer_depots_raw = function(id, name)
  local network = get_network_by_id(id)
  if not network.buffers then return end
  local depots = network.buffers[name]
  return depots
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