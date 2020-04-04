local transport_drone = require("script/transport_drone")
local depot_common = require("script/depot_common")

local interface =
{
  get_drone_count = function()
    return transport_drone.get_drone_count()
  end,
  add_depot_lib = function()
    depot_common.add_depot_lib(entity_name, lib)
  end
}

local lib = {}

lib.add_remote_interface = function()
  if not remote.interfaces["transport_drones"] then
    remote.add_interface("transport_drones", interface)
  end
end

return lib