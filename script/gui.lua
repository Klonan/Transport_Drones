local road_network = require("script/road_network")

local network_size = function(network)
  
  --This is a meh way to do it.

  local sum = 0
  
  for category, depots in pairs (network.depots) do
    sum = sum + table_size(depots)
  end

  return sum
end

local add_contents_tab = function(tabbed_pane, network)
  local contents_tab = tabbed_pane.add{type = "tab", caption = "Contents"}
  local contents = tabbed_pane.add{type = "scroll-pane"}
  contents.style.maximal_width = 1900
  --contents.style.width = 1900
  --contents.style.horizontally_stretchable = true
  --contents.style.horizontally_squashable = false
  local contents_table = contents.add{type = "table", column_count = 4, style = "bordered_table"}
  contents_table.style.column_alignments[1] = "center"
  contents_table.style.column_alignments[2] = "center"
  contents_table.style.column_alignments[3] = "center"
  contents_table.style.column_alignments[4] = "center"
  --contents_table.style.horizontally_stretchable = false
  --contents_table.style.horizontally_squashable = false
  local items = game.item_prototypes
  local fluids = game.fluid_prototypes
  for name, counts in pairs (network.item_supply) do
    local icon, locale
    if items[name] then
      icon = "item/"..name 
      locale = items[name].localised_name
    elseif fluids[name] then
      icon = "fluid/"..name
      locale = fluids[name].localised_name
    else
      --Some old shit?
    end
    if icon then
      local sum = 0
      for depot_id, count in pairs (counts) do
        sum = sum + count
      end
      if sum > 0 then
        local flow = contents_table.add{type = "flow"}
        flow.add{type = "sprite-button", sprite = icon, number = sum, style = "slot_button"}
        local label = flow.add{type = "label", caption = locale}
        --label.style.width = 128
        flow.style.vertical_align = "center"
        flow.style.horizontally_stretchable = true
      end
    end
  end
  tabbed_pane.add_tab(contents_tab, contents)
end

local add_contents = function(gui, contents)
  local items = game.item_prototypes
  local fluids = game.fluid_prototypes

  for name, count in pairs (contents) do
    if items[name] then
      icon = "item/"..name 
      locale = items[name].localised_name
    elseif fluids[name] then
      icon = "fluid/"..name
      locale = fluids[name].localised_name
    else
      --Some old shit?
    end
    if icon then
      --local flow = gui.add{type = "flow"}
      gui.add{type = "sprite-button", sprite = icon, number = count, style = "slot_button"}
      --flow.add{type = "sprite-button", sprite = icon, number = count, style = "slot_button"}
      --local label = flow.add{type = "label", caption = locale}
      --label.style.width = 128
      --flow.style.vertical_align = "center"
      
    end
  end
  
end

local map_size = 70
local add_supply_tab = function(tabbed_pane, network)
  local supply_tab = tabbed_pane.add{type = "tab", caption = "Supply depots"}
  local contents = tabbed_pane.add{type = "scroll-pane"}
  local depot_table = contents.add{type = "table", column_count = 2, style = "bordered_table"}
  depot_table.style.horizontally_stretchable = true

  for index, depot in pairs (network.depots.supply) do
    --local depot_frame = depot_table.add{type = "frame", style = "bordered_frame"}
    local depot_frame = depot_table.add{type = "flow"}
    depot_frame.style.horizontally_stretchable = true
    local button = depot_frame.add{type = "button"}
    button.style.width = map_size + 8
    button.style.height = map_size + 8
    button.style.horizontal_align = "center"
    button.style.vertical_align = "center"
    button.style.padding = {0,0,0,0}
    local entity = depot.entity
    local map = button.add
    {
      type = "minimap",
      position = entity.position,
      surface_index = entity.surface.index,
      force = entity.force.name,
      zoom = 1,
      ignored_by_interaction = true
    }
    map.style.width = map_size
    map.style.height = map_size
    local contents = depot.old_contents
    if next(contents) then
      local table = depot_frame.add{type = "table", column_count = 6}
      table.style.horizontally_stretchable = true
      add_contents(table, contents)
    else
      --depot_frame.add{type = "label", caption = "No contents"}
    end
    local pusher = depot_frame.add{type = "empty-widget"}
    pusher.style.horizontally_stretchable = true
  end


  tabbed_pane.add_tab(supply_tab, contents)
end

local map_size = 70
local add_fluid_tab = function(tabbed_pane, network)
  local fluid_tab = tabbed_pane.add{type = "tab", caption = "Fluid depots"}
  local contents = tabbed_pane.add{type = "scroll-pane"}
  local depot_table = contents.add{type = "table", column_count = 2, style = "bordered_table"}
  depot_table.style.horizontally_stretchable = true

  for index, depot in pairs (network.depots.fluid) do
    --local depot_frame = depot_table.add{type = "frame", style = "bordered_frame"}
    local depot_frame = depot_table.add{type = "flow"}
    depot_frame.style.horizontally_stretchable = true
    local button = depot_frame.add{type = "button"}
    button.style.width = map_size + 8
    button.style.height = map_size + 8
    button.style.horizontal_align = "center"
    button.style.vertical_align = "center"
    button.style.padding = {0,0,0,0}
    local entity = depot.entity
    local map = button.add
    {
      type = "minimap",
      position = entity.position,
      surface_index = entity.surface.index,
      force = entity.force.name,
      zoom = 1,
      ignored_by_interaction = true
    }
    map.style.width = map_size
    map.style.height = map_size
    local contents = depot.old_contents
    if next(contents) then
      local table = depot_frame.add{type = "table", column_count = 6}
      table.style.horizontally_stretchable = true
      add_contents(table, contents)
    else
      --depot_frame.add{type = "label", caption = "No contents"}
    end
    local pusher = depot_frame.add{type = "empty-widget"}
    pusher.style.horizontally_stretchable = true
  end


  tabbed_pane.add_tab(fluid_tab, contents)
end

local map_size = 70
local add_mining_tab = function(tabbed_pane, network)
  local mining_tab = tabbed_pane.add{type = "tab", caption = "Mining depots"}
  local contents = tabbed_pane.add{type = "scroll-pane"}
  local depot_table = contents.add{type = "table", column_count = 2, style = "bordered_table"}
  depot_table.style.horizontally_stretchable = true



  for index, depot in pairs (network.depots.mining) do
    --local depot_frame = depot_table.add{type = "frame", style = "bordered_frame"}
    local depot_frame = depot_table.add{type = "flow"}
    depot_frame.style.horizontally_stretchable = true
    local button = depot_frame.add{type = "button"}
    button.style.width = map_size + 8
    button.style.height = map_size + 8
    button.style.horizontal_align = "center"
    button.style.vertical_align = "center"
    button.style.padding = {0,0,0,0}
    local entity = depot.entity
    local map = button.add
    {
      type = "minimap",
      position = entity.position,
      surface_index = entity.surface.index,
      force = entity.force.name,
      zoom = 1,
      ignored_by_interaction = true
    }
    map.style.width = map_size
    map.style.height = map_size
    local contents = depot.old_contents
    if next(contents) then
      local table = depot_frame.add{type = "table", column_count = 6}
      table.style.horizontally_stretchable = true
      add_contents(table, contents)
    else
      depot_frame.add{type = "label", caption = "No contents"}
    end
    local pusher = depot_frame.add{type = "empty-widget"}
    pusher.style.horizontally_stretchable = true
  end


  tabbed_pane.add_tab(mining_tab, contents)
end

local map_size = 70
local add_requester_tab = function(tabbed_pane, network)
  local requester_tab = tabbed_pane.add{type = "tab", caption = "Request depots"}
  local contents = tabbed_pane.add{type = "scroll-pane"}
  local depot_table = contents.add{type = "table", column_count = 2, style = "bordered_table"}
  depot_table.style.horizontally_stretchable = true



  for index, depot in pairs (network.depots.request) do
    --local depot_frame = depot_table.add{type = "frame", style = "bordered_frame"}
    local depot_frame = depot_table.add{type = "flow"}
    depot_frame.style.horizontally_stretchable = true
    local button = depot_frame.add{type = "button"}
    button.style.width = map_size + 8
    button.style.height = map_size + 8
    button.style.horizontal_align = "center"
    button.style.vertical_align = "center"
    button.style.padding = {0,0,0,0}
    local entity = depot.entity
    local map = button.add
    {
      type = "minimap",
      position = entity.position,
      surface_index = entity.surface.index,
      force = entity.force.name,
      zoom = 1,
      ignored_by_interaction = true
    }
    map.style.width = map_size
    map.style.height = map_size
    local contents = depot.old_contents
    if next(contents) then
      local table = depot_frame.add{type = "table", column_count = 6}
      table.style.horizontally_stretchable = true
      add_contents(table, contents)
    else
      depot_frame.add{type = "label", caption = "No contents"}
    end
    local pusher = depot_frame.add{type = "empty-widget"}
    pusher.style.horizontally_stretchable = true
  end


  tabbed_pane.add_tab(mining_tab, contents)
end

local fuel_map_size = 90
local add_fuel_tab = function(tabbed_pane, network)
  local add_fuel_tab = tabbed_pane.add{type = "tab", caption = "Fuel depots"}
  local contents = tabbed_pane.add{type = "scroll-pane"}
  local depot_table = contents.add{type = "table", column_count = 2, style = "bordered_table"}
  depot_table.style.horizontally_stretchable = true



  for index, depot in pairs (network.depots.fuel) do
    --local depot_frame = depot_table.add{type = "frame", style = "bordered_frame"}
    local depot_frame = depot_table.add{type = "flow"}
    depot_frame.style.horizontally_stretchable = true
    local button = depot_frame.add{type = "button"}
    button.style.width = fuel_map_size + 8
    button.style.height = fuel_map_size + 8
    button.style.horizontal_align = "center"
    button.style.vertical_align = "center"
    button.style.padding = {0,0,0,0}
    local entity = depot.entity
    local map = button.add
    {
      type = "minimap",
      position = entity.position,
      surface_index = entity.surface.index,
      force = entity.force.name,
      zoom = 1,
      ignored_by_interaction = true
    }
    map.style.width = fuel_map_size
    map.style.height = fuel_map_size
    local flow = depot_frame.add{type = "table", column_count = 1, style = "bordered_table"}
    local label = flow.add{type = "label", caption = "Active Drones: "..depot:get_active_drone_count()}
    label.style.horizontally_stretchable = true
    flow.add{type = "label", caption = "Available Drones: "..depot:get_drone_item_count()}
    flow.add{type = "label", caption = "Available Fuel: "..math.floor(depot:get_fuel_amount())}
    flow.style.horizontally_stretchable = true
  end


  tabbed_pane.add_tab(add_fuel_tab, contents)
end

local make_network_gui = function(inner, network)
  local tabbed_pane = inner.add{type = "tabbed-pane"}
  add_contents_tab(tabbed_pane, network)
  add_supply_tab(tabbed_pane, network)
  add_fluid_tab(tabbed_pane, network)
  add_mining_tab(tabbed_pane, network)
  add_fuel_tab(tabbed_pane, network)
  

  
end

local refresh_network_gui = function(player, selected_index)
  local gui = player.gui.screen

  local frame = gui.road_network_frame
  if not frame then return end

  local networks = road_network.get_networks()

  local index, network
  for k = 1, selected_index do
    index, network = next(networks, index)
  end

  if not network then return end

  local inner = frame.add{type = "frame", style = "inside_deep_frame_for_tabs"}

  make_network_gui(inner, network)

end

local open_gui = function(player)
  local gui = player.gui.screen

  local frame = gui.add{type = "frame", direction = "vertical", name = "road_network_frame"}
  frame.style.maximal_height = 1000

  local title_flow = frame.add{type = "flow"}

  local title = title_flow.add{type = "label", caption = "Road networks", style = "frame_title"}
  title.drag_target = frame

  local pusher = title_flow.add{type = "empty-widget", style = "draggable_space_header"}
  pusher.style.vertically_stretchable = true
  pusher.style.horizontally_stretchable = true
  pusher.drag_target = frame

  local drop_down = title_flow.add{type = "drop-down", name = "road_network_drop_down"}
  
  local networks = road_network.get_networks()
  
  local selected
  local big = 0
  local count = 0
  for k, network in pairs (networks) do
    count = count + 1
    if not selected then selected = count end
    local size = network_size(network)
    drop_down.add_item("Network #"..count.." - "..size.." depots")
    if size > big then
      big = size
      selected = count
    end
  end

  if count == 0 then return end
  drop_down.selected_index = selected

  refresh_network_gui(player, selected)

  frame.auto_center = true

end



commands.add_command("toggle-transport-depot-gui", "idk",
function(command)
  local player = game.player
  if not player then return end
  open_gui(player)
end)

local lib = {}

lib.events =
{
  [defines.events.on_gui_click] = on_gui_click
}

return lib
