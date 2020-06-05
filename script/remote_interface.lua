local transport_drone = require("script/transport_drone")
local depot_common = require("script/depot_common")
local informatron = require("script/informatron")

local interface =
{
  get_drone_count = function()
    return transport_drone.get_drone_count()
  end,
  informatron_menu = function(data)
    return informatron.menu_list(data.player_index)
  end,
  informatron_page_content = function(data)
    return informatron.page_content(data.page_name, data.player_index, data.element)
  end
}

if not remote.interfaces["transport_drones"] then
  remote.add_interface("transport_drones", interface)
end
