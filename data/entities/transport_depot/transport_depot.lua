local collision_box = { { -1.25, -1.25 }, { 1.25, 1.25 } }
local selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } }

local category =
{
  type = "item-subgroup",
  name = "transport-drones",
  group = "logistics",
  order = "ez"
}

data:extend { category }

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
  -- shift = shift,
  direction_count = 1,
  draw_as_shadow = false,
  flags = { "terrain" }
}

local request_base = function(shift)
  return
  {
    filename = util.path("data/entities/transport_depot/request-depot-base.png"),
    priority = "high",
    width = 474,
    height = 335,
    frame_count = 1,
    scale = 0.45,
    shift = shift
  }
end

depot.name = "request-depot"
depot.module_slots = 0
depot.localised_name = { "request-depot" }
depot.icon = util.path("data/entities/transport_depot/request-depot-icon.png")
depot.icon_size = 216
depot.icon_mipmaps = 0
depot.collision_box = collision_box
depot.selection_box = selection_box
depot.max_health = 150
depot.fast_replaceable_group = nil
depot.radius_visualisation_specification =
{
  sprite = caution_sprite,
  distance = 0.5,
  offset = { 0, -2 }
}
depot.fluid_boxes =
{
  {
    production_type = "input",
    volume = 1000,
    pipe_connections = { { flow_direction = "input", direction = defines.direction.north,position = { 0, -1 } } },
  },
  {
    production_type = "output",
    volume = 1000000,
    pipe_connections = { { flow_direction = "output",direction = defines.direction.south, position = { 0, 1 } } },
    pipe_covers = pipecoverspictures(),
    pipe_picture = assembler3pipepictures(),
    secondary_draw_orders = { north = -1, east = -1, west = -1 }
  },
  -- off_when_no_fluid_recipe = false
}
depot.fluid_boxes_off_when_no_fluid_recipe = false
depot.crafting_categories = { "transport-drone-request" }
depot.crafting_speed = (1)
depot.ingredient_count = nil
--depot.collision_mask = {"item-layer", "object-layer", "water-tile", "player-layer", "resource-layer"}
depot.se_allow_in_space = true
depot.allowed_effects = {}
depot.module_specification = nil
depot.minable = { result = "request-depot", mining_time = 1 }
depot.flags = { "placeable-neutral", "player-creation" }
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
depot.placeable_by = { item = "request-depot", count = 1 }

depot.graphics_set.animation =
{
  north =
  {
    layers =
    {
      request_base { 0, 0.4 },
    }
  },
  south =
  {
    layers =
    {
      request_base { 0, 0.4 },
    }
  },
  east =
  {
    layers =
    {
      request_base { 0, 0.4 },
    }
  },
  west =
  {
    layers =
    {
      request_base { 0, 0.4 },
    }
  },
}

local supply_depot = util.copy(depot)
supply_depot.name = "supply-depot"
supply_depot.module_slots = 0
supply_depot.localised_name = { "supply-depot" }
supply_depot.icon = util.path("data/entities/transport_depot/supply-depot-icon.png")
supply_depot.minable = { result = "supply-depot", mining_time = 1 }
supply_depot.placeable_by = { item = "supply-depot", count = 1 }
table.insert(supply_depot.flags, "not-deconstructable")

supply_depot.fluid_boxes =
{
  {
    production_type = "input",
    volume = 500,
    pipe_connections = { { flow_direction = "input",direction = defines.direction.north, position = { 0, -1 } } },
  },
  -- off_when_no_fluid_recipe = false
}
supply_depot.fluid_boxes_off_when_no_fluid_recipe = false


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

supply_depot.graphics_set.animation =
{
  north =
  {
    layers =
    {
      supply_base { 0, 0.4 },
    }
  },
  south =
  {
    layers =
    {
      supply_base { 0, 0.4 },
    }
  },
  east =
  {
    layers =
    {
      supply_base { 0, 0.4 },
    }
  },
  west =
  {
    layers =
    {
      supply_base { 0, 0.4 },
    }
  },
}

local caution_corpse =
{
  type = "corpse",
  name = "transport-caution-corpse",
  flags = { "placeable-off-grid" },
  animation = caution_sprite,
  remove_on_entity_placement = false,
  remove_on_tile_placement = false
}

local supply_depot_chest =
{
  type = "container",
  name = "supply-depot-chest",
  localised_name = { "supply-depot" },
  icon = util.path("data/entities/transport_depot/supply-depot-icon.png"),
  icon_size = 216,
  dying_explosion = depot.dying_explosion,
  damaged_trigger_effect = depot.damaged_trigger_effect,
  corpse = depot.corpse,
  flags = { "placeable-neutral", "player-creation", "not-blueprintable" },
  max_health = 150,
  collision_box = collision_box,
  -- collision_mask = {},
  selection_priority = 100,
  fast_replaceable_group = "container",
  scale_info_icons = false,
  selection_box = selection_box,
  inventory_size = 100,
  module_slots = 0,
  open_sound = { filename = "__base__/sound/metallic-chest-open.ogg", volume = 0.5 },
  close_sound = { filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.5 },
  picture =
  {
    layers =
    {
      supply_base { 0, 0 }
    }
  },
  picture = util.empty_sprite(),
  order = "nil",
  minable = { result = "supply-depot", mining_time = 1 },
  placeable_by = { item = "supply-depot", count = 1 },
  circuit_wire_max_distance = 10,
  circuit_wire_connection_point = circuit_connector_definitions["roboport"].points,
  circuit_connector_sprites = circuit_connector_definitions["roboport"].sprites,

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
    localised_name = { "supply-depot" },
    icon = supply_depot_chest.icon,
    icon_size = supply_depot_chest.icon_size,
    flags = {},
    subgroup = "transport-drones",
    order = "e-a-a",
    stack_size = 10,
    place_result = "supply-depot"
  },
  {
    type = "recipe",
    name = "supply-depot",
    localised_name = { "supply-depot" },
    icon = supply_depot_chest.icon,
    icon_size = supply_depot_chest.icon_size,
    --category = "transport",
    enabled = false,
    ingredients =
    {
      { type = "item", name = "iron-plate",       amount = 50 },
      { type = "item", name = "iron-gear-wheel",  amount = 10 },
      { type = "item", name = "iron-stick",       amount = 20 },
    },
    energy_required = 5,
    results = {
      { type = "item", name = "supply-depot", amount = 1 }
    }
  },
  {
    type = "item",
    name = "request-depot",
    localised_name = { "request-depot" },
    icon = depot.icon,
    icon_size = depot.icon_size,
    flags = {},
    subgroup = "transport-drones",
    order = "e-a-b",
    stack_size = 10,
    place_result = "request-depot"
  },
  {
    type = "recipe",
    name = "request-depot",
    localised_name = { "request-depot" },
    icon = depot.icon,
    icon_size = depot.icon_size,
    --category = "transport",
    enabled = false,
    ingredients =
    {
      { type = "item",name = "iron-plate",      amount =50 },
      { type = "item",name = "iron-gear-wheel", amount =10 },
      { type = "item",name = "iron-stick",      amount =20 },
    },
    energy_required = 5,
    results = {
      { type = "item", name = "request-depot", amount = 1 }
    }
  }
}

data:extend(items)

local fuel_depot = util.copy(depot)
fuel_depot.name = "fuel-depot"

fuel_depot.localised_name = { "fuel-depot" }
fuel_depot.icon = util.path("data/entities/transport_depot/fuel-depot-icon.png")
fuel_depot.icon_size = 264
fuel_depot.collision_box = { { -2.25, -2.25 }, { 2.25, 2.25 } }
fuel_depot.selection_box = { { -2.25, -2.25 }, { 2.25, 2.25 } }
fuel_depot.fluid_boxes =
{
  {
    production_type = "output",
    volume = 100,
    pipe_connections = { { flow_direction = "input-output",direction = defines.direction.north, position = { 0, -2 } } },
  },
  {
    production_type = "input",
    volume = 100,
    pipe_connections = { { flow_direction = "input-output", direction = defines.direction.south,position = { 0, 2 } } },
    pipe_covers = pipecoverspictures(),
    pipe_picture = assembler3pipepictures(),
    secondary_draw_orders = { north = -1, east = -1, west = -1 }
  },
  -- off_when_no_fluid_recipe = false
}
fuel_depot.fluid_boxes_off_when_no_fluid_recipe = false
local fuel_base = function(shift)
  return
  {
    filename = util.path("data/entities/transport_depot/fuel-depot-base.png"),
    width = 334,
    height = 266,
    frame_count = 1,
    scale = (32 * 5) / 266,
    shift = { 0.66, -0.1 }
  }
end

fuel_depot.graphics_set.animation =
{
  north =
  {
    layers =
    {
      fuel_base(),
    }
  },
  south =
  {
    layers =
    {
      fuel_base(),
    }
  },
  east =
  {
    layers =
    {
      fuel_base(),
    }
  },
  west =
  {
    layers =
    {
      fuel_base(),
    }
  },
}

local fuel_depot_items =
{
  {
    type = "item",
    name = "fuel-depot",
    localised_name = { "fuel-depot" },
    icon = fuel_depot.icon,
    icon_size = fuel_depot.icon_size,
    flags = {},
    subgroup = "transport-drones",
    order = "e-c",
    stack_size = 10,
    place_result = "fuel-depot"
  },
  {
    type = "recipe",
    name = "fuel-depot",
    localised_name = { "fuel-depot" },
    icon = fuel_depot.icon,
    icon_size = fuel_depot.icon_size,
    --category = "transport",
    enabled = false,
    ingredients =
    {
      {type = "item",name =  "steel-plate",     amount =10 },
      {type = "item",name =  "iron-plate",      amount =20 },
      {type = "item",name =  "iron-gear-wheel", amount =5 },
    },
    energy_required = 10,
    results = {
      { type = "item", name = "fuel-depot", amount = 1 }
    }
  }
}

local fuel_recipe_category =
{
  type = "recipe-category",
  name = "fuel-depot"
}

data:extend { fuel_recipe_category }

local fuel_signal =
{
  type = "virtual-signal",
  name = "fuel-signal",
  icon = util.path("data/entities/transport_depot/fuel-recipe-icon.png"),
  icon_size = 64,
  subgroup = "virtual-signal",
  order = "oh-yea-baby"
}

fuel_depot.fixed_recipe = "fuel-depots"
fuel_depot.fixed_quality = "normal"
fuel_depot.crafting_categories = { "fuel-depot" }
fuel_depot.minable.result = "fuel-depot"
fuel_depot.placeable_by = { item = "fuel-depot", count = 1 }

data:extend(fuel_depot_items)
data:extend { fuel_signal }

local invisble_corpse =
{
  type = "corpse",
  name = "invisible-transport-caution-corpse",
  flags = { "placeable-off-grid" },
  animation = util.empty_sprite(),
  remove_on_entity_placement = false,
  remove_on_tile_placement = false
}

local fluid_request_category =
{
  type = "recipe-category",
  name = "transport-fluid-request"
}

local fluid_supply_depot = util.copy(fuel_depot)
fluid_supply_depot.localised_name = { "fluid-depot" }
fluid_supply_depot.icon = util.path("data/entities/transport_depot/fluid-depot-icon.png")
fluid_supply_depot.icon_size = 144
fluid_supply_depot.collision_box = collision_box
fluid_supply_depot.selection_box = selection_box
fluid_supply_depot.name = "fluid-depot"
fluid_supply_depot.type = "furnace"
fluid_supply_depot.crafting_categories = { "transport-fluid-request" }
fluid_supply_depot.source_inventory_size = 0
fluid_supply_depot.result_inventory_size = 0
fluid_supply_depot.fixed_recipe = nil
fluid_supply_depot.placeable_by = { item = "fluid-depot", count = 1 }
fluid_supply_depot.minable.result = "fluid-depot"


fluid_supply_depot.fluid_boxes =
{
  {
    production_type = "output",
    volume = 10,
    base_level = -1,
    pipe_connections = { { flow_direction = "input-output",direction = defines.direction.north, position = { 0, -1 } } },
  },
  {
    production_type = "input",
    volume = 40000,
    base_level = -1,
    pipe_connections = { { flow_direction = "input-output", direction = defines.direction.south, position = { 0, 1 } } },
    pipe_covers = pipecoverspictures(),
    pipe_picture = assembler3pipepictures(),
    secondary_draw_orders = { north = -1, east = -1, west = -1 }
  },
  -- off_when_no_fluid_recipe = false
}
fluid_supply_depot.fluid_boxes_off_when_no_fluid_recipe = false
local fluid_base = function(shift)
  return
  {
    filename = util.path("data/entities/transport_depot/fluid-depot-base.png"),
    width = 231,
    height = 146,
    frame_count = 1,
    scale = (32 * 3) / 146,
    shift = { 0.5, 0 }
  }
end

fluid_supply_depot.graphics_set.animation =
{
  north =
  {
    layers =
    {
      fluid_base(),
    }
  },
  south =
  {
    layers =
    {
      fluid_base(),
    }
  },
  east =
  {
    layers =
    {
      fluid_base(),
    }
  },
  west =
  {
    layers =
    {
      fluid_base(),
    }
  },
}

data:extend
{
  fluid_supply_depot,
  fluid_request_category
}

local fluid_depot_items =
{
  {
    type = "item",
    name = "fluid-depot",
    localised_name = { "fluid-depot" },
    icon = fluid_supply_depot.icon,
    icon_size = fluid_supply_depot.icon_size,
    flags = {},
    subgroup = "transport-drones",
    order = "e-c",
    stack_size = 10,
    place_result = "fluid-depot"
  },
  {
    type = "recipe",
    name = "fluid-depot",
    localised_name = { "fluid-depot" },
    icon = fluid_supply_depot.icon,
    icon_size = fluid_supply_depot.icon_size,
    --category = "transport",
    enabled = false,
    ingredients =
    {
      {type = "item",name =  "iron-plate",      amount=50 },
      {type = "item",name =  "iron-gear-wheel", amount=10 },
      {type = "item",name =  "iron-stick",      amount=20 },
    },
    energy_required = 5,
    results = {
      { type = "item", name = "fluid-depot", amount = 1 }
    }
  }
}

data:extend(fluid_depot_items)

data:extend
{
  depot,
  supply_depot,
  caution_corpse,
  invisble_corpse,
  supply_depot_chest,
  category,
  fuel_depot
}

local buffer_depot = util.copy(depot)
buffer_depot.name = "buffer-depot"
buffer_depot.localised_name = { "buffer-depot" }
buffer_depot.minable.result = "buffer-depot"
buffer_depot.placeable_by = { item = "buffer-depot", count = 1 }
buffer_depot.icon = util.path("data/entities/transport_depot/buffer-depot-icon.png")


local buffer_base = function(shift)
  return
  {
    filename = util.path("data/entities/transport_depot/buffer-depot-base.png"),
    width = 474,
    height = 335,
    frame_count = 1,
    scale = 0.45,
    shift = shift
  }
end

buffer_depot.graphics_set.animation =
{
  north =
  {
    layers =
    {
      buffer_base { 0, 0.4 },
    }
  },
  south =
  {
    layers =
    {
      buffer_base { 0, 0.4 },
    }
  },
  east =
  {
    layers =
    {
      buffer_base { 0, 0.4 },
    }
  },
  west =
  {
    layers =
    {
      buffer_base { 0, 0.4 },
    }
  }
}

local buffer_depot_items =
{
  {
    type = "item",
    name = "buffer-depot",
    localised_name = { "buffer-depot" },
    icon = buffer_depot.icon,
    icon_size = buffer_depot.icon_size,
    flags = {},
    subgroup = "transport-drones",
    order = "e-a-c",
    stack_size = 10,
    place_result = "buffer-depot"
  },
  {
    type = "recipe",
    name = "buffer-depot",
    localised_name = { "buffer-depot" },
    icon = buffer_depot.icon,
    icon_size = buffer_depot.icon_size,
    --category = "transport",
    enabled = false,
    ingredients =
    {
      { type = "item",name = "iron-plate",     amount = 50 },
      { type = "item",name = "iron-gear-wheel",amount = 10 },
      { type = "item",name = "iron-stick",     amount = 20 },
    },
    energy_required = 5,
    results = {
      { type = "item", name = "buffer-depot", amount = 1 }
    }
  }
}

data:extend { buffer_depot }
data:extend(buffer_depot_items)

local reader = util.copy(data.raw["constant-combinator"]["constant-combinator"])
reader.name = "road-network-reader"
reader.localised_name = "Road network reader"
reader.item_slot_count = 1
reader.sprites = require(util.path("data/entities/transport_depot_circuits/road-network-reader-sprite"))
reader.icon = util.path("data/entities/transport_depot_circuits/road-network-reader-icon.png")
reader.icon_mipmaps = 0
reader.icon_size = 72
reader.minable.result = "road-network-reader"
reader.radius_visualisation_specification =
{
  sprite = caution_sprite,
  distance = 0.5,
  offset = { 0, 1 }
}

local reader_item =
{
  type = "item",
  name = "road-network-reader",
  icon = reader.icon,
  icon_size = reader.icon_size,
  stack_size = 20,
  subgroup = "transport-drones",
  order = "z-a",
  place_result = "road-network-reader"
}

local reader_recipe =
{
  type = "recipe",
  name = "road-network-reader",
  localised_name = { "road-network-reader" },
  icon = reader.icon,
  icon_size = reader.icon_size,
  enabled = false,
  ingredients =
  {
    {type = "item",name =  "copper-cable",   amount=    5 },
    { type = "item",name = "electronic-circuit", amount =10 },
  },
  energy_required = 5,
  results = {
    { type = "item", name = "road-network-reader", amount = 1 }
  }
}

data:extend
{
  reader,
  reader_item,
  reader_recipe
}
