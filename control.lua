
shared = require("shared")
util = require("script/script_util")

local handler = require("event_handler")

handler.add_lib(require("script/road_network"))
handler.add_lib(require("script/supply_depot"))
handler.add_lib(require("script/request_depot"))
handler.add_lib(require("script/transport_drone"))
handler.add_lib(require("script/proxy_tile"))

--handler.add_lib(require("script/mining_drone"))
--handler.add_lib(require("script/mining_depot"))
--handler.add_lib(require("script/mining_technologies"))
--handler.add_lib(require("script/remote_interface"))
