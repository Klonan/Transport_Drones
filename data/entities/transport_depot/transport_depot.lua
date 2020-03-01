local depot = util.copy(data.raw["offshore-pump"]["offshore-pump"])

depot.name = "transport-depot"


depot.collision_mask = { "object-layer", "resource-layer"}
depot.fluid_box_tile_collision_test = {"object-layer"}
depot.center_collision_mask = { "object-layer", "resource-layer"}
depot.adjacent_tile_collision_test = { "object-layer" }
depot.adjacent_tile_collision_mask = { "ground-tile" }
depot.adjacent_tile_collision_box = { { -0.4, -3 }, { 0.4, -3.5 } }
depot.collision_box = {{-1.4, -2.4},{1.4, 2.4}}
depot.selection_box = {{-1.5, -2.5},{1.5, 2.5}}
--depot.fluid = nil
depot.fluid_box =
{
  base_area = 1,
  base_level = 1,
  pipe_covers = pipecoverspictures(),
  production_type = "input-output",
  --filter = "water",
  pipe_connections =
  {
    {
      position = {0, -3},
      type = "input-output"
    }
  }
}
depot.order = "nuasdj"
data:extend{depot}


local base = function(shift)
  return
  {
    filename = util.path("data/entities/mining_depot/depot-base.png"),
    width = 474,
    height = 335,
    frame_count = 1,
    scale = 0.45,
    shift = shift
  }
end

local h_chest = function(shift)
  return
  {
    filename = util.path("data/entities/mining_depot/depot-chest-h.png"),
    width = 190,
    height = 126,
    frame_count = 1,
    scale = 0.5,
    shift = shift
  }
end
local h_shadow = function(shift)
  return
  {
    filename = util.path("data/entities/mining_depot/depot-chest-h-shadow.png"),
    width = 192,
    height = 99,
    frame_count = 1,
    scale = 0.5,
    shift = shift,
    draw_as_shadow = true
  }
end

local v_chest = function(shift)
  return
  {
    filename = util.path("data/entities/mining_depot/depot-chest-v.png"),
    width = 136,
    height = 189,
    frame_count = 1,
    scale = 0.4,
    shift = shift
  }
end

local v_shadow = function(shift)
  return
  {
    filename = util.path("data/entities/mining_depot/depot-chest-v-shadow.png"),
    width = 150,
    height = 155,
    frame_count = 1,
    scale = 0.4,
    shift = shift,
    draw_as_shadow = true
  }
end

depot.graphics_set =
{
  animation = 
  {
    north =
    {
      layers =
      {
        base{0, -0.5},
        h_shadow{0.2, 1.5},
        h_chest{0, 1.5},
        
      }
    },
    south =
    {
      layers =
      {
        h_shadow{0.2, -1.5},
        h_chest{0, -1.5},
        base{0, 1},
      }
    },
    east =
    {
      layers =
      {
      v_shadow{-1.3, 0},
      v_chest{-1.5, 0},
      base{0.5, 0.2},
    }
    },
    west =
    {
      layers =
      {
        v_shadow{1.7, 0},
        v_chest{1.5, 0},
        base{-0.5, 0.2},
      }
    },
  }
}
