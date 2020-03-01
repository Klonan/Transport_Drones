local require = function(name) return require("data/entities/"..name) end

require("transport_drone/transport_drone")
require("transport_depot/transport_depot")

--require("mining_drone/mining_drone")
--require("proxy_chest/proxy_chest")
--require("mining_depot/mining_depot")