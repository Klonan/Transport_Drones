local collision_box = {{-1.25, -1.25},{1.26, 1.26}}
local selection_box = {{-1.5, -1.5}, {1.5, 1.5}}

local category = 
{
  type = "item-subgroup",
  name = "transport-drones",
  group = "logistics",
  order = "ez"
}

data:extend{category}

local depot = util.copy(data.raw["assembling-machine"]["assembling-machine-3"])

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


depot.name = "request-depot"
depot.localised_name = {"request-depot"}
depot.icon = util.path("data/entities/transport_depot/request-depot-icon.png")
depot.icon_size = 216
depot.collision_box = collision_box
depot.selection_box = selection_box
depot.max_health = 150
depot.radius_visualisation_specification =
{
  sprite = caution_sprite,
  distance = 0.5,
  offset = {0, -2}
}
depot.fluid_boxes =
{
  {
    production_type = "output",
    base_area = 10,
    base_level = -1,
    pipe_connections = {{ type="input-output", position = {0, -2} }},
  },
  off_when_no_fluid_recipe = false
}
depot.crafting_categories = {"transport-drone-request"}
depot.crafting_speed = (1)
depot.ingredient_count = nil
depot.collision_mask = {"item-layer", "object-layer", "water-tile", "player-layer", "resource-layer"}
depot.allowed_effects = {}
depot.module_specification = nil
depot.minable = {result = "request-depot", mining_time = 1}
depot.flags = {"placeable-neutral", "player-creation"}
depot.next_upgrade = nil
depot.scale_entity_info_icon = true
depot.energy_usage = "1W"
depot.gui_title_key = "transport-depot-choose-item"
depot.energy_source =
{
  type = "void",
  usage_priority = "secondary-input",
  emissions_per_second_per_watt = 0.1
}
depot.placeable_by = {item = "request-depot", count = 1}

depot.animation =
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

local supply_depot = util.copy(depot)
supply_depot.name = "supply-depot"
supply_depot.localised_name = {"supply-depot"}
supply_depot.icon = util.path("data/entities/transport_depot/supply-depot-icon.png")
table.insert(supply_depot.flags, "not-deconstructable")


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

supply_depot.animation =
{
  north =
  {
    layers =
    {
      supply_base{0, 0},
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
      supply_base{0, 0},
    }
  },
  west =
  {
    layers =
    {
      supply_base{0, 0},
    }
  },
}

local caution_corpse =
{
  type = "corpse",
  name = "transport-caution-corpse",
  flags = {"placeable-off-grid"},
  animation = caution_sprite,
  remove_on_entity_placement = false,
  remove_on_tile_placement = false
}

local supply_depot_chest = 
{
  type = "container",
  name = "supply-depot-chest",
  localised_name = {"supply-depot"},
  icon = util.path("data/entities/transport_depot/supply-depot-icon.png"),
  icon_size = 216,
  dying_explosion = depot.dying_explosion,
  damaged_trigger_effect = depot.damaged_trigger_effect,
  corpse = depot.corpse,
  flags = {"placeable-neutral", "player-creation", "not-blueprintable"},
  max_health = 150,
  collision_box = collision_box,
  collision_mask = {},
  selection_priority = 100,
  fast_replaceable_group = "container",
  scale_info_icons = false,
  selection_box = selection_box,
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
  picture = util.empty_sprite(),
  order = "nil",
  minable = {result = "supply-depot", mining_time = 1},
  placeable_by = {item = "supply-depot", count = 1},

}

local category =
{
  type = "recipe-category",
  name = "transport-drone-request"
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
    subgroup = "transport-drones",
    order = "e-a",
    stack_size = 10,
    place_result = "supply-depot"
  },
  {
    type = "recipe",
    name = "supply-depot",
    localised_name = {"supply-depot"},
    icon = supply_depot_chest.icon,
    icon_size = supply_depot_chest.icon_size,
    --category = "transport",
    enabled = true,
    ingredients =
    {
      {"iron-plate", 10},
    },
    energy_required = 1,
    result = "supply-depot"
  },
  {
    type = "item",
    name = "request-depot",
    localised_name = {"request-depot"},
    icon = depot.icon,
    icon_size = depot.icon_size,
    flags = {},
    subgroup = "transport-drones",
    order = "e-b",
    stack_size = 10,
    place_result = "request-depot"
  },
  {
    type = "recipe",
    name = "request-depot",
    localised_name = {"request-depot"},
    icon = depot.icon,
    icon_size = depot.icon_size,
    --category = "transport",
    enabled = true,
    ingredients =
    {
      {"iron-plate", 10},
    },
    energy_required = 1,
    result = "request-depot"
  }
}

data:extend(items)



data:extend
{
  depot,
  supply_depot,
  caution_corpse,
  supply_depot_chest,
  category
}