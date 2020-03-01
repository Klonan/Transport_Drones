local mining_drone = require("script/mining_drone")
local mining_depot = require("script/mining_depot")

local interface =
{
  get_drone_count = function()
    return mining_drone.get_drone_count()
  end
}

local lib = {}

lib.add_remote_interface = function()
  if not remote.interfaces["mining_drones"] then
    remote.add_interface("mining_drones", interface)
  end
end

return lib