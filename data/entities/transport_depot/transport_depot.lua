local collision_box = {{-1.25, -1.25},{1.25, 1.25}}
local selection_box = {{-1.5, -1.5}, {1.5, 1.5}}

local depot = util.copy(data.raw["offshore-pump"]["offshore-pump"])

local fluid = util.copy(data.raw.fluid.water)
fluid.name = "transparent-fluid"
fluid.icon_size = 1
fluid.icon_mipmaps = nil

data:extend{fluid}


local caution_sprite =
{
  type = "sprite",
  name = "caution-sprite",
  filename = util.path("data/entities/transport_depot/depot-caution.png"),
  width = 101,
  height = 72,
  frame_count = 1,
  scale = 0.33,
  shift = shift,
  direction_count = 1,
  draw_as_shadow = false,
  flags = {"terrain"}
}



depot.name = "request-transport-depot"
depot.localised_name = {"request-depot"}
depot.icon = util.path("data/entities/transport_depot/request-depot-icon.png")
depot.icon_size = 216

depot.collision_mask = { "object-layer", "player-layer"}
depot.fluid_box_tile_collision_test = {"layer-14"}
depot.center_collision_mask = { "object-layer", "resource-layer"}
depot.adjacent_tile_collision_test = shared.tile_collision_mask
depot.adjacent_tile_collision_mask = { "ground-tile" }
depot.adjacent_tile_collision_box = { { -0.4, -2 }, { 0.4, -2.5 } }
depot.corpse = nil
depot.collision_box = collision_box
depot.selection_box = selection_box
depot.radius_visualisation_specification =
{
  sprite = caution_sprite,
  distance = 0.5,
  offset = {0, -2}
}
depot.fluid = "transparent-fluid"
depot.fluid_box =
{
  base_area = 1,
  base_level = 1,
  --pipe_covers = pipecoverspictures(),
  --production_type = "input-output",
  --filter = "water",
  pipe_connections =
  {
    {
      position = {0, -2},
      type = "input-output"
    }
  }
}
depot.order = "nuasdj"


local request_base = function(shift)
  return
  {
    filename = util.path("data/entities/transport_depot/request-depot-base.png"),
    width = 474,
    height = 335,
    frame_count = 1,
    scale = 0.45,
    shift = shift
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
        request_base{0, 0},
      }
    },
    south =
    {
      layers =
      {
        request_base{0, 0},
      }
    },
    east =
    {
      layers =
      {
        request_base{0, 0},
    }
    },
    west =
    {
      layers =
      {
        request_base{0, 0},
      }
    },
  }
}

local supply_depot = util.copy(depot)
supply_depot.name = "supply-transport-depot"
supply_depot.localised_name = {"supply-depot"}


local supply_base = function(shift)
  return
  {
    filename = util.path("data/entities/transport_depot/supply-depot-base.png"),
    width = 474,
    height = 335,
    frame_count = 1,
    scale = 0.45,
    shift = shift
  }
end

supply_depot.graphics_set =
{
  animation = 
  {
    north =
    {
      layers =
      {
        supply_base{0,0},
      }
    },
    south =
    {
      layers =
      {
        supply_base{0, 0},
      }
    },
    east =
    {
      layers =
      {
        supply_base{0,0},
      }
    },
    west =
    {
      layers =
      {
        supply_base{0,0},
      }
    }
  }
}

supply_depot.adjacent_tile_collision_box = { { -0.4, -2 }, { 0.4, -2.5 } }
supply_depot.collision_box = collision_box
supply_depot.selection_box = selection_box
supply_depot.icon = util.path("data/entities/transport_depot/supply-depot-icon.png")
supply_depot.fluid_box =
{
  base_area = 1,
  base_level = 1,
  --pipe_covers = pipecoverspictures(),
  --production_type = "input-output",
  --filter = "water",
  pipe_connections =
  {
    {
      position = {0, -2},
      type = "input-output"
    }
  }
}
supply_depot.order = "nuasdjz"


local caution_corpse =
{
  type = "corpse",
  name = "caution-corpse",
  flags = {"placeable-off-grid"},
  animation = caution_sprite,
  remove_on_entity_placement = false,
  remove_on_tile_placement = false
}

local machine = util.copy(data.raw["assembling-machine"]["assembling-machine-3"])

local supply_depot_chest = 
{
  type = "container",
  name = "supply-depot-chest",
  localised_name = {"supply-depot"},
  icon = util.path("data/entities/transport_depot/supply-depot-icon.png"),
  icon_size = 216,
  dying_explosion = machine.dying_explosion,
  damaged_trigger_effect = machine.damaged_trigger_effect,
  corpse = machine.corpse,
  flags = {"placeable-neutral", "player-creation"},
  minable = {mining_time = 0.1, result = "wooden-chest"},
  max_health = 150,
  collision_box = {{-1.4, -1.4}, {1.4, 1.4}},
  fast_replaceable_group = "container",
  selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
  inventory_size = 100,
  open_sound = { filename = "__base__/sound/metallic-chest-open.ogg", volume=0.5 },
  close_sound = { filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.5 },
  picture =
  {
    layers =
    {
      supply_base{0,0}
    }
  },
  order = "nil",
  minable = {result = "supply-depot", mining_time = 1},
  placeable_by = {item = "supply-depot", count = 1}

}

local name = "request-depot-machine"

local category =
{
  type = "recipe-category",
  name = "transport-drone-request"
}

machine.name = name
machine.localised_name = {"request-depot"}
machine.collision_box = collision_box
machine.selection_box = selection_box
machine.crafting_categories = {"transport-drone-request"}
machine.crafting_speed = (1)
machine.ingredient_count = nil
machine.collision_mask = {"item-layer", "object-layer", "water-tile", "player-layer", "resource-layer"}
machine.allowed_effects = {"consumption", "speed", "pollution"}
machine.module_specification = nil
machine.minable = {result = "request-depot", mining_time = 1}
machine.flags = {"placeable-neutral", "player-creation"}
machine.next_upgrade = nil
machine.fluid_boxes = nil
machine.scale_entity_info_icon = true
machine.energy_usage = "1W"
machine.gui_title_key = "transport-depot-choose-item"
machine.energy_source =
{
  type = "void",
  usage_priority = "secondary-input",
  emissions_per_second_per_watt = 0.1
}
machine.icon = util.path("data/entities/transport_depot/request-depot-icon.png")
machine.icon_size = 216
machine.radius_visualisation_specification = nil
machine.order = "asdufh"
machine.placeable_by = {item = "request-depot", count = 1}

machine.animation =
{
  north =
  {
    layers =
    {
      request_base{0, 0},
    }
  },
  south =
  {
    layers =
    {
      request_base{0, 0},
    }
  },
  east =
  {
    layers =
    {
      request_base{0, 0},
    }
  },
  west =
  {
    layers =
    {
      request_base{0, 0},
    }
  },
}

local items = 
{
  {
    type = "item",
    name = "supply-depot",
    localised_name = {"supply-depot"},
    icon = supply_depot_chest.icon,
    icon_size = supply_depot_chest.icon_size,
    flags = {},
    subgroup = "transport",
    order = "e-a",
    stack_size = 10,
    place_result = supply_depot.name
  },
  {
    type = "item",
    name = "request-depot",
    localised_name = {"request-depot"},
    icon = machine.icon,
    icon_size = machine.icon_size,
    flags = {},
    subgroup = "transport",
    order = "e-b",
    stack_size = 10,
    place_result = depot.name
  }
}

data:extend(items)


data:extend
{
  depot,
  supply_depot,
  caution_corpse,
  supply_depot_chest,
  machine,
  category
}