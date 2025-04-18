--local reader = util.copy(data.raw.pump.pump)
--reader.name = "transport-depot-reader"

local writer_sprite = util.copy(data.raw["constant-combinator"]["constant-combinator"])

local writer = util.copy(data.raw.pump.pump)
writer.name = "transport-depot-writer"
writer.localised_name = "Transport depot writer"
writer.energy_source =
{
  type = "void",
  energy_usage = "0w"
}

writer.glass_pictures = nil
writer.animations = require(util.path("data/entities/transport_depot_circuits/depot-writer-sprite"))
writer.icon = util.path("data/entities/transport_depot_circuits/depot-writer-icon.png")
writer.icon_mipmaps = 0
writer.icon_size = 72
writer.fluid_animations = nil
writer.pumping_speed = 0
writer.load_connector_animations = nil
writer.unload_connetor_animations = nil
writer.fluid_wagon_connector_frame_count = 0
writer.collision_box = {{-0.4, -0.4},{0.4, 0.4}}
writer.selection_box = {{-0.5, -0.5}, {0.5, 0.5}}
writer.minable.result = "transport-depot-writer"
writer.next_upgrade = nil
writer.circuit_connector_sprites =
{
  data.raw.lamp["small-lamp"].circuit_connector_sprites,
  data.raw.lamp["small-lamp"].circuit_connector_sprites,
  data.raw.lamp["small-lamp"].circuit_connector_sprites,
  data.raw.lamp["small-lamp"].circuit_connector_sprites
}
writer.circuit_wire_connection_points = writer_sprite.circuit_wire_connection_points
writer.fluid_box =
{
  volume = 50,
  pipe_connections =
  {
    {
      direction = defines.direction.south,
      position = {0, 0},
      flow_direction = "output"
    }
  }
}

-- regex to replace CRLF with LF
-- ^\r

local writer_item =
{
  type = "item",
  name = "transport-depot-writer",
  icon = writer.icon,
  icon_size = writer.icon_size,
  stack_size = 20,
  subgroup = "transport-drones",
  order = "z-b",
  place_result = "transport-depot-writer"
}


local writer_recipe =
{
  type = "recipe",
  name = "transport-depot-writer",
  localised_name = {"transport-depot-writer"},
  icon = writer.icon,
  icon_size = writer.icon_size,
  enabled = false,
  ingredients =
  {
    {type = "item",name = "copper-cable", amount = 5},
    {type = "item",name = "electronic-circuit", amount  = 10},
  },
  energy_required = 5,
  results = {
    {type="item",name="transport-depot-writer",amount=1}
  }
}

data:extend
{
  writer,
  writer_item,
  writer_recipe
}

local reader = util.copy(data.raw["constant-combinator"]["constant-combinator"])
reader.name = "transport-depot-reader"
reader.localised_name = "Transport depot reader"
reader.item_slot_count = 2
reader.sprites = require(util.path("data/entities/transport_depot_circuits/depot-reader-sprite"))
reader.icon = util.path("data/entities/transport_depot_circuits/depot-reader-icon.png")
reader.icon_mipmaps = 0
reader.icon_size = 72
reader.minable.result = "transport-depot-reader"
reader.radius_visualisation_specification =
{
  offset = {0, 1},
  distance = 0.5,
  sprite =
  {
    filename = "__core__/graphics/arrows/gui-arrow-circle.png",
    height = 50,
    width = 50
  }
}

local reader_item =
{
  type = "item",
  name = "transport-depot-reader",
  icon = reader.icon,
  icon_size = reader.icon_size,
  stack_size = 20,
  subgroup = "transport-drones",
  order = "z-c",
  place_result = "transport-depot-reader"
}

local reader_recipe =
{
  type = "recipe",
  name = "transport-depot-reader",
  localised_name = {"transport-depot-reader"},
  icon = reader.icon,
  icon_size = reader.icon_size,
  enabled = false,
  ingredients =
  {
    {type = "item",name = "copper-cable", amount = 5},
    {type = "item",name = "electronic-circuit", amount = 10},
  },
  energy_required = 5,
  results = {
    {type="item",name="transport-depot-reader",amount=1}
  }
}

data:extend
{
  reader,
  reader_item,
  reader_recipe
}