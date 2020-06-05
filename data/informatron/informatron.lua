local util = require("data/tf_util/tf_util")

local path = function(string)
  return util.path("data/informatron/"..string)
end

-- width 960 for images to fill the frame.

informatron_make_image("transport_drones_thumbnail", path("thumbnail.png"), 769, 769)