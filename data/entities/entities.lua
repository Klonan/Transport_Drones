local require = function(name) return require("data/entities/"..name) end

require("transport_depot/transport_depot")
require("transport_depot_circuits/transport_depot_circuits")
