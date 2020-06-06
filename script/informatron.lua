local shared = require("shared")
local transport_technologies = require("script/transport_technologies")
local informatron = {}

informatron.menu_list = function(player_index)
  if game.active_mods["Mining_Drones"] then
    return
    {
      road_network = 1,
      drone = 1,
      depots =
      {
        fuel_depots = 1,
        request_depots = 1,
        supply_depots = 1,
        buffer_depots = 1,
        mining_depots = 1
      },
      circuit_connectors =
      {
        depot_reader = 1,
        depot_writer = 1,
        network_reader = 1
      },
    }
  end
  return
  {
    road_network = 1,
    drone = 1,
    depots =
    {
      fuel_depots = 1,
      request_depots = 1,
      supply_depots = 1,
      buffer_depots = 1,
    },
    circuit_connectors =
    {
      depot_reader = 1,
      depot_writer = 1,
      network_reader = 1
    },
  }

end

local doerhickers =
{
  transport_drones = function(gui)
    gui.add{type = "label", caption = {"transport_drones_pages.welcome-1"}}
    gui.add{type="button", style="depots"}
  end,
  road_network = function(gui)
    gui.add{type = "label", caption = {"transport_drones_pages.road-network"}}
    gui.add{type="button", style="road_network"}
  end,
  request_depots = function(gui)
    gui.add{type = "label", caption = {"transport_drones_pages.request-depot-1"}}
    gui.add{type="button", style="request_depot_1"}
    gui.add{type = "label", caption = {"transport_drones_pages.request-depot-2"}}
    --gui.add{type="button", style="request_depot_2"}
  end,
  fuel_depots = function(gui)
    gui.add{type = "label", caption = {"transport_drones_pages.fuel-depot-1"}}
    gui.add{type="button", style="fuel_depot"}
  end,
  drone = function(gui)

    local force_index = game.get_player(gui.player_index).force.index
    gui.add{type = "label", caption = {"transport_drones_pages.drones-1"}}
    gui.add
    {
      type = "label",
      caption =
      {
        "transport_drones_pages.drone-details",
        shared.fuel_consumption_per_meter * 1000,
        shared.drone_pollution_per_second * 60,
        1 + transport_technologies.get_transport_capacity_bonus(force_index),
        (1 + transport_technologies.get_transport_capacity_bonus(force_index)) * shared.drone_fluid_capacity,
        (0.1 * (1 + transport_technologies.get_transport_speed_bonus(force_index))) * ((60 * 60 * 60) / 1000)
      }
    }
    gui.add{type="button", style="transport_drones"}
  end,
  supply_depots = function(gui)
    gui.add{type = "label", caption = {"transport_drones_pages.supply-depot"}}
    gui.add{type="button", style="supply_depot"}
  end,
  buffer_depots = function(gui)
    gui.add{type = "label", caption = {"transport_drones_pages.buffer-depot"}}
    gui.add{type="button", style="buffer_depot"}
  end,
  circuit_connectors = function(gui)
    gui.add{type = "label", caption = {"transport_drones_pages.circuit-connectors"}}
    gui.add{type="button", style="circuit_connectors"}
  end,
  depots = function(gui)
    gui.add{type = "label", caption = {"transport_drones_pages.transport-depots"}}
    gui.add{type="button", style="transport_depots"}
  end,
  mining_depots = function(gui)
    gui.add{type = "label", caption = {"transport_drones_pages.mining-depots"}}
    gui.add{type="button", style="mining_depots"}
  end,
  depot_reader = function(gui)
    local table = gui.add{type = "flow"}
    table.add{type="button", style="depot_reader"}
    local label = table.add{type = "label", caption = {"transport_drones_pages.depot-reader"}}
    label.style.single_line = false
  end,
  depot_writer = function(gui)
    local table = gui.add{type = "flow"}
    table.add{type="button", style="depot_writer"}
    local label = table.add{type = "label", caption = {"transport_drones_pages.depot-writer"}}
    label.style.single_line = false

    local table = gui.add{type = "flow"}
    table.add{type="button", style="depot_writer_special"}
    local label = table.add{type = "label", caption = {"transport_drones_pages.depot-writer-special"}}
    label.style.single_line = false

  end,
  network_reader = function(gui)
    local table = gui.add{type = "flow"}
    table.add{type="button", style="network_reader"}
    local label = table.add{type = "label", caption = {"transport_drones_pages.network-reader"}}
    label.style.single_line = false
  end,

}

informatron.page_content = function(page_name, player_index, element)
  if doerhickers[page_name] then
    doerhickers[page_name](element)
  end
end

return informatron