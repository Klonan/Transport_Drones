
shared = require("shared")
util = require("script/script_util")

local handler = require("event_handler")

handler.add_lib(require("script/road_network"))
handler.add_lib(require("script/depot_common"))
handler.add_lib(require("script/transport_drone"))
handler.add_lib(require("script/proxy_tile"))
handler.add_lib(require("script/blueprint_correction"))
handler.add_lib(require("script/transport_technologies"))
handler.add_lib(require("script/gui"))

require("script/remote_interface")
