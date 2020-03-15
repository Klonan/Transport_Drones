local transport_drone = require("script/transport_drone")

local interface =
{
  get_drone_count = function()
    return transport_drone.get_drone_count()
  end
}

local lib = {}

lib.add_remote_interface = function()
  if not remote.interfaces["transport_drones"] then
    remote.add_interface("transport_drones", interface)
  end
end

return lib