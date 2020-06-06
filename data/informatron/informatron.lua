local util = require("data/tf_util/tf_util")

local path = function(string)
  return util.path("data/informatron/"..string)
end

-- width 960x512 for images to fill the frame.

informatron_make_image("depots", path("depots.png"), 960, 512)
informatron_make_image("road_network", path("road_network.png"), 960, 512)
informatron_make_image("request_depot_1", path("request_depot_1.png"), 960, 512)
informatron_make_image("request_depot_2", path("request_depot_2.png"), 960, 512)
informatron_make_image("fuel_depot", path("fuel_depot.png"), 960, 512)
informatron_make_image("transport_drones", path("transport_drones.png"), 960, 512)
informatron_make_image("road_network_reader", path("road_network_reader.png"), 960, 512)
informatron_make_image("supply_depot", path("supply_depot.png"), 960, 512)
informatron_make_image("buffer_depot", path("buffer_depot.png"), 960, 512)
informatron_make_image("circuit_connectors", path("circuit_connectors.png"), 960, 512)
informatron_make_image("transport_depots", path("transport_depots.png"), 960, 512)
informatron_make_image("mining_depots", path("mining_depots.png"), 960, 512)

informatron_make_image("depot_reader", path("depot_reader.png"), 320, 320)
informatron_make_image("depot_writer", path("depot_writer.png"), 320, 320)
informatron_make_image("depot_writer_special", path("depot_writer_special.png"), 512, 512)
informatron_make_image("network_reader", path("network_reader.png"), 320, 320)
