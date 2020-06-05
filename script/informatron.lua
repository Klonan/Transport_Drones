local informatron = {}

informatron.menu_list = function(player_index)
  return
  {
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
    gui.add{type = "label", caption = "HI"}
    gui.add{type="button", style="transport_drones_thumbnail"}
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