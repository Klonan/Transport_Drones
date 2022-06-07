local shared = require("shared")

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
    item_supply = {},
    depots = {}
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

  {-1, -1},
  {1, -1},
  {1, 1},
  {-1, 1},

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
    --local node_position = debug_get_node_postion(node)
    --game.surfaces[node_position.surface].create_entity{name = "flying-text", position = {node_position.x, node_position.y}, text = id}

    node.id = id

    if node.depots then
      for k, depot in pairs (node.depots) do
        depot:remove_from_network()
        if depot.entity.valid then
          depot:add_to_network()
        end
      end
    end
  end

end



local clear_network = function(id)
  --print("Clearing "..id)
  local network = script_data.networks[id]

  --if not network then return end

  for category, depots in pairs (network.depots) do
    for id, depot in pairs (depots) do
      depot:remove_from_network()
      depot:add_to_network()
    end
  end

  script_data.networks[id] = nil
end


local road_network = {}

road_network.get_network_item_supply = function(id)
  local network = get_network_by_id(id)
  return network.item_supply
end

road_network.get_supply_depots = function(id, name)
  local network = get_network_by_id(id)
  return network.item_supply[name]
end

road_network.add_node = function(surface, x, y)

  local node = get_node(surface, x, y)
  if node then
    --Eh... maybe I should error?
    return
  end

  local new_node_id
  local rx, ry
  local checked = {}

  for k, offset in pairs (neighbor_offsets) do
    local fx, fy = x + offset[1], y + offset[2]
    local neighbor = get_node(surface, fx, fy)
    if neighbor then
      if not new_node_id then
        new_node_id = neighbor.id
        rx, ry = fx, fy
      elseif neighbor.id ~= new_node_id then
        local smaller_node_set = accumulate_smaller_node(surface, rx, ry, fx, fy)
        local smaller_id = next(smaller_node_set).id
        if smaller_id == new_node_id then
          new_node_id = neighbor.id
          rx, ry = fx, fy
        end
      end
    end
  end

  for k, offset in pairs (neighbor_offsets) do
    local fx, fy = x + offset[1], y + offset[2]
    local neighbor = get_node(surface, fx, fy)
    if neighbor then
      local neighbor_id = neighbor.id
      if neighbor_id ~= new_node_id then
        local nodes = accumulate_nodes(surface, fx, fy)
        set_node_ids(nodes, new_node_id)
        clear_network(neighbor_id)
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

  local node_id = node.id

  local checked = {}
  for k, offset in pairs(neighbor_offsets) do

    checked[k] = true

    local fx, fy = x + offset[1], y + offset[2]
    local neighbor = get_node(surface, fx, fy)

    if neighbor then
      if neighbor.id == node_id then
        for j, offset in pairs(neighbor_offsets) do
          if not checked[j] then
            local nx, ny = x + offset[1], y + offset[2]
            local other_neighbor = get_node(surface, nx, ny)
            if other_neighbor and other_neighbor.id == neighbor.id then
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

end

road_network.get_network = function(surface, x, y)
  local node = get_node(surface, x, y)
  if not node then return end

  return get_network_by_id(node.id)
end

road_network.add_depot = function(depot, category)
  local x, y = depot.node_position[1], depot.node_position[2]
  local surface = depot.entity.surface.index
  local node = get_node(surface, x, y)

  local network = get_network_by_id(node.id)

  if not network.depots[category] then network.depots[category] = {} end
  network.depots[category][depot.index] = depot

  return node.id
end

road_network.remove_depot = function(depot, category)
  --local x, y = depot.node_position[1], depot.node_position[2]
  --local surface = depot.entity.surface.index
  --local node = get_node(surface, x, y)
  --local network = get_network_by_id(node.id)

  local network_id = depot.network_id
  if not network_id then return end

  local network = get_network_by_id(network_id)
  if not network then return end

  if depot.old_contents then
    local item_supply = network.item_supply
    for name, count in pairs (depot.old_contents) do
      if item_supply[name] then
        item_supply[name][depot.index] = nil
      end
    end
  end

  if network.depots[category] then
    network.depots[category][depot.index] = nil
  end

end

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

local prune_networks = function()
  local valid = {}
  for index, surface_map in pairs(script_data.node_map) do
    for x, y_map in pairs (surface_map) do
      for y, id in pairs (y_map) do
        if not valid[id] then
          valid[id] = true
        end
      end
    end
  end

  for id, network in pairs (script_data.networks) do
    if not valid[id] then
      clear_network(id)
    end
  end

end

local floor = math.floor

local get_tiles = function()
  local mask = game.tile_prototypes["transport-drone-road"].collision_mask
  local tiles = {}
  for name, tile in pairs (game.tile_prototypes) do
    local tile_mask = tile.collision_mask or {}
    if table_size(tile_mask) == table_size(mask) then
      local good = true
      for layer, bool in pairs (mask) do
        if not tile_mask[layer] then
          good = false
          break
        end
      end
      if good then
        table.insert(tiles, name)
      end
    end
  end
  return tiles
end

local reset = function()

  local profiler = game.create_profiler()

  script_data.node_map = {}
  script_data.networks = {}
  script_data.id_number = 0

  local add_node = road_network.add_node


  local tile_names = get_tiles()
  if not next(tile_names) then
    error("NO ROAD TILES? Something if fishy! Aborting loading to prevent save corruption.")
  end

  for surface_index, surface in pairs (game.surfaces) do
    local index = surface.index
    local tiles = surface.find_tiles_filtered{name = tile_names}
    for k, tile in pairs (tiles) do
      local tile_position = tile.position
      add_node(index, tile_position.x, tile_position.y)
    end
  end

  game.print({"", "Reset road network - ", profiler})

end


road_network.get_depots_by_distance = function(id, category, node_position)
  local sort_function = function(depot_a, depot_b)
    return distance_squared(depot_a.node_position, node_position) < distance_squared(depot_b.node_position, node_position)
  end
  local network = get_network_by_id(id)
  local depots = network.depots[category]
  if not depots then return end

  local to_sort = {}
  local i = 1
  for k, v in pairs (depots) do
    to_sort[i] = v
    i = i + 1
  end

  sort(to_sort, sort_function)
  return to_sort
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

  local hidden = surface.get_hidden_tile(position)
  if hidden then
    surface.set_tiles
    {
      {
        name = hidden,
        position = position
      }
    }
  end

end

road_network.on_init = function()
  global.road_network = global.road_network or script_data
end

road_network.on_load = function()
  script_data = global.road_network or script_data
end

road_network.on_configuration_changed = function()

  reset()

end

road_network.get_network_by_id = get_network_by_id
road_network.get_node = get_node
road_network.get_networks = function()
  return script_data.networks
end

return road_network