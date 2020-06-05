local informatron = {}

informatron.menu_list = function(player_index)
  return
  {
    road_network = 1,
    request_depots = 1,
    supply_depots = 1,
    fuel_depots = 1,
    buffer_depots = 1,
    circuit_connectors = 1,
  }
end

local doerhickers =
{
  transport_drones = function(gui)
    gui.add{type = "label", caption = {"transport_drones_pages.welcome-1"}}
    gui.add{type="button", style="transport_drones_thumbnail"}
    gui.add{type = "label", caption = {"transport_drones_pages.welcome-2"}}
  end,
  road_network = function(gui)

  end,
  request_depots = function(gui)

  end
}

informatron.page_content = function(page_name, player_index, element)
  if doerhickers[page_name] then
    doerhickers[page_name](element)
  end
end

return informatron