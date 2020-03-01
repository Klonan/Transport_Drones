local machine = util.copy(data.raw["assembling-machine"]["assembling-machine-3"])
local name = names.mining_depot
machine.name = name
machine.localised_name = {name}
local scale = 2
util.recursive_hack_make_hr(machine)
util.recursive_hack_scale(machine, scale)
machine.collision_box = {{-1.25, -2.5},{1.25, 2.25}}
machine.selection_box = {{-1.5, -2.5},{1.5, 2.5}}
machine.crafting_categories = {name}
machine.crafting_speed = (1)
machine.ingredient_count = nil
machine.collision_mask = {"item-layer", "object-layer", "water-tile", "player-layer", "resource-layer"}
machine.allowed_effects = {"consumption", "speed", "pollution"}
machine.module_specification =nil
machine.minable = {result = name, mining_time = 1}
machine.flags = {"placeable-neutral", "player-creation"}
machine.next_upgrade = nil
machine.fluid_boxes =
{
  {
    production_type = "input",
    pipe_picture = assembler2pipepictures(),
    base_area = 10,
    base_level = -1,
    pipe_connections = {{ type="input-output", position = {0, 3} }},
    pipe_covers = pipecoverspictures(),
  },
  off_when_no_fluid_recipe = false
}
machine.scale_entity_info_icon = true
machine.energy_usage = "1W"
machine.gui_title_key = "mining-depot-choose-resource"
machine.energy_source =
{
  type = "void",
  usage_priority = "secondary-input",
  emissions_per_second_per_watt = 0.1
}
machine.icon = util.path("data/entities/mining_depot/depot-icon.png")
machine.icon_size = 216
machine.radius_visualisation_specification =
{
  sprite =
  {
    filename = "__base__/graphics/entity/electric-mining-drill/electric-mining-drill-radius-visualization.png",
    width = 10,
    height = 10
  },
  distance = 40.5,
  offset = {0, -43}
}

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

machine.animation =
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

local item =
{
  type = "item",
  name = name,
  icon = machine.icon,
  icon_size = machine.icon_size,
  flags = {},
  subgroup = "extraction-machine",
  order = "za"..name,
  place_result = name,
  stack_size = 5
}

local category = {
  type = "recipe-category",
  name = name
}

local recipe =
{
  type = "recipe",
  name = name,
  localised_name = {name},
  enabled = true,
  ingredients =
  {
    {"iron-plate", 50},
    {"iron-gear-wheel", 10},
    {"iron-stick", 20},
  },
  energy_required = 5,
  result = name
}

local caution_sprite =
{
  type = "sprite",
  name = "caution-sprite",
  filename = util.path("data/entities/mining_depot/depot-caution.png"),
  width = 101,
  height = 72,
  frame_count = 1,
  scale = 0.5,
  shift = shift,
  direction_count =1,
  draw_as_shadow = false,
  flags = {"terrain"}
}

local caution_corpse =
{
  type = "corpse",
  name = "caution-corpse",
  flags = {"placeable-off-grid"},
  animation = caution_sprite,
  remove_on_entity_placement = false,
  remove_on_tile_placement = false
}

data:extend
{
  machine,
  item,
  category,
  recipe,
  caution_sprite,
  caution_corpse
}

--error(count)