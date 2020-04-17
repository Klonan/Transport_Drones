local road_network = require("script/road_network")
local depot_common = require("script/depot_common")

local network_size = function(network)
  
  --This is a meh way to do it.

  local sum = 0
  
  for category, depots in pairs (network.depots) do
    sum = sum + table_size(depots)
  end

  return sum
end

local get_network_by_dropdown_index = function(selected_index)

  local networks = road_network.get_networks()

  local index, network
  for k = 1, selected_index do
    index, network = next(networks, index)
  end

  return network
end

local get_frame = function(player)
  local gui = player.gui.screen
  return gui.road_network_frame
end

local get_selected_network = function(player)
  local frame = get_frame(player)
  if not frame then return end
  local index = frame.title_flow.road_network_drop_down.selected_index
  return get_network_by_dropdown_index(index)
end

local get_tab_pane = function(player)
  local frame = get_frame(player)
  if not frame then return end
  return frame.inner_frame.tab_pane
end

local get_tab = function(player, tab_name)
  local pane = get_tab_pane(player)
  if not pane then return end
  return pane[tab_name]
end

local get_selected_tab_index = function(player)
  local tab_pane = get_tab_pane(player)
  if tab_pane then return tab_pane.selected_tab_index end
end

local get_filter_value = function(player)
  local frame = get_frame(player)
  if not frame then return end
  --game.print(serpent.line(frame.inner_frame.subheader_frame.depot_filter_button.elem_value))
  return frame.inner_frame.subheader_frame.depot_filter_button.elem_value
end

local set_filter_value = function(player, value)
  local frame = get_frame(player)
  if not frame then return end

  frame.inner_frame.subheader_frame.depot_filter_button.elem_value = value

end

local cache = {}
local get_item_icon_and_locale = function(name)
  if cache[name] then
    return cache[name]
  end

  local items = game.item_prototypes
  if items[name] then
    icon = "item/"..name 
    locale = items[name].localised_name
    local value = {icon = icon, locale = locale}
    cache[name] = value
    return value
  end

  local fluids = game.fluid_prototypes
  if fluids[name] then
    icon = "fluid/"..name
    locale = fluids[name].localised_name
    local value = {icon = icon, locale = locale}
    cache[name] = value
    return value
  end

end

local signal_cache = {}
local get_signal_id = function(name)
  if signal_cache[name] then
    return signal_cache[name]
  end

  local items = game.item_prototypes
  if items[name] then
    local value = {type = "item", name = name}
    signal_cache[name] = value
    return value
  end

  local fluids = game.fluid_prototypes
  if fluids[name] then
    local value = {type = "fluid", name = name}
    signal_cache[name] = value
    return value
  end

end

local floor = math.floor
local update_contents_table = function(contents_table, network, filter)

  for name, counts in pairs (network.item_supply) do
    local item_locale = get_item_icon_and_locale(name)

    if item_locale then
      local visible = (not filter or filter.name == name)
      local flow = contents_table[name]
      if visible then
        local sum = 0
        for depot_id, count in pairs (counts) do
          sum = sum + count
        end

        sum = floor(sum)

        
        if not flow then
          flow = contents_table.add{type = "flow", name = name}
          flow.add
          {
            type = "sprite-button",
            sprite = item_locale.icon,
            number = sum,
            style = "slot_button",
            name = "count",
            tooltip = sum
          }
          flow.style.vertical_align = "center"
          flow.style.horizontally_stretchable = true
          local label = flow.add{type = "label", caption = item_locale.locale}
        else
          flow.count.number = sum
          flow.count.tooltip = sum
        end
      end
      if flow then flow.visible = visible end
    end
  end
  for k, gui in pairs (contents_table.children) do
    if not network.item_supply[gui.name] then gui.destroy() end
  end
end

local refresh_contents_tab = function(player)
  if get_selected_tab_index(player) ~= 1 then return end
  local contents_tab = get_tab(player, "contents_tab")
  if not contents_tab then return end
  local network = get_selected_network(player)
  update_contents_table(contents_tab.contents_table, network, get_filter_value(player))
end

local add_contents_tab = function(tabbed_pane, network)
  local contents_tab = tabbed_pane.add{type = "tab", caption = {"contents"}}
  local contents = tabbed_pane.add{type = "scroll-pane",  name = "contents_tab"}
  contents.style.maximal_width = 1900

  local contents_table = contents.add{type = "table", column_count = 4, style = "bordered_table", name = "contents_table"}
  contents_table.style.column_alignments[1] = "center"
  contents_table.style.column_alignments[2] = "center"
  contents_table.style.column_alignments[3] = "center"
  contents_table.style.column_alignments[4] = "center"

  update_contents_table(contents_table, network)

  tabbed_pane.add_tab(contents_tab, contents)
end

local update_contents = function(gui, contents)

  for name, count in pairs (contents) do
    local item_locale = get_item_icon_and_locale(name)
    if item_locale then
      local button = gui[name]
      if not button then
        button = gui.add
        {
          type = "sprite-button",
          sprite = item_locale.icon,
          number = count,
          style = "slot_button",
          name = name,
          tooltip = count
        }
      else
        button.number = count
        button.tooltip = count
      end      
    end
  end

  for k, element in pairs (gui.children) do
    if not contents[element.name] then
      element.destroy()
    end
  end
  
end


local add_depot_map_button = function(depot, gui, size)
  local button = gui.add{type = "button", name = "open_depot_map_"..depot.index}
  button.style.minimal_width = size + 8
  button.style.minimal_height = size + 8
  button.style.horizontal_align = "center"
  button.style.vertical_align = "center"
  button.style.padding = {0,0,0,0}
  --button.style.horizontally_stretchable = true
  local entity = depot.entity
  local map = button.add
  {
    type = "minimap",
    position = entity.position,
    surface_index = entity.surface.index,
    force = entity.force.name,
    zoom = 2,
    ignored_by_interaction = true
  }
  map.style.minimal_width = size
  map.style.minimal_height = size
  --map.style.horizontally_stretchable = true
  --local sprite_size = 32
  --local sprite = map.add{type = "sprite", sprite = "entity/"..depot.entity.name}
  --local padding = (size / 2) - (sprite_size / 2)
  --sprite.style.padding = {padding, padding, padding, padding}
  --sprite.style.width = sprite_size
  --sprite.style.height = sprite_size
  
end


local update_supply_depot_gui = function(depot, gui, filter)

  local holding_table = gui.table
  if not holding_table then
    holding_table = gui.add{type = "table", column_count = 5, name = "table"}
  end
  local visible = (not filter) or depot.old_contents[filter.name]
  if visible then
    update_contents(holding_table, depot.old_contents)
  end
  gui.visible = visible
end

local map_size = 64 * 3
local update_supply_tab = function(depots, gui, filter)

  for index, depot in pairs (depots) do
    --local depot_frame = depot_table.add{type = "frame", style = "bordered_frame"}
    local depot_frame = gui[index]
    if not depot_frame then
      depot_frame = gui.add{type = "flow", name = index, direction = "vertical"}
      depot_frame.style.horizontally_stretchable = true
      --depot_frame.style.vertically_stretchable = true
      depot_frame.style.vertical_align = "top"
      add_depot_map_button(depot, depot_frame, map_size)
    end
    update_supply_depot_gui(depot, depot_frame, filter)
  end

  for k, gui in pairs (gui.children) do
    if not depots[gui.name] then
      gui.destroy()
    end
  end

end

local refresh_supply_tab = function(player)
  if get_selected_tab_index(player) ~= 2 then return end
  local contents_tab = get_tab(player, "supply_tab")
  if not contents_tab then return end
  local network = get_selected_network(player)
  update_supply_tab(network.depots.supply, contents_tab.depot_table, get_filter_value(player))
end

local refresh_fluid_tab = function(player)
  if get_selected_tab_index(player) ~= 3 then return end
  local contents_tab = get_tab(player, "fluid_tab")
  if not contents_tab then return end
  local network = get_selected_network(player)
  update_supply_tab(network.depots.fluid, contents_tab.depot_table, get_filter_value(player))
end

local refresh_mining_tab = function(player)
  if get_selected_tab_index(player) ~= 4 then return end
  local contents_tab = get_tab(player, "mining_tab")
  if not contents_tab then return end
  local network = get_selected_network(player)
  update_supply_tab(network.depots.mining, contents_tab.depot_table, get_filter_value(player))
end

local add_supply_tab = function(tabbed_pane, network)
  local supply_tab = tabbed_pane.add{type = "tab", caption = {"supply-depots"}}
  local contents = tabbed_pane.add{type = "scroll-pane", name = "supply_tab"}
  
  local depots = network.depots.supply
  
  if not depots then
    supply_tab.enabled = false
    tabbed_pane.add_tab(supply_tab, contents)
    return
  end

  local depot_table = contents.add{type = "table", column_count = 4, style = "bordered_table", name = "depot_table"}
  depot_table.style.horizontally_stretchable = true

  update_supply_tab(depots, depot_table)

  tabbed_pane.add_tab(supply_tab, contents)
end

local add_fluid_tab = function(tabbed_pane, network)
  local fluid_tab = tabbed_pane.add{type = "tab", caption = {"fluid-depots"}}
  local contents = tabbed_pane.add{type = "scroll-pane", name = "fluid_tab"}

  local depots = network.depots.fluid

  if not depots then
    fluid_tab.enabled = false
    tabbed_pane.add_tab(fluid_tab, contents)
    return
  end

  local depot_table = contents.add{type = "table", column_count = 4, style = "bordered_table", name = "depot_table"}
  depot_table.style.horizontally_stretchable = true

  update_supply_tab(depots, depot_table)

  tabbed_pane.add_tab(fluid_tab, contents)
end

local add_mining_tab = function(tabbed_pane, network)
  local mining_tab = tabbed_pane.add{type = "tab", caption = {"mining-depots"}}
  local contents = tabbed_pane.add{type = "scroll-pane", name = "mining_tab"}
  
  local depots = network.depots.mining

  if not depots then
    mining_tab.enabled = false
    tabbed_pane.add_tab(mining_tab, contents)
    return
  end

  local depot_table = contents.add{type = "table", column_count = 4, style = "bordered_table", name = "depot_table"}
  depot_table.style.horizontally_stretchable = true

  update_supply_tab(depots, depot_table)

  tabbed_pane.add_tab(mining_tab, contents)
end

local update_fuel_depot_gui = function(depot, gui)

  --local depot_frame = depot_table.add{type = "frame", style = "bordered_frame"}
  local flow = gui.table

  if not flow then
    flow = gui.add{type = "table", column_count = 1, style = "bordered_table", name = "table"}
    flow.style.horizontally_stretchable = true
  else
    flow.clear()
  end

  local label = flow.add{type = "label", caption = {"active-drones", depot:get_active_drone_count()}}
  label.style.horizontally_stretchable = true
  flow.add{type = "label", caption = {"available-drones", depot:get_drone_item_count()}}
  flow.add{type = "label", caption = {"available-fuel", math.floor(depot:get_fuel_amount())}}

end

  
local fuel_map_size = 64 * 3
local update_fuel_tab = function(depots, gui)
  
  for index, depot in pairs (depots) do
    local depot_frame = gui[index]
    if not depot_frame then
      depot_frame = gui.add{type = "flow", name = index}
      depot_frame.style.horizontally_stretchable = true
      add_depot_map_button(depot, depot_frame, fuel_map_size)
    end
    update_fuel_depot_gui(depot, depot_frame)
  end
    
  for k, gui in pairs (gui.children) do
    if not depots[gui.name] then
      gui.destroy()
    end
  end
end

local refresh_fuel_tab = function(player)
  if get_selected_tab_index(player) ~= 5 then return end
  local contents_tab = get_tab(player, "fuel_tab")
  if not contents_tab then return end
  local network = get_selected_network(player)
  update_fuel_tab(network.depots.fuel, contents_tab.depot_table)
end

local add_fuel_tab = function(tabbed_pane, network)
  local fuel_tab = tabbed_pane.add{type = "tab", caption = {"fuel-depots-tab"}}
  local contents = tabbed_pane.add{type = "scroll-pane", name = "fuel_tab"}
  
  local depots = network.depots.fuel
  
  if not depots then
    fuel_tab.enabled = false
    tabbed_pane.add_tab(fuel_tab, contents)
    return
  end

  local depot_table = contents.add{type = "table", column_count = 2, style = "bordered_table", name = "depot_table"}
  depot_table.style.horizontally_stretchable = true

  update_fuel_tab(depots, depot_table)

  tabbed_pane.add_tab(fuel_tab, contents)
end

local floor = math.floor
local update_request_depot_gui = function(depot, gui, filter)

  local flow = gui.holding_flow
  if not flow then
    flow = gui.add{type = "flow", name = "holding_flow", direction = "vertical"}
    flow.style.horizontally_stretchable = true
  else
    flow.clear()
  end

  local item = depot.item
  local visible = (not filter) or filter.name == item
  gui.visible = visible

  if not visible then return end

  local status_flow = flow.add{type = "table", column_count = 1, style = "bordered_table"}
  
  if item then
    local item_locale = get_item_icon_and_locale(item)
    if item_locale then
      --local request_flow = flow.add{type = "table", column_count = 1, style = "bordered_table"}
      local current_item_flow = status_flow.add{type = "flow"}
      current_item_flow.style.vertical_align = "center"
      local current_count = floor(depot:get_current_amount())
      current_item_flow.add
      {
        type = "sprite-button",
        sprite = item_locale.icon,
        number = current_count,
        tooltip = {"", item_locale.locale, ": ", current_count},
        style = "slot_button"
      }
      current_item_flow.add{type = "label", caption = {"current"}}    
      local requested_item_flow = status_flow.add{type = "flow"}
      requested_item_flow.style.vertical_align = "center"
      local request_count = depot:get_request_size() * depot:get_drone_item_count()
      requested_item_flow.add
      {
        type = "sprite-button",
        sprite = item_locale.icon,
        number = request_count,
        tooltip = {"", item_locale.locale, ": ", request_count},
        style = "slot_button"
      }
      requested_item_flow.add{type = "label", caption = {"requested"}}    
      --flow.add{type = "sprite-button", sprite = icon, number = count, style = "slot_button"}
      --local label = flow.add{type = "label", caption = locale}
      --label.style.width = 128
      --flow.style.vertical_align = "center"
    end
  else
    status_flow.add{type = "label", caption = {"no-request-set"}}    

  end
  
  local label = status_flow.add{type = "label", caption = {"active-drones", depot:get_active_drone_count()}}
  label.style.horizontally_stretchable = true
  status_flow.add{type = "label", caption = {"available-drones", depot:get_drone_item_count()}}
  status_flow.add{type = "label", caption = {"available-fuel", math.floor(depot:get_fuel_amount())}}
  

end

local request_map_size = 64 * 3
local update_request_tab = function(depots, gui, filter)

  for index, depot in pairs (depots) do
    local depot_frame = gui[index]
    if not depot_frame then
      depot_frame = gui.add{type = "flow", name = index}
      depot_frame.style.horizontally_stretchable = true
      add_depot_map_button(depot, depot_frame, request_map_size)
    end
    update_request_depot_gui(depot, depot_frame, filter)
  end
    
  for k, gui in pairs (gui.children) do
    if not depots[gui.name] then
      gui.destroy()
    end
  end

end


local refresh_request_tab = function(player)
  if get_selected_tab_index(player) ~= 6 then return end
  local contents_tab = get_tab(player, "request_tab")
  if not contents_tab then return end
  local network = get_selected_network(player)
  update_request_tab(network.depots.request, contents_tab.depot_table, get_filter_value(player))
end

local refresh_buffer_tab = function(player)
  if get_selected_tab_index(player) ~= 7 then return end
  local contents_tab = get_tab(player, "buffer_tab")
  if not contents_tab then return end
  local network = get_selected_network(player)
  update_request_tab(network.depots.buffer, contents_tab.depot_table, get_filter_value(player))
end

local add_request_tab = function(tabbed_pane, network)
  local request_tab = tabbed_pane.add{type = "tab", caption = {"request-depots"}}
  local contents = tabbed_pane.add{type = "scroll-pane", name = "request_tab"}
  
  local depots = network.depots.request
  if not depots then
    request_tab.enabled = false
    tabbed_pane.add_tab(request_tab, contents)
    return
  end

  local depot_table = contents.add{type = "table", column_count = 2, style = "bordered_table", name = "depot_table"}
  depot_table.style.horizontally_stretchable = true
  update_request_tab(depots, depot_table)

  tabbed_pane.add_tab(request_tab, contents)
end

local buffer_map_size = 64 * 3
local floor = math.floor
local add_buffer_tab = function(tabbed_pane, network)
  local buffer_tab = tabbed_pane.add{type = "tab", caption = {"buffer-depots"}}
  local contents = tabbed_pane.add{type = "scroll-pane", name = "buffer_tab"}
  
  local depots = network.depots.buffer
  if not depots then
    buffer_tab.enabled = false
    tabbed_pane.add_tab(buffer_tab, contents)
    return
  end

  local depot_table = contents.add{type = "table", column_count = 2, style = "bordered_table", name = "depot_table"}
  depot_table.style.horizontally_stretchable = true
  update_request_tab(depots, depot_table)

  tabbed_pane.add_tab(buffer_tab, contents)
end

local make_network_gui = function(inner, network)
  
  local tabbed_pane = inner.add{type = "tabbed-pane", name = "tab_pane"}
  add_contents_tab(tabbed_pane, network)
  add_supply_tab(tabbed_pane, network)
  add_fluid_tab(tabbed_pane, network)
  add_mining_tab(tabbed_pane, network)
  add_fuel_tab(tabbed_pane, network)
  add_request_tab(tabbed_pane, network)
  add_buffer_tab(tabbed_pane, network)
  tabbed_pane.selected_tab_index = 1
  
end

local refresh_network_gui = function(player, selected_index)

  local frame = get_frame(player)
  if not frame then return end

  local network = get_network_by_dropdown_index(selected_index)

  if not network then return end

  local inner = frame.add{type = "frame", style = "inside_deep_frame_for_tabs", name = "inner_frame", direction = "vertical"}
  local subheader = inner.add{type = "flow", name = "subheader_frame"}
  subheader.style.vertical_align = "center"
  local pusher = subheader.add{type = "empty-widget"}
  pusher.style.horizontally_stretchable = true
  subheader.add{type = "label", caption = {"filter"}}
  local filter = subheader.add{type = "choose-elem-button", name = "depot_filter_button", elem_type = "signal"}

  make_network_gui(inner, network)

end

local close_gui = function(player)
  
  local gui = player.gui.screen
  local frame = gui.road_network_frame

  if frame then
    frame.destroy()
  end
end

local refresh_gui = function(player)

  local frame = get_frame(player)
  if not frame then return end

  refresh_contents_tab(player)
  refresh_supply_tab(player)
  refresh_fluid_tab(player)
  refresh_mining_tab(player)
  refresh_fuel_tab(player)
  refresh_request_tab(player)
  refresh_buffer_tab(player)

end

local title_caption = {"road-networks"}
local open_gui = function(player, network_index)
  local gui = player.gui.screen

  local frame = gui.road_network_frame
  if frame then
    frame.clear()
  else
    frame = gui.add{type = "frame", direction = "vertical", name = "road_network_frame"}
  end
  frame.style.maximal_height = player.display_resolution.height * 0.9

  local title_flow = frame.add{type = "flow", name = "title_flow"}

  local title = title_flow.add{type = "label", caption = title_caption, style = "frame_title"}
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
    drop_down.add_item({"road-network-size", count, size})
    if size > big then
      big = size
      selected = count
    end
  end

  if count == 0 then return end

  selected = network_index or selected

  drop_down.selected_index = selected

  refresh_network_gui(player, selected)

  frame.auto_center = true
  player.opened = frame

end

local split = function(str)
  local sep, fields = "/", {}
  local pattern = string.format("([^%s]+)", sep)
  string.gsub(str, pattern, function(c) fields[#fields+1] = c end)
  return fields
end

local on_gui_click = function(event)
  local gui = event.element
  if not (gui and gui.valid) then return end
  
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end

  if gui.name:find("open_depot_map_") then
    local depot_index = gui.name:sub(("open_depot_map_"):len() + 1)
    local depot = depot_common.get_depot_by_index(depot_index)
    if depot then
      player.zoom_to_world(depot.entity.position, 1)
      close_gui(player)
    end
    return
  end

  if gui.type == "sprite-button" then
    local sprite = gui.sprite
    if sprite and sprite ~= "" then
      local result = split(sprite)
      local signal = {type = result[1], name = result[2]}
      set_filter_value(player, signal)
      refresh_gui(player)
    end
  end

end

local on_gui_selection_state_changed = function(event)
  local gui = event.element
  if not (gui and gui.valid) then return end
  
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end
  
  if gui.name == "road_network_drop_down" then
    open_gui(player, gui.selected_index)
    return
  end

end

local on_tick = function(event)
  if game.tick % 60 ~= 0 then return end
  for k, player in pairs (game.players) do
    refresh_gui(player)
  end
end

local on_gui_elem_changed = function(event)
  
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end

  refresh_gui(player)

end

local on_gui_selected_tab_changed = function(event)
  
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end

  refresh_gui(player)

end

local on_gui_closed = function(event)
  local element = event.element
  if not (element and element.valid) then return end
  if element.name == "road_network_frame" then
    element.destroy()
    return
  end
end

local toggle_gui = function(event)
  local player = game.get_player(event.player_index)
  if not (player and player.valid) then return end

  local frame = get_frame(player)
  if frame then
    frame.destroy()
    return
  end

  open_gui(player)

end

local on_lua_shortcut = function(event)
  if event.prototype_name ~= "transport-drones-gui" then return end
  toggle_gui(event)
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
  [defines.events.on_tick] = on_tick,
  [defines.events.on_gui_click] = on_gui_click,
  [defines.events.on_gui_selection_state_changed] = on_gui_selection_state_changed,
  [defines.events.on_gui_selected_tab_changed] = on_gui_selected_tab_changed,
  [defines.events.on_gui_elem_changed] = on_gui_elem_changed,
  [defines.events.on_gui_closed] = on_gui_closed,
  ["toggle-road-network-gui"] = toggle_gui,
  [defines.events.on_lua_shortcut] = on_lua_shortcut
}

return lib
