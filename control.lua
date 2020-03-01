if true then return end

shared = require("shared")
util = require("script/script_util")

local handler = require("event_handler")

handler.add_lib(require("script/mining_drone"))
handler.add_lib(require("script/mining_depot"))
handler.add_lib(require("script/mining_technologies"))
handler.add_lib(require("script/remote_interface"))
